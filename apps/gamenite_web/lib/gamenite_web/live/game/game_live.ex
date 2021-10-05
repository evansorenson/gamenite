defmodule GameniteWeb.GameLive do
  use GameniteWeb, :live_component

  alias Phoenix.Socket.Broadcast
  alias GamenitePersistance.Accounts
  alias Gamenite.Games.{Charades, CharadesGame, CharadesPlayer}
  alias Gamenite.TeamGame
  alias Gamenite.SaladBowlAPI

  def update(%{slug: slug, game_id: game_id, connected_users: connected_users, user: user } = _assigns, socket) do
    game_info = GamenitePersistance.Gaming.get_game!(game_id)

    game_changeset = game_changeset(connected_users, %{})

    {:ok,
    socket
    |> initialize_game(slug)
    |> assign(game_changeset: game_changeset)
    |> assign(user: user)
    |> assign(game_info: game_info)
    |> assign(slug: slug)
    |> assign(connected_users: connected_users)
    }
  end

  defp initialize_game(socket, slug) do
    cond do
      SaladBowlAPI.exists?(slug) ->
        {:ok, game } = SaladBowlAPI.state(slug)
        assign(socket, game: game)
      true ->
        IO.puts "nooooo king"
        assign(socket, game: nil)
    end
  end

  def update(%{ game: game } = _assigns, socket) do
    {:ok,
    socket
    |> assign(game: game)
    }
  end

  @impl true
  def handle_event("start_game", _payload, socket) do
    if SaladBowlAPI.exists?(socket.assigns.slug) do
      {:noreply, put_flash(socket, :error, "Game already started.")}
    else
      case CharadesGame.create(socket.assigns.game_changeset) do
        {:ok, game} ->
          SaladBowlAPI.start_game(game, socket.assigns.slug)
          broadcast_game_update(socket.assigns.slug, game)
          {:noreply,
          socket
          |> assign(:game, game)
          |> put_flash(:info, "Game created successfully.")}
        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Error creating game.")}
      end
    end
  end

  defp game_changeset(connected_users, params) do
    teams = connected_users
    |> users_to_players
    |> Enum.map(fn player -> CharadesPlayer.new(player) end)
    |> TeamGame.Team.split_teams(2)

    params
    |> Map.put(:teams, teams)
    |> CharadesGame.new_salad_bowl()
    |> Map.put(:action, :update)
  end

  defp users_to_players(connected_users) do
    connected_users
    |> Map.to_list()
    |> Enum.map(fn {_k, %{user_id: user_id} = _roommate} -> Accounts.get_user_by(%{id: user_id}) end)
    |> TeamGame.Player.new_players_from_users()
  end

  defp broadcast_game_update(room_id, game) do
    GameniteWeb.Endpoint.broadcast_from(
      self(),
      "game:" <> room_id,
      "game_state_update",
      game
    )
  end


  @impl true
  def handle_event("validate", %{"game_changeset" => params}, socket) do
    game_changeset =
      %CharadesGame{}
      |> CharadesGame.salad_bowl_changeset(params)

    {:noreply, assign(socket, game_changeset: game_changeset)}
  end

  @impl true
  def handle_event("correct", _params, socket) do
    {:ok, game} = SaladBowlAPI.correct_card(socket.assigns.slug)
    broadcast_game_update(socket.assigns.slug, game)
    {:noreply, assign(socket, game: game)}
  end

  @impl true
  def handle_event("start_turn", _params, socket) do
    {:ok, game} = SaladBowlAPI.start_turn(socket.assigns.slug)
    broadcast_game_update(socket.assigns.slug, game)


    :timer.apply_interval(1000, __MODULE__, &read_timer/1, [socket.assigns.slug] )
    {:noreply, assign(socket, game: game)}
  end

  defp read_timer(slug) do

  end


  @impl true
  def handle_event("skip", _params, socket) do
    case SaladBowlAPI.skip_card(socket.assigns.slug) do
      {:ok, game} ->
        broadcast_game_update(socket.assigns.slug, game)
        {:noreply, assign(socket, game: game)}
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

end
