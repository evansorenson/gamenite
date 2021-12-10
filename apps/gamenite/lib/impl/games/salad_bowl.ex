defmodule Gamenite.SaladBowl do
  @behaviour Gamenite.Game
  use Accessible

  use Ecto.Schema
  import Ecto.Changeset

  alias Gamenite.TeamGame
  alias Gamenite.TeamGame.Team
  alias Gamenite.Charades

  @default_rounds Application.get_env(:gamenite, :salad_bowl_default_rounds)
  embedded_schema do
    embeds_one(:current_team, Team)
    embeds_many(:teams, Team)
    field(:room_slug, :string)
    field(:current_turn, :map)
    field(:turn_length, :integer, default: 60)
    field(:skip_limit, :integer, default: 1)
    field(:rounds, {:array, :string}, default: @default_rounds)
    field(:cards_per_player, :integer, default: 4)
    field(:current_round, :string)
    field(:starting_deck, {:array, :string})
    field(:deck, {:array, :string}, default: [])
    field(:submitted_users, {:array, :binary_id}, default: [])
    field(:finished?, :boolean, default: false)
    field(:timer)
  end

  @fields [
    :room_slug,
    :turn_length,
    :skip_limit,
    :deck,
    :current_turn,
    :rounds,
    :current_round,
    :starting_deck,
    :cards_per_player
  ]

  @impl Gamenite.Game
  def changeset(salad_bowl_game, attrs) do
    rounds = Map.get(attrs, :rounds, @default_rounds)
    attrs = Map.put(attrs, :current_round, hd(rounds))

    salad_bowl_game
    |> cast(attrs, @fields)
    |> validate_required(:room_slug)
    |> validate_number(:turn_length, less_than_or_equal_to: 120)
    |> validate_number(:turn_length, greater_than_or_equal_to: 30)
    |> validate_number(:skip_limit, greater_than_or_equal_to: 0)
    |> validate_number(:skip_limit, less_than_or_equal_to: 5)
    |> validate_required([:rounds, :cards_per_player, :current_round])
    |> validate_subset(:rounds, Application.get_env(:gamenite, :all_salad_bowl_rounds))
    |> validate_length(:rounds, min: 1)
    |> validate_number(:cards_per_player, greater_than: 2, less_than_or_equal_to: 10)
  end

  @impl Gamenite.Game
  def create(attrs), do: TeamGame.create(__MODULE__, %__MODULE__{}, attrs)

  @impl Gamenite.Game
  def change(game, attrs), do: TeamGame.change(__MODULE__, game, attrs)

  @impl Gamenite.Game
  def new(), do: %__MODULE__{}

  @impl Gamenite.Game
  def create_player(attrs) do
    TeamGame.Player.create(attrs)
  end
end
