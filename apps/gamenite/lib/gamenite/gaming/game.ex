defmodule Gamenite.Gaming.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :description, :string
    field :play_count, :integer
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:title, :description, :play_count])
    |> validate_required([:title, :description, :play_count])
  end
end
