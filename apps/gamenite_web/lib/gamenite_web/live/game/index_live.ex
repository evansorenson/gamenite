defmodule GameniteWeb.Game.IndexLive do
  use GameniteWeb, :live_view

  alias Surface.Components.Form
  alias Surface.Components.Form.{Field, Label, SearchInput, Submit}

  alias GamenitePersistance.Gaming
  alias GameniteWeb.GameConfig
  alias Gamenite.Room

  def mount(_params, _session, socket) do
    games = GameConfig.list_configs()
    sorted_games = Enum.sort(games, &(Map.get(&1, :play_count) <= Map.get(&2, :play_count)))

    {:ok,
     socket
     |> assign(:games, sorted_games)}
  end

  def handle_event("search", %{"query" => nil}, socket) do
    {:noreply, assign(socket, :games, GameConfig.list_configs())}
  end

  def handle_event("search", %{"query" => query}, socket) do
    games_search = GameConfig.search_games(query)
    {:noreply, assign(socket, :games, games_search)}
  end

  def handle_event("host_game", %{"game_title" => game_title}, socket) do
    with {:ok, room_slug} <- Room.API.start_room(),
         :ok <- Room.API.set_game(room_slug, game_title) do
      {:noreply,
       socket
       |> push_redirect(to: Routes.room_path(socket, :new, room_slug, %{slug: room_slug}))}
    else
      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not start the room.")}
    end
  end
end
