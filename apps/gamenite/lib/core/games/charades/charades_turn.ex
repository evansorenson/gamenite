defmodule Gamenite.Games.CharadesTurn do
  defstruct cards_skipped: [], cards_correct: [], player_id: nil, started_at: nil, needs_review: false, finished?: false

  def new(player_id) do
    struct!(
      __MODULE__,
      time_remaining_in_sec: nil,
      needs_review: false,
      cards_correct: [],
      cards_skipped: [],
      player_id: player_id,
      finished?: false,
      timer: nil,
    )
  end
end
