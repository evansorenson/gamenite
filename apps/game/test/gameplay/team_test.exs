defmodule TeamTest do
  use ExUnit.Case
  use GameBuilders

  defp create_team(context) do
    {:ok, Map.put(context, :team, build_team())}
  end

  defp seven_players(context) do
    players = Enum.map(1..7, &build_player(&1))
    {:ok, Map.put(context, :seven_players, players)}
  end

  defp six_players(context) do
    players = Enum.map(1..6, &build_player(&1))
    {:ok, Map.put(context, :six_players, players)}
  end

  describe "new team constructor" do
    setup [:create_team]

    test "id is not nil", %{team: team} do
      assert not is_nil(team.id)
    end

    test "current player is first player", %{team: team} do
      assert team.current_player == List.first(team.players)
    end

    test "team name is generated properly", %{team: team} do
      assert team.name == "Team 1"
    end

    test "team color is choser properly", %{team: team} do
      assert team.color == :red
    end

    test "update team name", %{team: team} do
      new_name = "FeatherRufflers"
      team_with_new_name = Team.update_name(team, "FeatherRufflers")
      assert team_with_new_name.name == new_name
    end
  end


  describe "splitting into two teams" do
    setup [:six_players, :seven_players]

    test "splitting odd number of players", %{seven_players: players} do
      teams = Team.split_teams(players, 2)
      team_one = Enum.at(teams, 0)
      team_two = Enum.at(teams, 1)
      assert length(teams) == 2
      assert length(team_one.players) == 4
      assert length(team_two.players) == 3
    end

    test "splitting even number of players", %{six_players: players} do
      teams = Team.split_teams(players, 2)
      team_one = Enum.at(teams, 0)
      team_two = Enum.at(teams, 1)
      assert length(teams) == 2
      assert length(team_one.players) == 3
      assert length(team_two.players) == 3
    end
  end

  describe "splitting into three teams" do
    setup [:six_players, :seven_players]

    test "splitting odd number of players", %{seven_players: players} do
      teams = Team.split_teams(players, 3)
      team_one = Enum.at(teams, 0)
      team_two = Enum.at(teams, 1)
      team_three = Enum.at(teams, 2)

      assert length(teams) == 3
      assert length(team_one.players) == 3
      assert length(team_two.players) == 2
      assert length(team_three.players) == 2

    end

    test "splitting even number of players", %{six_players: players} do
      teams = Team.split_teams(players, 3)
      team_one = Enum.at(teams, 0)
      team_two = Enum.at(teams, 1)
      team_three = Enum.at(teams, 2)

      assert length(teams) == 3
      assert length(team_one.players) == 2
      assert length(team_two.players) == 2
      assert length(team_three.players) == 2
    end
  end
end
