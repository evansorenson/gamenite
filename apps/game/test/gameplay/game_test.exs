defmodule Gameplay.GameTest do
  use ExUnit.Case
  use GameBuilders

  describe "new game" do
    setup [:two_teams_of_two]

    test "current round is set to first in list", %{game: game} do
      assert game.current_round == List.first(game.rounds)
    end

    test "current team is set to first team", %{game: game} do
      assert game.current_team == List.first(game.teams)
    end

    test "game is not finished", %{game: game} do
      refute game.is_finished
    end

    test "discard pile is empty list", %{game: game} do
      assert game.discard_pile == []
    end
  end

  describe "two teams of two" do
    setup [:two_teams_of_two, :add_player]
    test "add_player/2 adding player to teams with even count, adds to first element",
    %{game: game, player_to_add: player_to_add} do
      updated_teams = TeamGame.add_player(game, player_to_add).teams
      updated_team  = Enum.at(updated_teams, 0)

      assert length(updated_teams) == 2
      assert length(updated_team.players) == 3
      assert length(Enum.at(updated_teams, 1).players) == 2
      assert Enum.at(updated_team.players, 0) == player_to_add
    end
  end

  describe "four teams" do
    setup [:two_teams_of_four_and_three, :add_player]

    test "add_player/2 adding player, adds to team with fewest players" do
      updated_teams = TeamGame.add_player(game, player_to_add).teams
      updated_team  = Enum.at(updated_teams, 3)

      assert length(updated_teams) == 4
      assert length(updated_team.players) == 2
      assert Enum.at(updated_team.players, 0) == player_to_add
    end
  end


end
