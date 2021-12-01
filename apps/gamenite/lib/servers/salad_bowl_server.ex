defmodule Gamenite.SaladBowl.Server do
  use Gamenite.Game.Server

  alias Gamenite.TeamGame
  alias Gamenite.Charades

  use Gamenite.Timing

  def init({game, _room_uuid}) do
    setup_game =
      game
      |> Charades.new_turn(game.turn_length)

    broadcast_game_update(setup_game)
    {:ok, setup_game}
  end

  def handle_call({:add_player, player}, _from, game) do
    game_response(TeamGame.add_player(game, player), game)
  end

  def handle_call(:start_turn, _from, game) do
    game
    |> Charades.start_turn()
    |> Timing.start_timer(&tick/1)
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
        |> Timing.stop_timer()
        |> Charades.needs_review()
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

  def tick(%{current_turn: %{time_remaining_in_sec: time}} = game)
      when time <= 1 do
    game
    |> decrement_time_remaining
    |> Timing.stop_timer()
    |> Charades.needs_review()
  end

  def tick(game) do
    game
    |> Timing.start_timer(&tick/1)
    |> decrement_time_remaining
  end

  defp decrement_time_remaining(game) do
    game
    |> update_in([:current_turn, :time_remaining_in_sec], &(&1 - 1))
  end
end
