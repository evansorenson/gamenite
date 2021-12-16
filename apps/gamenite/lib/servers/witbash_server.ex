defmodule Gamenite.Witbash.Server do
  use Gamenite.Game.Server
  use Gamenite.Timing

  alias Gamenite.Witbash

  def init({game, _room_uuid}) do
    new_game =
      game
      |> start_answering_timer()
      |> Witbash.setup()

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
      |> maybe_next_prompt()
      |> maybe_start_voting_timer()
      |> maybe_start_answering_timer()

    broadcast_game_update(new_game)
    {:noreply, new_game}
  end

  defp maybe_start_voting_timer(game)
       when not game.answering? and length(game.current_prompt.answers) > 1 do
    game
    |> stop_answering_timer()
    |> start_voting_timer()
  end

  defp maybe_start_voting_timer(game), do: game

  defp maybe_start_answering_timer(game) when game.answering? do
    game
    |> stop_voting_timer()
    |> start_answering_timer()
  end

  defp maybe_start_answering_timer(game), do: game

  defp start_answering_timer(game) do
    Timing.start_timer(
      game,
      :answering_timer,
      fn game ->
        game
        |> Witbash.start_voting_phase()
        |> start_voting_timer()
      end,
      game.answer_length_in_sec
    )
  end

  defp stop_answering_timer(game) do
    game
    |> Timing.stop_timer(:answering_timer)
  end

  defp start_voting_timer(game) do
    Timing.start_timer(
      game,
      :voting_timer,
      fn game -> Witbash.score_votes(game) end,
      game.vote_length_in_sec
    )
  end

  defp stop_voting_timer(game) do
    game
    |> Timing.stop_timer(:voting_timer)
  end

  defp maybe_next_prompt(game)
       when not game.answering? and length(game.current_prompt.answers) < 2 do
    next_prompt(game)
  end

  defp maybe_next_prompt(game) when not game.answering? and game.current_prompt.scored? do
    next_prompt(game)
  end

  defp maybe_next_prompt(game), do: game

  defp next_prompt(game) do
    Process.send_after(self(), :next_prompt, 5000)

    game
    |> Timing.stop_timer(:voting_timer)
  end
end
