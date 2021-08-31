defmodule Gameplay.GameTest do
  use ExUnit.Case
  use GameBuilders

  defp two_teams_of_two(context) do
    {:ok , Map.put(context, :game, build_game([2, 2]))}
  end

  @max_teams Application.get_env(:gamenite, :max_teams
  defp range_of_teams(context) do

    games = Enum.map(
      1..(@max_teams + 3),
      &build_game(Enum.map(1..&1, 3)))

    {:ok, Map.put(context, :games, games)}
  end

  defp add_player(context) do
    {:ok, Map.put(context, :player_to_add, build_player("newbie"))}
  end

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
  end

  describe "new games with range of teams" do
    setup [:range_of_teams]

    test "game with 0 teams throws error", do
      assert build_game([]) == {:error, _}
    end

    test "games with less than 2 teams throw error", %{games: games} do
      assert games[0] == {:error, _ }
    end

    test "games between 2 and max teams create succesfully" do
      for i <- 1..@max_teams - 1 do
        assert games[i] == %TeamGame{}
      end
    end

    test "games above max teams throw errors" do
      for i <- @max_teams..@max_teams + 2 do
        assert games[i] == {:error, _}
      end
    end
  end

  describe "two teams of two" do
    setup [:two_teams_of_two, :add_player]

    test "add_player/2 adding player to current team",
    %{game: game, player_to_add: player_to_add} do
      added_current_team = TeamGame.add_player(game, player_to_add).current_team

      assert length(added_current_team.players) == 3
      assert Enum.at(added_current_team.players, 0) == player_to_add
    end
  end

  defp four_teams(context) do
    {:ok, Map.put(context, :four_team_game, build_game([4, 3, 2, 3]))}
  end

  describe "four teams" do
    setup [:four_teams, :add_player]

    test "add_player/2 adding player, adds to team with fewest players", %{four_team_game: game, player_to_add: player} do
      updated_game = TeamGame.add_player(game, player)
      updated_teams = updated_game.teams
      updated_team  = Enum.at(updated_teams, 2)

      assert length(updated_teams) == 4
      assert length(updated_team.players) == 3
      assert Enum.at(updated_team.players, 0) == player
    end
  end


end
