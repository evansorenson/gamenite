defmodule Gamenite.Rooms.Roommate do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :user_id, :binary_id
    field :display_name, :string
    field :muted?, :boolean, default: false
    field :host?, :boolean, default: false
    field :connected?, :boolean, default: true
  end
  @fields [:user_id, :display_name, :muted?, :host?]

  def changeset(roommate, attrs) do
    roommate
    |> cast(attrs, @fields)
    |> validate_required([:display_name])
  end
end
