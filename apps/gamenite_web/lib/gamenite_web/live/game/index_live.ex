defmodule GameniteWeb.Game.IndexLive do
  use GameniteWeb, :live_view

  alias GamenitePersistance.Gaming
  alias Gamenite.GameConfigs
  alias Gamenite.Room

  def mount(_params, _session, socket) do
    games = GameConfigs.list_configs()
    sorted_games = Enum.sort(games, &(Map.get(&1, :play_count) <= Map.get(&2, :play_count)))

    {:ok,
     socket
     |> assign(:games, sorted_games)}
  end

  def handle_event("search", %{"search_field" => %{"query" => nil}}, socket) do
    {:noreply, assign(socket, :games, GameConfigs.list_configs())}
  end

  def handle_event("search", %{"search_field" => %{"query" => query}}, socket) do
    games_search = Gaming.search_games(query)
    {:noreply, assign(socket, :games, games_search)}
  end

  def handle_event("host_game", %{"game_title" => game_title}, socket) do
    with {:ok, room_slug} <- Room.API.start_room(),
         :ok <- Room.API.set_game(room_slug, game_title) do
      {:noreply,
       socket
       |> push_redirect(to: Routes.room_path(socket, :new, room_slug))}
    else
      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not start the room.")}
    end
  end
end
