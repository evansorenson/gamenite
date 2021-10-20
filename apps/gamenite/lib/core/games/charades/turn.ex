defmodule Gamenite.Games.Charades.Turn do
  use Accessible

  defstruct card: nil,
            completed_cards: [],
            player_name: nil,
            time_remaining_in_sec: nil,
            needs_review: false

  def new(params) do
    struct!(__MODULE__, params)
  end
end
