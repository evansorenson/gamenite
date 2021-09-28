defmodule Gamenite.TeamGame.Turn do
  defstruct num_cards_skipped: 0, cards_correct: [], player: nil, started_at: nil, needs_review: false

  def new(player) do
    struct!(
      __MODULE__,
      started_at: nil,
      needs_review: false,
      num_cards_skipped: 0,
      cards_correct: [],
      player: player
    )
  end
end
