defmodule Gamenite.Game do
  @callback create(attrs :: map()) ::
              {:ok, new_struct :: struct()} | {:error, reason :: Ecto.Changeset.t()}
  @callback change(struct :: struct(), attrs :: map()) :: Ecto.Changeset.t()
end
