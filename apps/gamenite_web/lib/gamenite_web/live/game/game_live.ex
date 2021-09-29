defmodule GameniteWeb.GameLive do
  use GameniteWeb, :live_view

  alias Gamenite.Games.CharadesOptions

  alias Gamenite.TeamGame
  alias Phoenix.Socket.Broadcast
  alias GamenitePersistance.Accounts


  def mount(_params, %{"slug" => slug, "game_id" => game_id } = _session, socket) do
    game = GamenitePersistance.Gaming.get_game!(game_id)
    IO.puts "game mount"

    Phoenix.PubSub.subscribe(GamenitePersistance.PubSub, "game:" <> slug)

    with :ok <- start_or_get_game_process(game, slug) do
      game_options_changeset = CharadesOptions.new_salad_bowl(%{})
      team_game_changeset = TeamGame.teams_changeset(%TeamGame{}, %{teams: [%{}, %{}]})

      {:ok,
      socket
      |> assign(game: game)
      |> assign(game_options_changeset: game_options_changeset)
      |> assign(team_game_changeset: team_game_changeset)
      }
    else
      {:error, reason} ->
        socket
        |> put_flash(:error, reason)
        |> push_redirect(to: Routes.game_path(socket, :index))
    end
  end

  @impl true
  def handle_event("start_game", _payload, socket) do
    players = socket.assigns.room.connected_users |> Map.to_list()
    |> Enum.map(fn {_k, %{user_id: user_id} = _roommate} -> Accounts.get_user_by(%{id: user_id}) end)
    |> TeamGame.Player.new_players_from_users()

    teams = players
    |> TeamGame.Team.split_teams(2)

    # game_changeset = TeamGame.finalize_game_changeset(socket.assigns.game, %{teams: teams})

    {:noreply, socket}
  end

  defp start_or_get_game_process(game, slug) do
    case Gamenite.start_game(game.title, slug) do
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

  def handle_info(%Broadcast{event: "game_state_update", payload: game}, socket) do

    {:noreply,
      socket
      |> assign(:game, game)}
  end

  def handle_info(%Broadcast{event: "connected_uers_update", payload: game}, socket) do

    {:noreply,
      socket
      |> assign(:connected_users, game)}
  end

  @impl true
  def handle_event("validate", %{"charades_options" => params}, socket) do
    game_options_changeset =
      %CharadesOptions{}
      |> CharadesOptions.salad_bowl_changeset(params)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, game_options_changeset: game_options_changeset)}
  end
end
