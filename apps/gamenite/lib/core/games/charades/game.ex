defmodule Gamenite.Games.Charades.Game do
  use Ecto.Schema
  use Accessible
  import Ecto.Changeset
  alias Gamenite.TeamGame
  alias Gamenite.TeamGame.Team

  @default_rounds Application.get_env(:gamenite, :salad_bowl_default_rounds)
  embedded_schema do
    embeds_one :current_team, Team
    embeds_many :teams, Team
    embeds_one :current_turn, CharadesTurn
    field :turn_length, :integer, default: 60
    field :skip_limit, :integer, default: 1
    field :rounds, {:array, :string}, default: @default_rounds
    field :cards_per_player, :integer, default: 4
    field :current_round, :string
    field :starting_deck, {:array, :map}
    field :deck, {:array, :map}
    field :finished?, :boolean, default: false
  end
  @fields [:turn_length, :skip_limit, :deck]
  @salad_bowl_fields [:rounds, :current_round, :starting_deck, :cards_per_player]
  def changeset(charades_game, attrs) do
    charades_game
    |> TeamGame.changeset(attrs)
    |> cast(attrs, @fields)
    |> validate_number(:turn_length, less_than_or_equal_to: 120)
    |> validate_number(:turn_length, greater_than_or_equal_to: 30)
    |> validate_number(:skip_limit, greater_than_or_equal_to: 0)
    |> validate_number(:skip_limit, less_than_or_equal_to: 5)
  end

  def salad_bowl_changeset(salad_bowl_game, attrs) do
    rounds = Map.get(attrs, :rounds, @default_rounds)
    attrs = Map.put(attrs, :current_round, hd(rounds))

    salad_bowl_game
    |> TeamGame.changeset(attrs)
    |> changeset(attrs)
    |> cast(attrs, @salad_bowl_fields)
    |> validate_required([:rounds, :cards_per_player, :current_round])
    |> validate_subset(:rounds, Application.get_env(:gamenite, :all_salad_bowl_rounds))
    |> validate_length(:rounds, min: 1)
    |> validate_number(:cards_per_player, greater_than: 2, less_than_or_equal_to: 10)
  end

end
