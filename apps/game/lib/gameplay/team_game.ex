defmodule Gameplay.TeamGame do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset

  alias Gamenite.Cards
  alias Gamenite.Cards.Card
  alias Gameplay.Team
  alias Gameplay.Turn



  embedded_schema do
    field :turn_length, :integer, default: 60
    field :skip_limit, :integer, default: 2
    field :rounds, {:array, :string}
    field :current_round, :string
    field :discard_pile, {:array, :map}
    embeds_one :current_turn, Turn
    embeds_one :current_team, Team
    embeds_many :teams, Team
    has_many :deck, Card
    has_many :starting_deck, Card
  end
  @fields [:turn_length, :skip_limit, :rounds, :current_round, :discard_pile, :current_turn, :current_team, :teams, :deck, :starting_deck]

  # defstruct teams: [],
  # current_team: nil,
  # deck: [],
  # starting_deck: [],
  # discard_pile: [],
  # current_turn: nil,
  # rounds: [],
  # current_round: nil,
  # turn_length: 60,
  # skip_limit: 2,
  # is_finished: false

  def new_game_changeset(fields) do
    %__MODULE__{}
    |> cast(fields, @fields)
    |> validate_required([:teams, :current_team, :rounds, :current_round, :deck, :starting_deck, :current_turn])
    |> validate_length(:teams, min: 2, max: 7)
    |> validate_number(:turn_length, greater_than_or_equal_to: 30, less_than_or_equal_to: 120)
    |> validate_number(:skip_limit, greater_than_or_equal_to: 0)
    |> validate_length(:deck, min: 20, max: 100)
  end

  def new(teams, rounds, deck, fields \\ %{}) do
    current_team = List.first(teams)

    fields
    |> Map.put(:current_team, current_team)
    |> Map.put(:current_round, List.first(rounds))
    |> Map.put(:current_turn, Turn.new(current_team.current_player))
    |> Map.put(:starting_deck, deck)
    |> new_game_changeset()
    |> apply_action(:update)
  end

  @doc """
  Moves to next player's and team's turn.

  Returns %__MODULE__{}.
  """
  def next_player(game) do
    game
    |> end_turn
    |> inc_player
    |> inc_team
    |> new_turn
  end

  def end_turn(%__MODULE__{ current_turn: current_turn } = game) do
    game
    |> update_in([:current_team][:turns], fn turns -> [ current_turn | turns ] end)
  end

  def inc_player(%__MODULE__{ teams: teams, current_team: current_team } = game) do
    game
    |> put_in(
      [:current_team][:players],
      current_team.current_player
    )
    |> update_in(
      [:current_team][:current_player],
      &next_list_element(teams, &1)
    )
  end

  def inc_team(%__MODULE__{ teams: teams, current_team: current_team } = game) do
    { _, next_team } = next_list_element(teams, current_team)

    game
    |> update_team(teams, current_team)
    |> replace_current_team(next_team)
  end

  defp update_team(game, teams, team) do
    game
    |> put_in([:teams][Access.at(find_element_index(teams, team))], team)
  end

  defp replace_current_team(game, next_team) do
    game
    |> Map.replace!(:current_team, next_team)
  end

  def new_turn(%__MODULE__{ current_team: current_team } = game) do
    turn = PartyTurn.new(current_team.current_player)

    game
    |> Map.replace!(:current_turn, turn)
  end

  def inc_round(%__MODULE__{ rounds: rounds, current_round: current_round} = game) do
    _inc_round(game, next_list_element(rounds, current_round))
  end
  defp _inc_round(game, { 0, _ }) do
    Map.replace!(game, :is_finished, true)
  end
  defp _inc_round(game, { _, next_round }) do
    Map.replace!(game, :current_round, next_round)
  end

  defp next_list_element(list, element) do
    curr_idx = find_element_index(list, element)
    next_idx = next_list_index(list, curr_idx)
    { next_idx, Enum.at(list, next_idx) }
  end

  defp find_element_index(list, element) do
    Enum.find_index(list, &(&1 == element))
  end

  defp next_list_index(list, index) when index >= 0 and index < Kernel.length(list), do: rem(index + 1, length(list))
  defp next_list_index(_, _), do: {:error, "Index must be between 0 (inclusive) and length of list "}

  @doc """
  Adds player to either team with lowest number of players or if no teams, to list of players.

  Returns %__MODULE__{}.
  """
  def add_player( %__MODULE__{ teams: teams } = game, player) do
    team_to_add = team_with_lowest_players(teams)
    _add_player(game, team_to_add, player)
  end
  defp _add_player(%{ current_team: current_team } = game, team, player) when current_team.id == team.id do
    game
    |> update_in(
      [:current_team, :players],
      fn players -> [ player | players ] end)
  end
  defp _add_player(%{ teams: teams } = game, team, player) do
    team_index = find_element_index(teams, team)
    game
    |> update_in(
      [:teams, Access.at(team_index), :players],
      fn players -> [ player | players ] end)
  end

  defp team_with_lowest_players(teams) do
    IO.inspect teams
    teams
    |> Enum.sort_by(fn team -> length(team.players) end, :asc)
    |> List.first()
  end

  def reset_deck(game) do
    game
    |> clear_all_players_hands
    |> set_deck_to_starting
  end

  def clear_all_players_hands(%__MODULE__{ teams: teams, current_team: current_team } = game) do
    cleared_teams = teams
    |> Enum.map(&clear_team_hand(&1))

    cleared_current_team =  clear_team_hand(current_team)

    game
    |> Map.replace!(:teams, cleared_teams)
    |> replace_current_team(cleared_current_team)
  end

  defp clear_team_hand(team) do
    Enum.map(team.players, &clear_player_hand(&1))
  end
  defp clear_player_hand(player) do
    player
    |> Map.replace!(:hand, [])
  end

  def set_deck_to_starting(%__MODULE__{ starting_deck: starting_deck } = game) do
    game
    |> Map.replace!(:deck, starting_deck)
    |> Map.replace!(:discard_pile, [])
  end

  def draw_card(%__MODULE__{ deck: deck, discard_pile: discard_pile, current_team: current_team } = game, num) do
    case Cards.draw_into_hand(deck, current_team.current_player.hand, discard_pile, num) do
      { :error, _ } ->
        inc_round(game)

      { new_hand,  new_deck, new_discard_pile } ->
        game
        |> update_current_hand(new_hand)
        |> Map.replace!(:deck, new_deck)
        |> Map.replace!(:discard_pile, new_discard_pile)
    end
  end

  def update_current_hand(game, hand) do
    game
    |> put_in([:current_team][:current_player][:hand], hand)
  end

  def update_discard_pile(game, discard_pile) do
    game
    |> Map.replace!(:discard_pile, discard_pile)
  end

  def skip_card(%__MODULE__{ current_turn: current_turn, skip_limit: skip_limit } = _game, _card)
  when current_turn.num_cards_skipped >= skip_limit
  do
    {:error, "You have reached skip limit of #{current_turn.skip_limit}"}
  end
  def skip_card(%__MODULE__{ discard_pile: discard_pile, current_team: current_team } = game, card) do
    { new_hand, new_discard_pile } =
      Cards.move_card(card, current_team.current_player.hand, discard_pile)

    game
    |> update_current_hand(new_hand)
    |> update_discard_pile(new_discard_pile)
    |> inc_skipped_card
  end

  defp inc_skipped_card(game) do
    game
    |> update_in([:current_turn][:num_cards_skipped], &(&1 + 1))
  end

  def correct_card(%__MODULE__{ current_turn: current_turn, current_team: current_team } = game, card) do
    { new_hand, cards_correct } =
      Cards.move_card(card, current_team.current_player.hand, current_turn.cards_correct)

    game
    |> update_current_hand(new_hand)
    |> add_to_correct_cards(cards_correct)
  end

  defp add_to_correct_cards(game, cards_correct) do
    game
    |> put_in([:current_turn][:cards_correct], cards_correct)
  end
end
