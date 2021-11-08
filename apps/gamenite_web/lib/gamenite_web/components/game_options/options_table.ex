defmodule GameniteWeb.Components.OptionsTable do
  use Surface.LiveComponent

  alias Surface.Components.Dynamic

  alias GameniteWeb.ParseHelpers
  alias Gamenite.TeamGame
  alias Gamenite.GameServer
  alias Gamenite.Room

  prop(slug, :string, required: true)
  prop(game_config, :map, required: true)
  prop(roommates, :map, required: true)

  data(game_changeset, :map)

  def update(
        %{slug: slug, game_config: game_config, roommates: roommates} = _assigns,
        socket
      ) do
    {:ok,
     socket
     |> assign(game_config: game_config)
     |> assign(slug: slug)
     |> assign(roommates: roommates)
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
    teams =
      socket.assigns.roommates
      |> roommates_to_players(socket.assigns.game_config.player)
      |> TeamGame.split_teams(2)

    IO.inspect(params)

    ParseHelpers.key_to_atom(params)
    |> Map.put(:teams, teams)
    |> Map.put(:room_slug, socket.assigns.slug)
  end

  defp convert_changeset_params(params, socket) do
    players =
      socket.assigns.roommates
      |> roommates_to_players(socket.assigns.game_config.player)

    ParseHelpers.key_to_atom(params)
    |> Map.put(:players, players)
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

    apply(socket.assigns.game_config.impl, :change, [game, converted_params])
    |> Map.put(:action, :validate)
  end

  defp roommates_to_players(roommates, player_module) do
    roommates
    |> Map.values()
    |> TeamGame.Player.new_players_from_roommates()
    |> Enum.map(fn player -> create_game_player(player_module, player) end)
  end

  defp create_game_player(player_module, player) do
    apply(player_module, :create, [player])
  end

  @impl true
  def handle_event("start", %{"game" => params}, socket) do
    game_config = socket.assigns.game_config

    if GameServer.game_exists?(socket.assigns.slug) do
      {:noreply, put_flash(socket, :error, "Game already started.")}
    else
      with conv_params <- convert_changeset_params(params, socket),
           {:ok, game} <- apply(game_config.impl, :create, [conv_params]),
           :ok <-
             GameServer.start_game(game_config.server, game, socket.assigns.slug),
           :ok <- Room.API.set_game_in_progress(socket.assigns.slug, true) do
        {:noreply, push_redirect(socket, game_config.components.game)}
      else
        {:error, reason} ->
          IO.inspect(reason)

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
    <GameniteWeb.Components.Horsepaste.Options submit={"start", target: @myself} change={"validate", target: @myself} game_changeset={@game_changeset} />
    """
  end
end
