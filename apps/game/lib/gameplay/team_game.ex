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
  def end_turn(game) do
    game
    |> move_cards_after_review
    |> append_turn_to_team
    |> inc_player
    |> inc_team
    |> new_turn
  end

  def end_round(%__MODULE__{ starting_deck: starting_deck } = game) do
    game
    |> inc_round
    |> move_cards_after_review
    |> update_deck(starting_deck)
  end

  defp append_turn_to_team(%__MODULE__{ current_turn: current_turn } = game) do
    game
    |> update_in([:current_team][:turns], fn turns -> [ current_turn | turns ] end)
  end

  defp inc_player(%__MODULE__{ teams: teams, current_team: current_team } = game) do
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

  defp inc_team(%__MODULE__{ teams: teams, current_team: current_team } = game) do
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
    turn = Turn.new(current_team.current_player)

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
    game
    |> Map.replace!(:current_round, next_round)
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

  # def clear_all_players_hands(%__MODULE__{ teams: teams, current_team: current_team } = game) do
  #   cleared_teams = teams
  #   |> Enum.map(&clear_team_hand(&1))

  #   cleared_current_team =  clear_team_hand(current_team)

  #   game
  #   |> Map.replace!(:teams, cleared_teams)
  #   |> replace_current_team(cleared_current_team)
  # end

  # defp clear_team_hand(team) do
  #   Enum.map(team.players, &clear_player_hand(&1))
  # end
  defp clear_current_player_hand(%__MODULE__{ current_team: current_team } = game) do
    game
    |> put_in([:current_team][:current_player][:hand], [])
  end

  def draw_card(%__MODULE__{ deck: deck, current_team: current_team } = game, num \\ 1) do
    case Cards.draw_into_hand(deck, current_team.current_player.hand, num) do
      { :error, _ } ->
        inc_round(game)

      { new_hand,  new_deck } ->
        game
        |> update_current_hand(new_hand)
        |> update_deck(new_deck)
    end
  end

  defp update_deck(game, new_deck) do
    game
    |> Map.replace!(:deck, new_deck)
  end

  def update_current_hand(game, hand) do
    game
    |> put_in([:current_team][:current_player][:hand], hand)
  end

  def start_turn(%__MODULE__{ current_turn: current_turn } = game) do
    game
    |> put_in(current_turn.started_at, DateTime.utc_now())
  end

  def skip_card(%__MODULE__{ current_turn: current_turn, skip_limit: skip_limit } = _game, _card)
  when current_turn.num_cards_skipped >= skip_limit
  do
    {:error, "You have reached skip limit of #{current_turn.skip_limit}"}
  end
  def skip_card(%__MODULE__{ deck: deck} = _game, _card)
  when length(deck) == 0
  do
    {:error, "Cannot skip card. No cards left in deck."}
  end
  def skip_card(game) do
    game
    |> inc_skipped_card
    |> draw_card
  end

  defp inc_skipped_card(game) do
    game
    |> update_in([:current_turn][:num_cards_skipped], &(&1 + 1))
  end

  def card_is_correct(game, card) do
    correct_card = Cards.correct_card(card)

    game
    |> update_card_in_hand(correct_card)
    |> maybe_review_cards
  end

  defp update_card_in_hand(game, card) do
    card_index = find_element_index(game.current_player.hand, card)

    game
    |> put_in([:current_player][:hand][Access.at!(card_index)], card)
  end

  defp maybe_review_cards(%__MODULE__{ current_turn: current_turn, deck: deck } = game)
  when length(deck) == 0 do
    game
    |> put_in(current_turn.needs_review, true)
  end
  defp maybe_review_cards(game), do: game

  defp move_cards_after_review(%__MODULE__{ current_team: current_team} = game) do
    correct_cards = Enum.filter(current_team.current_player.hand, &is_card_correct?(&1))
    incorrect_cards = Enum.reject(current_team.current_player.hand, &is_card_correct?(&1))

    game
    |> add_correct_cards_to_turn(correct_cards)
    |> move_incorrect_back_to_deck(incorrect_cards)
    |> clear_current_player_hand
  end

  defp is_card_correct?(card) when card.is_correct, do: true
  defp is_card_correct?(_card), do: false

  defp add_correct_cards_to_turn(game, cards_correct) do
    game
    |> put_in([:current_turn][:cards_correct], cards_correct)
  end

  defp move_incorrect_back_to_deck(%__MODULE__{ deck: deck } = game, incorrect_cards) do
    new_deck = deck ++ incorrect_cards

    game
    |> update_deck(new_deck)
  end
end
