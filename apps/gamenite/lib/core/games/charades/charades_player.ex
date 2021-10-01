defmodule Gamenite.Games.CharadesPlayer do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset
  alias Gamenite.TeamGame.Player

  embedded_schema do
    embeds_one :player, Player
    embeds_many :hand, Card
  end

  def changeset(charades_player, %{player: player, hand: hand} = _attrs) do
    charades_player
    |> put_embed(:player, player)
    |> cast_embed(:hand, hand)
    |> validate_required([:player, :hand])
  end

  def new(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:update)
  end
end
