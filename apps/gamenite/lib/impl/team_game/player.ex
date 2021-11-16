defmodule Gamenite.TeamGame.Player do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:name, :string)
    field(:color, :string, default: nil)
    field(:turns, {:array, :map})
  end

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

  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name, :color, :id])
    |> validate_required([:name, :color, :id])
    |> validate_length(:name, min: 2, max: 15)
  end

  def new(attrs) do
    %__MODULE__{}
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action!(:update)
  end

  def new_players_from_roommates(roommates) do
    roommates
    |> Enum.with_index()
    |> Enum.map(fn {roommate, index} ->
      %{id: roommate.id, color: Enum.at(@player_colors, index), name: roommate.name}
    end)
  end
end
