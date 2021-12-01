defmodule Gamenite.Witbash.Server do
  use Gamenite.Game.Server
  use Gamenite.Timing

  alias Gamenite.Witbash

  def init({game, _room_uuid}) do
    new_game =
      game
      |> Map.put(:time_remaining_in_sec, game.answer_length_in_sec)
      |> Timing.start_timer(&submiting_answers_tick/1)

    broadcast_game_update(new_game)
    {:ok, new_game}
  end

  def handle_call({:submit_answer, answer}, _from, game) do
    game
    |> Witbash.submit_answer(answer)
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
    new_game =
      Witbash.next_prompt(game)
      |> maybe_start_voting_timer()
      |> maybe_start_answering_timer()

    broadcast_game_update(new_game)
    {:noreply, new_game}
  end

  defp maybe_start_voting_timer(game) when not game.answering? do
    game
    |> Timing.stop_timer()
    |> Map.put(:time_remaining_in_sec, game.vote_length_in_sec)
    |> Timing.start_timer(&voting_tick/1)
  end

  defp maybe_start_voting_timer(game), do: game

  defp maybe_start_answering_timer(game) when game.answering? do
    game
    |> Timing.stop_timer()
    |> Map.put(:time_remaining_in_sec, game.answer_length_in_sec)
    |> Timing.start_timer(&submiting_answers_tick/1)
  end

  defp maybe_start_answering_timer(game), do: game

  defp maybe_next_prompt(game) when game.current_prompt.scored? do
    Process.send_after(self(), :next_prompt, 5000)

    game
    |> Timing.stop_timer()
  end

  defp maybe_next_prompt(game), do: game

  defp submiting_answers_tick(game) when game.time_remaining_in_sec <= 1 do
    game
    |> decrement_time()
    |> Timing.stop_timer()
    |> Witbash.start_voting_phase()
  end

  defp submiting_answers_tick(game) do
    game
    |> decrement_time()
    |> Timing.start_timer(&submiting_answers_tick/1)
  end

  defp voting_tick(game) when game.time_remaining_in_sec <= 1 do
    game
    |> decrement_time()
    |> Timing.stop_timer()
    |> Witbash.score_votes()
  end

  defp voting_tick(game) do
    game
    |> decrement_time
    |> Timing.start_timer(&voting_tick/1)
  end

  defp decrement_time(game) do
    game
    |> Map.update!(:time_remaining_in_sec, &(&1 - 1))
  end
end
