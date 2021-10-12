defmodule GameniteWeb.GameLive do
  use GameniteWeb, :live_component

  alias GamenitePersistance.Accounts
  alias Gamenite.Games.Charades
  alias Gamenite.Games.Charades.{Game, Player}
  alias Gamenite.TeamGame
  alias Gamenite.SaladBowlAPI

  def update(%{slug: slug, game_id: game_id, connected_users: connected_users, user: user } = _assigns, socket) do
    game_info = GamenitePersistance.Gaming.get_game!(game_id)

    game_changeset = create_game_changeset(%{}, connected_users)

    {:ok,
    socket
    |> initialize_game(slug)
    |> assign(game_changeset: game_changeset)
    |> assign(user: user)
    |> assign(game_info: game_info)
    |> assign(slug: slug)
    |> assign(connected_users: connected_users)
    }
  end

  @impl true
  def update(%{ game: game } = _assigns, socket) do
    {:ok,
    socket
    |> assign(game: game)
    }
  end

  defp initialize_game(socket, slug) do
    cond do
      SaladBowlAPI.exists?(slug) ->
        {:ok, game } = SaladBowlAPI.state(slug)
        assign(socket, game: game)
      true ->
        assign(socket, game: nil)
    end
  end

  defp users_to_players(connected_users) do
    connected_users
    |> Map.to_list()
    |> Enum.map(fn {_k, %{user_id: user_id} = _roommate} -> Accounts.get_user_by(%{id: user_id}) end)
    |> TeamGame.Player.new_players_from_users()
  end

  defp broadcast_game_update(room_id, game) do
    GameniteWeb.Endpoint.broadcast_from(
      self(),
      "game:" <> room_id,
      "game_state_update",
      game
    )
  end

  defp convert_changeset_params(params, connected_users) do
    teams = connected_users
    |> users_to_players
    |> Enum.map(fn player -> Player.new(player) end)
    |> TeamGame.Team.split_teams(2)

    key_to_atom(params)
    |> Map.put(:teams, teams)
  end

  defp create_game_changeset(params, connected_users) do
    _game_changeset = %Game{}
    |> Game.salad_bowl_changeset(convert_changeset_params(params, connected_users))
  end

  defp key_to_atom(map) do
    Enum.reduce(map, %{}, fn
      # String.to_existing_atom saves us from overloading the VM by
      # creating too many atoms. It'll always succeed because all the fields
      # in the database already exist as atoms at runtime.
      {key, value}, acc when is_atom(key) -> Map.put(acc, key, value)
      {key, value}, acc when is_binary(key) -> Map.put(acc, String.to_existing_atom(key), value)
    end)
  end


  defp card_completed(socket, outcome) do
    case SaladBowlAPI.card_completed(socket.assigns.slug, outcome) do
      {:ok, game} ->
        broadcast_game_update(socket.assigns.slug, game)
        {:noreply, assign(socket, game: game)}
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  @impl true
  def handle_event("start", %{"game" => params}, socket) do
    params = convert_changeset_params(params, socket.assigns.connected_users)

    if SaladBowlAPI.exists?(socket.assigns.slug) do
      {:noreply, put_flash(socket, :error, "Game already started.")}
    else
      with {:ok, game } <-  Charades.create_salad_bowl(params),
          game_with_first_turn <- Charades.new_turn(game),
          {:ok, _pid } <- SaladBowlAPI.start_game(game_with_first_turn, socket.assigns.slug) do

        broadcast_game_update(socket.assigns.slug, game)
        {:noreply,
        socket
        |> assign(:game, game)}
      else
        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Error creating game.")}
      end
    end
  end

  @impl true
  def handle_event("validate", %{"game" => params}, socket) do
    {:noreply,
    assign(socket, game_changeset: create_game_changeset(params, socket.assigns.connected_users))}
  end

  @impl true
  def handle_event("correct", _params, socket) do
    card_completed(socket, :correct)
  end

  @impl true
  def handle_event("incorrect", _params, socket) do
    card_completed(socket, :incorrect)
  end

  @impl true
  def handle_event("skip", _params, socket) do
    card_completed(socket, :skipped)
  end

  @impl true
  def handle_event("start_turn", _params, socket) do
    {:ok, game} = SaladBowlAPI.start_turn(socket.assigns.slug)
    broadcast_and_assign_game(game, socket)
  end

  @impl true
  def handle_event("end_turn", _params, socket) do
    {:ok, game} = SaladBowlAPI.end_turn(socket.assigns.slug)
    broadcast_and_assign_game(game, socket)
  end

  def handle_event("submit_words", params, socket) do
    word_list = Enum.map(params, fn {_k, v} -> v end)
    case SaladBowlAPI.submit_cards(socket.assigns.slug, word_list, socket.assigns.user.id) do
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
      {:ok, game} ->
        broadcast_and_assign_game(game, socket)
    end
  end

  defp broadcast_and_assign_game(game, socket) do
    broadcast_game_update(socket.assigns.slug, game)
    {:noreply, assign(socket, game: game)}
  end
end
