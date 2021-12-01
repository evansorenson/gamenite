defmodule GameniteWeb.Components.OptionsTable do
  use Surface.LiveComponent
  require Logger

  alias Surface.Components.Dynamic
  alias GameniteWeb.ParseHelpers
  alias Gamenite.TeamGame
  alias Gamenite.Game

  prop(slug, :string, required: true)
  prop(game_config, :map, required: true)
  prop(roommates, :map, required: true)
  prop user_id, :any, required: true

  data(game_changeset, :map)
  data flash, :any

  def update(
        %{slug: slug, game_config: game_config, roommates: roommates, user_id: user_id} =
          _assigns,
        socket
      ) do
    {:ok,
     socket
     |> assign(game_config: game_config)
     |> assign(slug: slug)
     |> assign(roommates: roommates)
     |> assign(user_id: user_id)
     |> assign_game_changeset(%{})}
  end

  def update(%{roommates: roommates} = _assigns, socket) do
    {:ok,
     socket
     |> assign(roommates: roommates)}
  end

  defp new_game(game_config) do
    apply(game_config.impl, :new, [])
  end

  defp convert_changeset_params(params, socket) when socket.assigns.game_config.team_game? do
    params
    |> ParseHelpers.key_to_atom()
    |> add_teams(socket)
    |> maybe_add_deck(socket)
    |> add_room_slug(socket)
  end

  defp convert_changeset_params(params, socket) do
    params
    |> ParseHelpers.key_to_atom()
    |> add_players(socket)
    |> maybe_add_deck(socket)
    |> add_room_slug(socket)
  end

  defp add_teams(params, socket) do
    teams =
      socket.assigns.roommates
      |> roommates_to_players(socket.assigns.game_config.impl)
      |> TeamGame.split_teams(2)

    params
    |> Map.put(:teams, teams)
  end

  defp add_players(params, socket) do
    players =
      socket.assigns.roommates
      |> roommates_to_players(socket.assigns.game_config.impl)

    params
    |> Map.put(:players, players)
  end

  defp maybe_add_deck(params, socket) when is_map_key(socket.assigns.game_config, :deck) do
    params
    |> Map.put(:deck, socket.assigns.game_config.deck.cards)
  end

  defp maybe_add_deck(params, _socket), do: params

  defp add_room_slug(params, socket) do
    params
    |> Map.put(:room_slug, socket.assigns.slug)
  end

  defp assign_game_changeset(socket, params) do
    socket
    |> assign(game_changeset: create_game_changeset(socket, params))
  end

  defp create_game_changeset(socket, params) do
    converted_params =
      params
      |> convert_changeset_params(socket)

    game = new_game(socket.assigns.game_config)

    changeset =
      apply(socket.assigns.game_config.impl, :change, [game, converted_params])
      |> Map.put(:action, :validate)

    IO.inspect(changeset)
    changeset
  end

  defp roommates_to_players(roommates, impl_module) do
    roommates
    |> Map.values()
    |> TeamGame.Player.new_players_from_roommates()
    |> Enum.map(fn player -> create_game_player(impl_module, player) end)
  end

  defp create_game_player(impl_module, player) do
    apply(impl_module, :create_player, [player])
  end

  @impl true
  def handle_event("start", %{"game" => params}, socket) do
    game_config = socket.assigns.game_config

    if Game.API.game_exists?(socket.assigns.slug) do
      {:noreply, put_flash(socket, :error, "Game already started.")}
    else
      with conv_params <- convert_changeset_params(params, socket),
           {:ok, game} <- apply(game_config.impl, :create, [conv_params]),
           :ok <- Game.API.start_game(game_config.server, game, socket.assigns.slug),
           :ok <- Rooms.set_game_in_progress(socket.assigns.slug, true) do
        {:noreply, socket}
      else
        {:error, reason} ->
          Logger.log(:error, title: "Error creating game.", error: reason)
          {:noreply, put_flash(socket, :error, "Error creating game.")}
      end
    end
  end

  @impl true
  def handle_event("validate", %{"game" => params}, socket) do
    {:noreply,
     assign(socket,
       game_changeset: create_game_changeset(socket, params)
     )}
  end

  @impl true
  def render(assigns) do
    #   <div>
    #   <Dynamic.Component module={@game_config.components.options} game_changeset={@game_changeset} submit={"start", target: @myself} change={"validate", target: @myself}/>
    # </div>
    ~F"""
    <div>
    <p class="alert alert-info" role="alert">{live_flash(@flash, :info)}</p>
    <p class="alert alert-danger" role="alert">{live_flash(@flash, :error)}</p>
    {#case @game_config.title}
    {#match "Witbash"}
      <GameniteWeb.Components.Witbash.Options submit={"start", target: @myself} change={"validate", target: @myself} game_changeset={@game_changeset} />
    {#match "Salad Bowl"}
      <GameniteWeb.Components.SaladBowl.Options submit={"start", target: @myself} change={"validate", target: @myself} game_changeset={@game_changeset} />
    {#match "Kodenames"}
      <GameniteWeb.Components.Kodenames.Options submit={"start", target: @myself} change={"validate", target: @myself} game_changeset={@game_changeset} />
    {/case}
    </div>
    """
  end
end
