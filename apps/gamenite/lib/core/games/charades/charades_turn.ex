defmodule Gamenite.Games.CharadesTurn do
  defstruct cards_skipped: [], cards_correct: [], player: nil, started_at: nil, needs_review: false

  def new(player) do
    struct!(
      __MODULE__,
      started_at: nil,
      needs_review: false,
      cards_correct: [],
      cards_skipped: [],
      player: player
    )
  end
end
