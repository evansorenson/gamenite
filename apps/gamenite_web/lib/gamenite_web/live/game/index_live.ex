defmodule GameniteWeb.Game.IndexLive do
  use GameniteWeb, :live_view

  alias Surface.Components.Form
  alias Surface.Components.Form.{Field, Label, SearchInput, Submit}

  alias GamenitePersistance.Gaming
  alias GameniteWeb.GameConfig
  alias Rooms

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
    with {:ok, room_slug} <- Rooms.start_room(),
         :ok <- Rooms.set_game(room_slug, game_title) do
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

  def render(assigns) do
    ~F"""
    <h1 class="text-7xl py-4 font-bold text-black">Games</h1>

    <Form for={:hi} class="search-form focus-within:border-blurple" change="search">
      <Field name="query" field="query">
        <SearchInput opts={autofocus: "autofocus", phx_debounnce: 100, placeholder: "Search for games"} />
      </Field>
    </Form>

    <div class="space-y-8">
      {#for game <- @games}
        <div class="container-left bg-white rounded-xl overflow-hidden shadow-lg">
        <h2 class="text-4xl font-bold text-black px-4 pt-4">{ game.title }</h2>
        <p class="text-black font-light px-8 py-2">{ game.description }</p>
        <button class="bg-blurple border-none text-white rounded hover:bg-indigo-400 py-2 px-4 float-right mb-4 mr-4" phx-click="host_game" phx-value-game_title={ game.title  }>Host Game</button>
      </div>
    {/for}
    </div>
    """
  end
end
