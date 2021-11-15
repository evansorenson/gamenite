defmodule Gamenite.Kodenames.Card do
  use Accessible

  defstruct word: nil,
            type: nil,
            flipped?: false

  def new(params) do
    struct!(__MODULE__, params)
  end
end
