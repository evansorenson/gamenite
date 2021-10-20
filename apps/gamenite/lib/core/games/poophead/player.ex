defmodule Gamenite.Games.Poophead.Player do
  use Accessible

  defstruct base_player: nil, facedown: [], faceup: [], hand: [], losses: 0

  def new(attrs) do
    struct(__MODULE__, attrs)
  end
end
