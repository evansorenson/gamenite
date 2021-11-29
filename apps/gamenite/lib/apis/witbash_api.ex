defmodule Gamenite.Witbash.API do
  import Gamenite.Game.API, only: [via: 1]

  def start_round(slug) do
    GenServer.call(via(slug), :start_round)
  end

  def vote(slug, {voting_player_id, receiving_player_id}) do
    GenServer.call(via(slug), {:vote, {voting_player_id, receiving_player_id}})
  end

  def submit_answer(slug, answer) do
    GenServer.call(via(slug), {:submit_answer, answer})
  end
end
