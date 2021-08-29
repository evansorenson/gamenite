defmodule Core.Games.SaladBowl do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset

  alias Gamenite.Core.TeamGame

  embedded_schema do
    field :rounds, {:array, :string}
    field :current_round, :string
    field :turn_length, :integer, default: 60
    field :skip_limit, :integer, default: 2
    has_many :deck, Card
    has_many :starting_deck, Card
    embems_one :team_game, TeamGame
  end
  @fields [:rounds, :current_round, :deck, :starting_deck]


  # |> Map.put(:current_round, List.first(rounds))

  def inc_round(%__MODULE__{ rounds: rounds, current_round: current_round} = game) do
    _inc_round(game, next_list_element(rounds, current_round))
  end
  defp _inc_round(game, { 0, _ }) do
    Map.replace!(game, :is_finished, true)
  end
  defp _inc_round(game, { _, next_round }) do
    game
    |> Map.replace!(:current_round, next_round)
  end

  def end_round(%__MODULE__{ starting_deck: starting_deck } = game) do
    game
    |> inc_round
    |> move_cards_after_review
    |> update_deck(starting_deck)
  end

end
