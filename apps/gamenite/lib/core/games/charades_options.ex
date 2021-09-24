defmodule Gamenite.Core.Games.CharadesOptions do
  use Ecto.Schema
  import Ecto.Changeset


  embedded_schema do
    field :turn_length, :integer, default: 60
    field :skip_limit, :integer, default: 1
    field :rounds, {:array, :string}, default: Application.get_env(:gamenite, :salad_bowl_default_rounds)
    field :cards_per_player, :integer, default: 4
    field :current_round, :string
    field :starting_deck, {:array, :map}
  end
  @fields [:turn_length, :skip_limit, :starting_deck]

  def changeset(charades, params) do
    charades
    |> cast(params, @fields)
    |> validate_number(:turn_length, less_than_or_equal_to: 120)
    |> validate_number(:turn_length, greater_than_or_equal_to: 30)
    |> validate_number(:skip_limit, greater_than_or_equal_to: 0)
    |> validate_number(:skip_limit, less_than_or_equal_to: 5)
  end


  def salad_bowl_changeset(changeset, params) do
    changeset
    |> cast(params, [:rounds, :cards_per_player])
    |> validate_subset(:rounds, Application.get_env(:gamenite, :salad_bowl_all_rounds))
    |> validate_length(:rounds, min: 1)
    |> validate_number(:cards_per_player, greater_than: 2, less_than_or_equal_to: 10)
  end

  def new_salad_bowl(params) do
    %__MODULE__{}
    |> changeset(params)
    |> salad_bowl_changeset(params)
  end

  def new(fields) do
    %__MODULE__{}
    |> changeset(fields)
  end
end
