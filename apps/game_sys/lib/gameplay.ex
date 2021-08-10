defmodule GameSys.Gameplay do
  alias GameSys.Team
  alias GameSys.Player

  def next_player( teams = [ %Team{} | _tail], current_team) do
    { next_team, next_team_index } = next_list_element(teams, current_team)
    {_, next_team_updated} = Map.get_and_update!(next_team, :player_index, &({&1, _next_list_index(next_team.players, &1)}))
    updated_teams = List.replace_at(teams, next_team_index, next_team_updated)
    { updated_teams , next_team_updated }
  end

  def next_player(players, current_player) do
    next_list_element(players, current_player)
  end

  # add player to team with lowest number of players, with score as tiebreaker
  def add_player( teams = [ %Team{} | _tail ], player) do
    teams
    |> Enum.sort_by(&length(&1), :asc)
    |> List.first()
    |> Map.get_and_update!(:players, fn players -> [ player | players ] end)
  end
  def add_player( players, player) do
    [ player | players ]
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
