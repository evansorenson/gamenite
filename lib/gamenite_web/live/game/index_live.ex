defmodule GameniteWeb.Game.IndexLive do
  use GameniteWeb, :live_view

  alias Gamenite.Gaming
  alias Gamenite.Organizer

  def mount(_params, _session, socket) do
    games = Gaming.list_games()
    IO.inspect games
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
    IO.puts query
    games_search = Gaming.search_games(query)
    {:noreply, assign(socket, :games, games_search)}
  end

  def handle_event("host_game", %{"game" => game}, socket) do
    case Organizer.create_room_with_random_slug(game) do
      {:ok, room} ->
        {:noreply,
          socket
          |> push_redirect(to: Routes.room_show_path(socket, :show, room.slug))
        }
      {:error, changeset} ->
        {:noreply,
          socket
          |> assign(:changeset, changeset)
          |> put_flash(:error, "Could not save the room.")
        }
    end
  end
end
