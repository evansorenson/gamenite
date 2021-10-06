defmodule Gamenite.Games.Charades.Player do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset

  alias Gamenite.TeamGame.Player

  embedded_schema do
    field :name, :string
    field :color, :string, default: nil
    field :turns, {:array, :map}
  end

  def changeset(charades_player, attrs) do
    charades_player
    |> Player.changeset(attrs)
  end

  def new(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action!(:update)
  end
end
