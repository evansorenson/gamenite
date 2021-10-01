defmodule Gamenite.Games.CharadesGame do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    embeds_one :team_game, Gamenite.TeamGame
    field :turn_length, :integer, default: 60
    field :skip_limit, :integer, default: 1
    field :rounds, {:array, :string}, default: Application.get_env(:gamenite, :salad_bowl_default_rounds)
    field :cards_per_player, :integer, default: 4
    field :current_round, :string
    field :starting_deck, {:array, :map}
    field :deck, {:array, :map}
  end
  @fields [:turn_length, :skip_limit, :deck, :starting_deck, :cards_per_player]

  def changeset(changeset, params) do
    changeset
    |> cast(params, @fields)
    |> validate_required([:turn_length, :skip_limit])
    |> validate_number(:turn_length, less_than_or_equal_to: 120)
    |> validate_number(:turn_length, greater_than_or_equal_to: 30)
    |> validate_number(:skip_limit, greater_than_or_equal_to: 0)
    |> validate_number(:skip_limit, less_than_or_equal_to: 5)
  end


  def salad_bowl_changeset(changeset, params) do
    changeset
    |> changeset(params)
    |> cast(params, [:rounds, :cards_per_player])
    |> validate_required([:rounds, :cards_per_player])
    |> validate_subset(:rounds, Application.get_env(:gamenite, :salad_bowl_all_rounds))
    |> validate_length(:rounds, min: 1)
    |> validate_number(:cards_per_player, greater_than: 2, less_than_or_equal_to: 10)
  end

  def finalize_changeset_and_create(team_game, changeset) do
    changeset
    |> put_embed(:team_game, team_game)
    |> validate_required([:team_game])
    |> apply_action!(:update)
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
