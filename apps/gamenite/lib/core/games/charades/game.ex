defmodule Gamenite.Games.Charades.Game do
  use Ecto.Schema
  use Accessible
  import Ecto.Changeset
  alias Gamenite.TeamGame
  alias Gamenite.TeamGame.Team

  embedded_schema do
    embeds_one :current_team, Team
    embeds_many :teams, Team
    embeds_one :current_turn, CharadesTurn
    field :turn_length, :integer, default: 60
    field :skip_limit, :integer, default: 1
    field :rounds, {:array, :string}, default: Application.get_env(:gamenite, :salad_bowl_default_rounds)
    field :cards_per_player, :integer, default: 4
    field :current_round, :string
    field :starting_deck, {:array, :map}
    field :deck, {:array, :map}
    field :finished?, :boolean, default: false
  end
  @fields [:turn_length, :skip_limit, :deck, :starting_deck, :cards_per_player]

  def changeset(charades_game, params) do
    charades_game
    |> TeamGame.changeset(params)
    |> cast(params, @fields)
    |> validate_number(:turn_length, less_than_or_equal_to: 120)
    |> validate_number(:turn_length, greater_than_or_equal_to: 30)
    |> validate_number(:skip_limit, greater_than_or_equal_to: 0)
    |> validate_number(:skip_limit, less_than_or_equal_to: 5)
  end


  def salad_bowl_changeset(salad_bowl_game, %{rounds: rounds} = params) do
    salad_bowl_game
    |> Map.put(:current_round, hd(rounds))
    |> TeamGame.changeset(params)
    |> changeset(params)
    |> cast(params, [:rounds, :cards_per_player])
    |> validate_required([:rounds, :cards_per_player, :current_round])
    |> validate_subset(:rounds, Application.get_env(:gamenite, :salad_bowl_all_rounds))
    |> validate_length(:rounds, min: 1)
    |> validate_number(:cards_per_player, greater_than: 2, less_than_or_equal_to: 10)
  end

  def create(changeset) do
    changeset
    |> apply_action(:update)
  end

  def new_salad_bowl(params) do
    %__MODULE__{}
    |> salad_bowl_changeset(params)
  end

  def new(fields) do
    %__MODULE__{}
    |> changeset(fields)
  end
end
