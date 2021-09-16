defmodule GameniteWeb.Game.IndexLive do
  use GameniteWeb, :live_view

  alias GamenitePersistance.Gaming
  alias GamenitePersistance.Organizer
  alias Gamenite

  def mount(_params, _session, socket) do
    games = Gaming.list_games()
    sorted_games = Enum.sort(games, &(Map.get(&1, :play_count) <= Map.get(&2, :play_count)))

    {:ok,
    socket
    |> assign(:games, sorted_games)
    }
  end

  def handle_event("search", %{"search_field" => %{"query" => nil}}, socket) do
    {:noreply, assign(socket, :games, Gaming.list_games())}
  end
  def handle_event("search", %{"search_field" => %{"query" => query}}, socket) do
    games_search = Gaming.search_games(query)
    {:noreply, assign(socket, :games, games_search)}
  end

  def handle_event("host_game", %{"game_id" => game_id}, socket) do
    case Organizer.create_room_with_random_slug() do
      {:ok, room} ->
        {:noreply,
          socket
          |> push_redirect(to: Routes.room_path(socket, :new, room.slug, %{ game_id: game_id }))
        }
      {:error, changeset} ->
        {:noreply,
          socket
          |> assign(:changeset, changeset)
          |> put_flash(:error, "Could not start the room.")
        }
    end
  end
end
