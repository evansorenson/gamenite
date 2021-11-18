defmodule Gamenite.Game do
  @callback setup(struct()) :: struct() | {:error, term()}
  @callback changeset(struct(), map()) :: Ecto.Changeset.t()
  @callback create_player(map()) :: struct()
  @callback new() :: struct()
  @callback change(struct(), map()) :: Ecto.Changeset.t()
  @callback create(map()) :: {:ok, struct()} | {:error, Ecto.Changeset.t()}

  import Ecto.Changeset

  def change(module, game, attrs \\ %{}) do
    game
    |> changeset(attrs)
    |> module.changeset(attrs)
  end

  def create(module, game, attrs) do
    game
    |> changeset(attrs)
    |> module.changeset(attrs)
    |> apply_action(:update)
  end

  def changeset(game, attrs) do
    game
    |> cast(attrs, [:room_slug])
    |> validate_required(:room_slug)
  end
end
