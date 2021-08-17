defmodule Gameplay.Team do
  defstruct id: Ecto.UUID, name: nil, score: 0, players: %{}, color: nil, current_player: nil

  @team_colors [:red, :blue, :green, :purple, :green, :orange, :pink ]
  def new(players, index) do
    name = "Team #{Integer.to_string(index - 1)}"
    color = Enum.at(@team_colors, index - 1)

    struct!(
      __MODULE__,
      name: name,
      color: color,
      players: players,
      current_player: List.first(players)
    )
  end


  @doc """
  Splits players into n number of teams.

  Returns [%Gameplay.Team{}]
  """

  def split_teams(players, n) when n * 2 > length(players) do
    {:error, "There must be at least two players per team."}
  end
  def split_teams(_players, n) when n > 7 do
    {:error, "Too many teams. Must be 7 or under."}
  end
  def split_teams(players, n) do
    _split_teams([], Enum.shuffle(players), n)
  end
  defp _split_teams(teams, players, 1) do
  team = Team.new(players, 0)
  [ team | teams ]
  end
  defp _split_teams(teams, players, n) do
    { team_players, remaining_players } = Enum.split(players, div(length(players), n))
    team = Team.new(team_players, n - 1 )
    _split_teams([ team | teams ], remaining_players, n - 1)
  end

  def update_name(team, name) do
    Map.put(team, :name, name)
  end
end
