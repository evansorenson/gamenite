defmodule GamenitePersistance.Cards.WordDeck do
  use Ecto.Schema
  import Ecto.Changeset

  alias GamenitePersistance.Cards.WordCard

  schema "decks" do
    field :title, :string
    has_many :cards, WordCard

    timestamps()
  end

  @doc false
  def changeset(deck, attrs) do
    deck
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
