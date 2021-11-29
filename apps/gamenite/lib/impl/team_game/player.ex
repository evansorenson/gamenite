defmodule Gamenite.TeamGame.Player do
  use Accessible

  defstruct id: nil, turns: [], score: 0

  def create(attr) do
    struct!(__MODULE__, attr)
  end

  def new_players_from_roommates(roommates) do
    roommates
    |> Enum.map(fn roommate -> %{id: roommate.id} end)
  end
end
