defmodule Gamenite.Core.Games.CharadesOptions do
  use Ecto.Schema
  import Ecto.Changeset

  @default_rounds ["Catchphrase", "Password", "Charades"]
  @rounds @default_rounds ++ ["Pictionary"]
  embedded_schema do
    field :turn_length, :integer, default: 60
    field :skip_limit, :integer, default: 1
    field :skip_limit?, :boolean, default: false
    field :rounds, {:array, :string}, default: @default_rounds
    field :current_round, :string
    field :starting_deck, {:array, :map}
  end
  @fields [:turn_length, :skip_limit, :rounds, :current_round, :starting_deck]

  def changeset(charades, params) do
    charades
    |> cast(params, @fields)
    |> validate_number(:turn_length, less_than_or_equal_to: 120)
    |> validate_number(:turn_length, greater_than_or_equal_to: 30)
    |> validate_number(:skip_limit, greater_than_or_equal_to: 0)
    |> validate_number(:skip_limit, less_than_or_equal_to: 5)
  end


  def salad_bowl_changeset(changeset) do
    changeset
    |> validate_required([:current_round, :starting_deck])
    |> validate_subset(:rounds, @rounds)
    |> validate_length(:rounds, min: 1)
  end

  def new_salad_bowl(%{rounds: rounds} = fields) do
    fields
    |> Map.put(:current_round, List.first(rounds))

    %__MODULE__{}
    |> changeset(fields)
    |> salad_bowl_changeset
  end

  def new(fields) do
    %__MODULE__{}
    |> changeset(fields)
  end
end
