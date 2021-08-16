defmodule Gameplay.GameTest do
  use ExUnit.Case
  alias Gameplay
  alias Gameplay.{Player, Team}

  def setup_team(num_players) do
    players = Enum.map(1..num_players, fn player -> setup_player(player) end)
    %Team{ players: players }
  end

  def setup_player(name) do
    %Player{ name: name }
  end

  describe "add players testing" do
    test "add_player/2 add player to single team" do
      teams = [ setup_team(4) ]
      player_to_add = setup_player("johnny")
      updated_teams = Gameplay.add_player(teams, player_to_add)
      updated_team  = Enum.at(updated_teams, 0)

      assert length(updated_team.players) == 5
      assert Enum.at(updated_team.players, 0) == player_to_add
    end

    test "add_player/2 add player to team in teams list of two" do
      teams = [ setup_team(3), setup_team(4) ]
      player_to_add = setup_player("johnny")
      updated_teams = Gameplay.add_player(teams, player_to_add)
      updated_team  = Enum.at(updated_teams, 0)

      assert length(updated_teams) == 2
      assert length(updated_team.players) == 4
      assert length(Enum.at(updated_teams, 1).players) == 4
      assert Enum.at(updated_team.players, 0) == player_to_add
    end

    test "add_player/2 add player to team in teams list of four" do
      teams = [ setup_team(3), setup_team(4), setup_team(2), setup_team(1) ]
      player_to_add = setup_player("johnny")
      updated_teams = Gameplay.add_player(teams, player_to_add)
      updated_team  = Enum.at(updated_teams, 3)

      assert length(updated_teams) == 4
      assert length(updated_team.players) == 2
      assert Enum.at(updated_team.players, 0) == player_to_add
    end
  end
end
