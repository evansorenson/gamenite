defmodule Gamenite.Kodenames.Turn do
  use Accessible

  defstruct clue: nil,
            number_of_words: nil,
            clue_time_remaining: nil,
            guess_time_remaining: nil,
            num_correct: 0,
            extra_guess?: false

  @spec new(any) :: struct
  def new(params) do
    struct!(__MODULE__, params)
  end
end
