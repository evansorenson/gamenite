defmodule Gamenite.Games.CharadesPlayer do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset
  alias Gamenite.TeamGame.Player

  embedded_schema do
    embeds_one :player, Player
    embeds_many :hand, Card
  end

  def changeset(charades_player, %{player: player} = attrs) do
    charades_player
    |> cast(attrs, [:id])
    |> put_embed(:player, player)
    |> validate_required([:player])
  end

  def new(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action!(:update)
  end
end
