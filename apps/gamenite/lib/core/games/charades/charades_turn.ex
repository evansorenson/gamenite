defmodule Gamenite.Games.CharadesTurn do
  defstruct cards_skipped: [], cards_correct: [], player_id: nil, started_at: nil, needs_review: false

  def new(player_id) do
    struct!(
      __MODULE__,
      started_at: nil,
      needs_review: false,
      cards_correct: [],
      cards_skipped: [],
      player_id: player_id
    )
  end
end
