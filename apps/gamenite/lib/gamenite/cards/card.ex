defmodule Gamenite.Cards.Card do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cards" do
    field :face, :string
    field :back, :string
    field :face_image, :string
    field :back_image, :string
    field :is_face_up, :boolean, default: false, virtual: true
    field :is_correct, :boolean, default: false, virtual: true
    belongs_to :deck, Gamenite.Cards.Deck

    timestamps()
  end

  @doc false
  def changeset(card, attrs) do
    card
    |> cast(attrs, [:face])
    |> validate_required([:face])
  end
end
