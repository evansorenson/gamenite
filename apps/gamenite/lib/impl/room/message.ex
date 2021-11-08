defmodule Gamenite.Room.Message do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :user_id, :binary_id
    field :body, :string
    field :sent_at, :utc_datetime
  end

  @fields [:body, :sent_at, :user_id]
  @required [:body, :sent_at, :user_id]

  def changeset(message, attrs) do
    message
    |> cast(attrs, @fields)
    |> validate_required(@required)
    |> validate_length(:body, min: 1, max: 500)
  end
end
