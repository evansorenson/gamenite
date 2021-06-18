defmodule Gamenite.Cards.Card do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cards" do
    field :front, :string
    belongs_to :deck, Gamenite.Cards.Deck

    timestamps()
  end

  @doc false
  def changeset(card, attrs) do
    card
    |> cast(attrs, [:front])
    |> validate_required([:front])
  end
end
