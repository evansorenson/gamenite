defmodule Gamenite.Witbash.Server do
  use Gamenite.Game.Server
  use Gamenite.Timing

  alias Gamenite.Witbash

  def handle_call(:start_round, _from, game) do
    game
    |> Map.put(:time_remaining_in_sec, game.answer_length_in_sec)
    |> Timing.start_timer(&submiting_answers_tick/1)
    |> game_response(game)
  end

  def handle_call({:submit_answer, answer, player_index, prompt_index}, _from, game) do
    game
    |> Witbash.submit_answer(answer, player_index, prompt_index)
    |> maybe_start_voting_timer
    |> game_response(game)
  end

  def handle_call({:vote, {voting_player_id, receiving_player_id}}, _from, game) do
    game
    |> Witbash.vote({voting_player_id, receiving_player_id})
    |> maybe_next_prompt
    |> game_response(game)
  end

  def handle_info(:next_prompt, game) do
    game
    |> Witbash.next_prompt()
    |> game_response(game)
  end

  defp maybe_start_voting_timer(game) when not game.answering? do
    game
    |> Map.put(:time_remaining_in_sec, game.vote_length_in_sec)
    |> Timing.start_timer(&voting_tick/1)
  end

  defp maybe_start_voting_timer(game), do: game

  defp maybe_next_prompt(game) when game.current_prompt.scored? do
    send_next_prompt()
    game
  end

  defp maybe_next_prompt(game), do: game

  defp send_next_prompt do
    Process.send_after(self(), :next_prompt, 5000)
  end

  defp submiting_answers_tick(game) when game.time_remaining_in_sec <= 0 do
    game
    |> Timing.stop_timer()
    |> Witbash.start_voting_phase()
  end

  defp submiting_answers_tick(game) do
    game
    |> decrement_time_and_start_timer(&submiting_answers_tick/1)
  end

  defp voting_tick(game) when game.time_remaining_in_sec <= 0 do
    game
    |> Timing.stop_timer()
    |> Witbash.score_votes()
  end

  defp voting_tick(game) do
    game
    |> decrement_time_and_start_timer(&voting_tick/1)
  end

  defp decrement_time_and_start_timer(game, func) do
    game
    |> Map.update!(:time_remaining_in_sec, &(&1 - 1))
    |> Timing.start_timer(func)
  end
end
