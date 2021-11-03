defmodule GameniteWeb.GameLive do
  use Surface.LiveComponent

  alias Surface.Components.Dynamic.Component
  alias GameniteWeb.Components.{TeamsScoreboard}
  alias GameniteWeb.Components.Charades.{Card, ChangesetTable}

  alias Gamenite.SaladBowl.API
  alias Gamenite.GameConfigs

  data(game, :map, default: nil)
  data(game_info, :map, default: nil)
  data(user, :map)
  data(slug, :string)
  data(roommates, :map)
  data(roommate, :map)
  data(flash, :map)

  def update(
        %{slug: slug, game_title: game_title, roommates: roommates, user: user} = _assigns,
        socket
      ) do
    game_info = GameConfigs.get_config(game_title)
    roommate = Map.get(roommates, user.id)

    IO.inspect(game_info.components)

    {:ok,
     socket
     |> initialize_game(slug)
     |> assign(user: user)
     |> assign(game_info: game_info)
     |> assign(slug: slug)
     |> assign(roommates: roommates)
     |> assign(roommate: roommate)}
  end

  @impl true
  def update(%{game: game} = _assigns, socket) do
    {:ok,
     socket
     |> assign(game: game)}
  end

  @impl true
  def update(%{game_changeset: game_changeset} = _assigns, socket) do
    {:ok,
     socket
     |> assign(game_changeset: game_changeset)}
  end

  defp initialize_game(socket, slug) do
    cond do
      API.exists?(slug) ->
        {:ok, game} = API.state(slug)
        assign(socket, game: game)

      true ->
        assign(socket, game: nil)
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
    <p class="alert alert-info" role="alert">{live_flash(@flash, :info)}</p>
    <p class="alert alert-danger" role="alert">{live_flash(@flash, :error)}</p>
    {#if is_nil(@game)}
      <Component module={@game_info.components.changeset} id={@game_info.title} slug={@slug} roommates={@roommates} />
    {#elseif @game.finished?}
      <Component module={@game_info.components.finished} id={@game_info.title} />
    {#else}
      <Component module={@game_info.components.game} id={@game_info.title} game={@game} roommates={@roommates} />
    {/if}
    </div>
    """
  end
end
