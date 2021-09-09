defmodule Gamenite.Core.Cards.Card do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :face, :string
    field :back, :string
    field :face_image, :string
    field :back_image, :string
    field :face_up?, :boolean, default: false
    field :is_correct, :boolean, default: false
  end
  @fields [:face, :back, :face_image, :back_image, :face_up?, :is_correct]

  def changeset(card, fields) do
    card
    |> cast(fields,  @fields)
    |> validate_required(:face)
  end

  def new(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:update)
  end

  def persistant_card_to_new() do

  end
end
