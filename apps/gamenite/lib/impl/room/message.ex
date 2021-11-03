defmodule Gamenite.Room.Message do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :roommate, :map
    field :body, :string
    field :sent_at, :utc_datetime
  end

  @fields [:body, :sent_at, :roommate]
  @required [:body, :sent_at]

  def changeset(message, attrs) do
    message
    |> cast(attrs, @fields)
    |> validate_required(@required)
    |> validate_length(:body, min: 1, max: 500)
  end
end
