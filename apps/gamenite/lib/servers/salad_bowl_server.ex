defmodule Gamenite.SaladBowl.Server do
  use GenServer

  import Gamenite.GameServer

  alias Gamenite.TeamGame
  alias Gamenite.Charades

  def init({game, _room_uuid}) do
    game_with_first_turn = Charades.new_turn(game, game.turn_length)
    broadcast_game_update(game_with_first_turn)
    {:ok, game_with_first_turn}
  end

  def handle_call(:state, _from, game) do
    {:reply, {:ok, game}, game}
  end

  def handle_call({:add_player, player}, _from, game) do
    game_response(TeamGame.add_player(game, player), game)
  end

  def handle_call(:start_turn, _from, game) do
    game
    |> Charades.start_turn()
    |> start_timer
    |> game_response(game)
  end

  def handle_call(:end_turn, _from, game) do
    game
    |> Charades.end_turn()
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

  def handle_call({:change_card_outcome, card_index, outcome}, _from, game) do
    game
    |> Charades.change_card_outcome(card_index, outcome)
    |> game_response(game)
  end

  def handle_info(:tick, %{current_turn: %{time_remaining_in_sec: time}} = game)
      when time <= 0 do
    new_game =
      game
      |> stop_timer

    broadcast_game_update(new_game)
    {:noreply, new_game}
  end

  def handle_info(:tick, game) do
    new_game =
      game
      |> start_timer
      |> decrement_time_remaining

    broadcast_game_update(new_game)
    {:noreply, new_game}
  end

  defp start_timer(game) do
    timer = Process.send_after(self(), :tick, 1000)
    Map.put(game, :timer, timer)
  end

  defp decrement_time_remaining(game) do
    game
    |> update_in([:current_turn, :time_remaining_in_sec], &(&1 - 1))
  end

  defp stop_timer(%{timer: timer} = game) do
    Process.cancel_timer(timer)

    game
    |> put_in([:current_turn, :review?], true)
  end
end
