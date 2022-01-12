defmodule Gamenite.Charades.Turn do
  use Accessible

  defstruct card: nil,
            completed_cards: [],
            player_id: nil,
            turn_length: 0,
            review?: false,
            started?: false

  def new(params) do
    struct!(__MODULE__, params)
  end
end
