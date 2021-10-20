defmodule Gamenite.Games.Poophead.Game do
  use Ecto.Schema
  import Ecto.Changeset

  alias Gamenite.Games.Poophead.{Player}
  alias Gamenite.Cards.PlayingCard

  embedded_schema do
    field :players, {:array, :map}
    field :deck, {:array, :map}
    field :submitted_machines, {:array, :string}
    field :votes, {:array, :integer}
    field :winning_machine, :string
    field :flush_threshold, :integer
    field :phase, :string
  end
  @fields [:players, :deck]
  @phases [""]

  def changeset(game, attrs) do
    game
    |> cast(@fields, attrs)
    |> validate_required([:players])
    |> validate_length(:players, min: 2)
  end
end
