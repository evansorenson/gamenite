defmodule Gamenite.Games.Horsepaste.Player do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset

  alias Gamenite.TeamGame.Player

  embedded_schema do
    field(:name, :string)
    field(:color, :string, default: nil)
    field(:spymaster?, :boolean, default: false)
  end

  def changeset(player, attrs) do
    player
    |> Player.changeset(attrs)
  end

  def new(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action!(:update)
  end
end
