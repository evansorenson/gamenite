defmodule Gameplay do
  alias Gameplay.Team
  alias Gameplay.Player


  @doc """
  Moves to next player's and/or team's turn.

  Returns
  """
  def next_player( teams = [ %Team{} | _tail], current_team) do
    { next_team, next_team_index } = next_list_element(teams, current_team)
    next_team_updated = Map.update(next_team, :current_player_index, 0, &(_next_list_index(next_team.players, &1)))
    updated_teams = List.replace_at(teams, next_team_index, next_team_updated)
    { updated_teams , next_team_updated }
  end

  def next_player(players, current_player) do
    next_list_element(players, current_player)
  end

  @doc """
  Adds player to either team with lowest number of players or if no teams, to list of players.

  Returns [%Gameplay.Team{}] or [%Gameplay.Player{}].
  """
  def add_player( teams = [ %Team{} | _tail ], player) do
    team_to_add_to = team_with_lowest_players(teams)
    { _, updated_team } = Map.get_and_update!(team_to_add_to, :players, fn players -> { players, [ player | players ] } end)
    replace_list_elem(teams, team_to_add_to, updated_team)
  end
  def add_player( players, player) do
    [ player | players ]
  end

  defp team_with_lowest_players(teams) do
    IO.inspect teams
    teams
    |> Enum.sort_by(fn team -> length(team.players) end, :asc)
    |> List.first()
  end

  defp replace_list_elem(list, old_value, value) do
    elem_index = Enum.find_index(list, &(&1 == old_value))
    List.replace_at(list, elem_index, value)
  end

  def next_list_element(list, element) do
    index = Enum.find_index(list, &(&1 == element))
    next_index = _next_list_index(list, index)
    next_element = Enum.fetch!(list, next_index)
    { next_element, next_index }
  end

  defp _next_list_index(list, index) when index >= 0 and index < Kernel.length(list), do: rem(index + 1, length(list))
  defp _next_list_index(_, _), do: {:error, "Index must be between 0 (inclusive) and length of list "}
end
