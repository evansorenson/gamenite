defmodule GamenitePersistance.Cards.Deck do
  use Ecto.Schema
  import Ecto.Changeset

  alias GamenitePersistance.Cards.Card

  schema "decks" do
    field :title, :string
    has_many :cards, Card

    timestamps()
  end

  @doc false
  def changeset(deck, attrs) do
    deck
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
