defmodule Gamenite.Cards.Deck do
  use Ecto.Schema
  import Ecto.Changeset

  schema "decks" do
    field :title, :string
    # has_many :cards

    timestamps()
  end

  @doc false
  def changeset(deck, attrs) do
    deck
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
