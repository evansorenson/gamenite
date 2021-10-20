defmodule Gamenite.Games.Poophead do
  alias Gamenite.Games.Poophead.Game
  def setup_game(game) do
    game
    |> add_decks
    |> set_threshold_limit
  end

  defp add_decks(%Game{players: players}) do

  end
end
