defmodule Gamenite.GameConfig.Components do
  @enforce_keys [:game, :changeset, :scoreboard, :finished]
  defstruct game: nil, changeset: nil, scoreboard: nil, finished: nil

  def new(attr) do
    struct!(__MODULE__, attr)
  end
end
