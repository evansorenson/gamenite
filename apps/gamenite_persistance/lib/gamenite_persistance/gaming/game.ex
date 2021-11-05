defmodule GamenitePersistance.Gaming.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :title, :string
    field :play_count, :integer

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:title, :play_count])
    |> validate_required([:title, :play_count])
  end
end
