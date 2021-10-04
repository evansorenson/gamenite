defmodule GameniteWeb.GameLive do
  use GameniteWeb, :live_component

  alias Phoenix.Socket.Broadcast
  alias GamenitePersistance.Accounts
  alias Gamenite.Games.{Charades, CharadesGame, CharadesPlayer}
  alias Gamenite.TeamGame
  alias Gamenite.SaladBowlAPI

  def update(%{slug: slug, game_id: game_id, connected_users: connected_users, user: user } = _assigns, socket) do
    game_info = GamenitePersistance.Gaming.get_game!(game_id)
    Phoenix.PubSub.subscribe(GamenitePersistance.PubSub, "game:" <> slug)

    game_changeset = game_changeset(connected_users, %{})

    {:ok,
    socket
    |> initialize_game_as_nil
    |> assign(game_changeset: game_changeset)
    |> assign(user: user)
    |> assign(game_info: game_info)
    |> assign(slug: slug)
    |> assign(connected_users: connected_users)
    }
  end

  defp initialize_game_as_nil(socket) do
    if not Map.has_key?(socket.assigns, :game) do
      assign(socket, game: nil)
    else
      socket
    end
  end

  # def update(%{ game: game } = _assigns, socket) do
  #   {:ok,
  #   socket
  #   |> assign(game: game)
  #   }
  # end

  @impl true
  def handle_event("start_game", _payload, socket) do
    IO.puts "what"

    with {:ok, game} <- CharadesGame.create(socket.assigns.game_changeset)
     do
      IO.inspect SaladBowlAPI.start_game(game, socket.assigns.slug)
      broadcast_game_update(socket.assigns.slug, game)
      IO.puts "what is going on here!"
      {:noreply, assign(socket, :game, game)}
    else
      {:error, _changeset} ->
        IO.inspect "hello"
        {:noreply, socket}
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
    {:noreply, assign(socket, game: game)}
  end

  @impl true
  def handle_event("skip", _params, socket) do
    case SaladBowlAPI.skip_card(socket.assigns.slug) do
      {:ok, game} ->
        {:noreply, assign(socket, game: game)}
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

end
