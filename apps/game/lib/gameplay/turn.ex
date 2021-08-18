defmodule Gameplay.PartyTurn do
  defstruct num_cards_skipped: 0, cards_correct: [], player: nil

  def new(player) do
    struct!(
      __MODULE__,
      num_cards_skipped: 0,
      cards_correct: [],
      player: player
    )
  end
end
