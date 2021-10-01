defmodule GameniteWeb.GameLive do
  use GameniteWeb, :live_component

  alias Phoenix.Socket.Broadcast
  alias GamenitePersistance.Accounts
  alias Gamenite.Games.{Charades, CharadesGame, CharadesPlayer}
  alias Gamenite.TeamGame
  alias Gamenite.SaladBowlAPI

  def update(%{slug: slug, game_id: game_id, connected_users: connected_users } = _assigns, socket) do
    IO.puts "hi"
    game_info = GamenitePersistance.Gaming.get_game!(game_id)
    Phoenix.PubSub.subscribe(GamenitePersistance.PubSub, "game:" <> slug)

    game_changeset = CharadesGame.new_salad_bowl(%{})

    {:ok,
    socket
    |> assign(game_info: game_info)
    |> assign(game_changeset: game_changeset)
    |> assign(slug: slug)
    |> assign(connected_users: connected_users)
    |> assign(game: nil)
    }
  end
  def update(%{ game: game } = _assigns, socket) do
    {:ok,
    socket
    |> assign(game: game)
    }
  end
  def update(%{ connected_users: connected_users } = _assigns, socket) do
    {:ok,
    socket
    |> assign(connected_users: connected_users)
    }
  end

  @impl true
  def handle_event("start_game", _payload, socket) do
    teams = socket.assigns.connected_users
    |> users_to_players
    |> Enum.map(fn player -> CharadesPlayer.new(%{player: player }) end)
    |> TeamGame.Team.split_teams(2)

    case teams do
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
      teams ->
        {:ok, game} = teams
        |> TeamGame.new()
        |> CharadesGame.finalize_changeset_and_create(socket.assigns.game_changeset)
        |> SaladBowlAPI.start_game(socket.assigns.slug)
        broadcast_game_update(socket.assigns.slug, game)
        {:noreply, assign(socket, :game, game)}
    end
  end

  defp users_to_players(connected_users) do
    connected_users
    |> Map.to_list()
    |> Enum.map(fn {_k, %{user_id: user_id} = _roommate} -> Accounts.get_user_by(%{id: user_id}) end)
    |> TeamGame.Player.new_players_from_users()
  end

  defp start_or_get_game_process(game_info, slug) do
    case Gamenite.start_game(game_info.title, slug) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      _ -> :error
    end
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
  def handle_event("validate", %{"charades_options" => params}, socket) do
    game_changeset =
      %CharadesGame{}
      |> CharadesGame.salad_bowl_changeset(params)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, game_changeset: game_changeset)}
  end

end
