defmodule Gamenite.SaladBowlServer do
  use GenServer
  alias Phoenix.PubSub

  alias Gamenite.Cards
  alias Gamenite.TeamGame
  alias Gamenite.Games.Charades

  def init({game, _room_uuid}) do
    {:ok, game}
  end

  def child_spec({game, room_uuid}) do
    %{
      id: {__MODULE__, room_uuid},
      start: {__MODULE__, :start_link, [{game, room_uuid}]},
      restart: :temporary
    }
  end

  def start_link({game, room_uuid}) do
    GenServer.start_link(
      __MODULE__,
      {game, room_uuid},
      name: via(room_uuid))
  end

  def via(room_uuid) do
    {:via,
    Registry,
    {Gamenite.Registry.Game, room_uuid}}
  end

  def start_child(game, room_uuid) do
    DynamicSupervisor.start_child(
      Gamenite.Supervisor.Game,
      child_spec({game, room_uuid}))
  end

  def game_exists?(room_slug) do
    case Registry.lookup(Gamenite.Registry.Game, room_slug) do
      [{_pid, _val}] -> true
      [] -> false
    end
  end

  defp game_response({:error, reason}, old_state) do
    {:reply, {:error, reason}, old_state}
  end

  defp game_response(new_state, _old_state) do
    broadcast_game_update(new_state)
    {:reply, :ok, new_state}
  end

  defp broadcast_game_update(game) do
    PubSub.broadcast(Gamenite.PubSub, "room:" <> game.room_slug, {:game_update, game})
  end

  def handle_call(:state, _from, game) do
    game_response(game, game)
  end

  def handle_call({:add_player, player}, _from, game) do
    game_response(TeamGame.add_player(game, player), game)
  end

  def handle_call(:start_turn, _from, game) do
    game
    |> Charades.draw_card
    |> start_timer
    |> game_response(game)
  end

  def handle_call(:end_turn, _from, game) do
    game
    |> Charades.end_turn
    |> game_response(game)
  end

  def handle_call({:completed_card, outcome}, _from, game) do
    case Charades.add_card_to_completed(game, outcome) do
      {:review, new_game} ->
        new_game
        |> stop_timer
        |> game_response(game)

      new_game ->
        new_game
        |> game_response(game)
    end
  end

  def handle_call({:submit_cards, word_list, user_id}, _from, game) do
    game
    |> Charades.add_cards_to_deck(word_list, user_id)
    |> game_response(game)
  end

  def handle_info({:tick, _pid}, %{current_turn: %{time_remaining_in_sec: time}} = game)
  when time <= 0 do
    new_game = game
    |> stop_timer
    {:noreply, new_game}
  end

  def handle_info(:tick, game) do
    new_game = update_in(game.current_turn.time_remaining_in_sec, &(&1 - 1))
    broadcast_game_update(new_game)
    {:noreply, new_game}
  end

  defp start_timer(game) do
    {:ok, {:interval, timer}} = :timer.send_interval(1000, self(), :tick)
    Map.put(game, :timer, timer)
  end

  defp stop_timer(%{timer: timer} = game) do
    Process.cancel_timer(timer)
    game
    |> put_in([:current_turn, :needs_review], true)
  end


end
