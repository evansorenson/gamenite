defmodule Gamenite.PlayingCards.PlayingCard do
  defstruct suit_in_int: nil,
            rank: nil,
            rank_in_int: nil,
            face_img: nil,
            back_img: nil,
            face_up?: false,
            playable?: false

  def new(attrs) do
    struct(__MODULE__, attrs)
  end
end
