defmodule Gamenite.Game do
  @callback create(attrs :: map()) ::
              {:ok, new_struct :: struct()} | {:error, reason :: Ecto.Changeset.t()}
  @callback change(struct :: struct(), attrs :: map()) :: Ecto.Changeset.t()

  import Ecto.Changeset

  def changeset(game, attrs) do
    game
    |> cast(attrs, [:room_slug])
    |> validate_required(:room_slug)
  end
end
