defmodule Gameplay.TeamGame do
  alias Gamenite.Cards
  alias Gameplay.Team

  defstruct teams: [], current_team: nil, deck: [], discard_pile: [], rounds: [], current_round: nil

  def new(players, num_teams, deck, rounds) do
    teams = Team.split_teams(players, num_teams)
    struct!(__MODULE__,
    teams: teams,
    current_team: List.first(teams),
    deck: deck,
    discard_pile: [],
    rounds: rounds,
    current_round: List.first(rounds),
    is_finished: false)
  end

    @doc """
  Moves to next player's and/or team's turn.

  Returns %__MODULE__{}.
  """
  def next_player(game) do
    game
    |> inc_player
    |> inc_team
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
    |> put_in(team_key(teams, current_team), current_team)
    |> Map.replace!(:current_team, next_team)
  end

  def inc_round(%__MODULE__{ rounds: rounds, current_round: current_round} = game) do
    _inc_round(game, next_list_element(rounds, current_round))
  end
  defp _inc_round(game, { 0, _ }) do
    Map.put(game, :is_finished, true)
  end
  defp _inc_round(game, { _, next_round }) do
    Map.put(game, :current_round, next_round)
  end


  defp next_list_element(list, element) do
    curr_idx = find_index(list, element)
    next_idx = next_list_index(list, curr_idx)
    { next_idx, Enum.at(list, next_idx) }
  end

  defp find_index(list, element) do
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
    |> update_in([:current_team][:players], fn players -> [ player | players ] end)
  end
  defp _add_player(%{ teams: teams } = game, team, player) do
    game
    |> update_in(team_key(teams, team)[:players], fn players -> [ player | players ] end)
  end

  defp team_with_lowest_players(teams) do
    IO.inspect teams
    teams
    |> Enum.sort_by(fn team -> length(team.players) end, :asc)
    |> List.first()
  end

  def reset_deck(%__MODULE__{ deck: deck, discard_pile: discard_pile } = game) do

  end

  def draw_card(%__MODULE__{ deck: deck, discard_pile: discard_pile, current_team: current_team } = game, num) do
    case Cards.draw_into_hand(deck, current_team.current_player.hand, discard_pile, num) do
      { :error, _ } ->
        inc_round(game)

      { new_hand,  new_deck, new_discard_pile } ->
        game
        |> put_in([:current_team][:current_player][:hand], new_hand)
        |> Map.replace!(:deck, new_deck)
        |> Map.replace!(:discard_pile, new_discard_pile)
    end
  end

  def discard(%__MODULE__{ discard_pile: discard_pile, current_team: current_team } = game, card) do
    {new_hand, new_discard_pile } = Cards.discard(card, current_team.current_player.hand, discard_pile)

    game
    |> put_in([:current_team][:current_player][:hand], new_hand)
    |> Map.replace!(:discard_pile, new_discard_pile)
  end

  defp team_key(teams, team) do
    [:teams][Access.at(find_index(teams, team))]
  end
end
