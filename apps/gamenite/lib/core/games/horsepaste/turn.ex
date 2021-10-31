defmodule Gamenite.Games.Horsepaste.Turn do
  use Accessible

  defstruct clue: nil,
            number_of_words: nil,
            clue_time_remaining: nil,
            guess_time_remaining: nil

  def new(params) do
    struct!(__MODULE__, params)
  end
end
