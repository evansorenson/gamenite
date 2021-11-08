defmodule Gamenite.Room.Roommate do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :name, :string
    field :muted?, :boolean, default: false
    field :host?, :boolean, default: false
    field :connected?, :boolean, default: true
  end

  @fields [:id, :name, :muted?, :host?]

  def changeset(roommate, attrs) do
    roommate
    |> cast(attrs, @fields)
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 15)
  end
end
