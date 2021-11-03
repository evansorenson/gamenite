defmodule GameniteWeb.GameLive do
  use Surface.LiveComponent

  alias GameniteWeb.Components.{TeamsScoreboard}
  alias GameniteWeb.Components.Charades.{Card, ChangesetTable}

  alias Gamenite.SaladBowl.API

  data(game, :map, default: nil)
  data(game_info, :map, default: nil)
  data(user, :map)
  data(slug, :string)
  data(roommates, :map)
  data(roommate, :map)
  data(flash, :map)

  def update(
        %{slug: slug, game_id: game_id, roommates: roommates, user: user} = _assigns,
        socket
      ) do
    game_info = GamenitePersistance.Gaming.get_game(game_id)
    roommate = Map.get(roommates, user.id)

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

  def render(assigns) do
    ~F"""
    <div>
    <p class="alert alert-info" role="alert">{live_flash(@flash, :info)}</p>
    <p class="alert alert-danger" role="alert">{live_flash(@flash, :error)}</p>
    {#if is_nil(@game)}
      <{@changeset_comp} id={@game_info.id} slug={@slug} roommates={@roommates} />
    {#elseif @game.finished?}
      <{@finished_comp} id={@game_info.id} />
    {#else}
      <{@game_comp} id={@game_info.id} game={@game} roommates={@roommates} xc/>
    {/if}
    </div>
    """
  end
end
