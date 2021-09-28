defmodule GamenitePersistance.Cards.Card do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cards" do
    field :face, :string
    field :back, :string
    field :face_image, :string
    field :back_image, :string
    belongs_to :deck, GamenitePersistance.Cards.Deck

    timestamps()
  end

  @doc false
  def changeset(card, attrs) do
    card
    |> cast(attrs, [:face])
    |> validate_required([:face])
  end
end