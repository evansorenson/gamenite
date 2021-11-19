defmodule Gamenite.TeamGame.Player do
  use Accessible

  defstruct id: nil, color: nil, turns: [], score: 0

  @player_colors [
    "F2F3F4",
    "222222",
    "F3C300",
    "875692",
    "F38400",
    "A1CAF1",
    "BE0032",
    "C2B280",
    "848482",
    "008856",
    "E68FAC",
    "0067A5",
    "F99379",
    "604E97",
    "F6A600",
    "B3446C",
    "DCD300",
    "882D17",
    "8DB600",
    "654522",
    "E25822",
    "2B3D26"
  ]

  def create(attr) do
    struct!(__MODULE__, attr)
  end

  def new_players_from_roommates(roommates) do
    roommates
    |> Enum.with_index()
    |> Enum.map(fn {roommate, index} ->
      %{id: roommate.id, color: Enum.at(@player_colors, index)}
    end)
  end
end
