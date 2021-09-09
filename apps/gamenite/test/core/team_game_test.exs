defmodule Gamenite.Core.GameTest do
  use ExUnit.Case
  use GameBuilders

  defp working_game(context) do
    {:ok, game } =  GameBuilders.build_game([4, 4])
    {:ok , Map.put(context, :game, game)}
  end


  @max_teams Application.get_env(:gamenite, :max_teams)
  @min_players_on_team Application.get_env(:gamenite, :min_players_on_team)
  defp range_of_teams(context) do
    context
    |> Map.put(:zero_teams, GameBuilders.build_game([]))
    |> Map.put(:one_team, GameBuilders.build_game([@min_players_on_team]))
    |> Map.put(:two_teams, GameBuilders.build_game([@min_players_on_team, @min_players_on_team]))
    |> Map.put(:max_teams, GameBuilders.build_game(Enum.map(1..@max_teams, &(&1 + @min_players_on_team))))
    |> Map.put(:max_teams_plus_one, GameBuilders.build_game(Enum.map(1..@max_teams + 1, &(&1 + @min_players_on_team))))
  end


  defp add_player(context) do
    {:ok, Map.put(context, :player_to_add, build_player("newbie"))}
  end

  describe "new game" do
    setup [:working_game]

    test "current team is set to first team", %{game: game} do
      assert game.current_team == List.first(game.teams)
    end

    test "game is not finished", %{game: game} do
      refute game.is_finished
    end
  end

  describe "new games with range of teams" do
    setup [:range_of_teams]

    test "game with 0 teams throws error", %{zero_teams: zero_teams} do
      assert :error == elem(zero_teams, 0)
    end

    test "games with 1 teams throw error", %{one_team: one_team} do
      assert :error == elem(one_team, 0)
    end

    test "games with 2 teams create successfully", %{two_teams: {:ok, two_teams}} do
      assert length(two_teams.teams) == 2
    end

    test "games at max teams create successfully", %{max_teams: {:ok, max_teams}} do
      assert length(max_teams.teams) == @max_teams
    end

    test "games above max teams create successfully", %{max_teams_plus_one: max_teams_plus_one} do
      assert :error == elem(max_teams_plus_one, 0)
    end
  end

  describe "two teams of four" do
    setup [:working_game, :add_player]

    test "add_player/2 adding player to current team",
    %{game: game, player_to_add: player_to_add} do
      added_current_team = TeamGame.add_player(game, player_to_add).current_team

      assert length(added_current_team.players) == 5
      assert Enum.at(added_current_team.players, 0) == player_to_add
    end
  end

  defp four_teams(context) do
    {:ok, game } = build_game([4, 4, 2, 3])
    {:ok, Map.put(context, :four_team_game, game)}
  end

  describe "four teams" do
    setup [:four_teams, :add_player]

    test "add_player/2 adding player, adds to team with fewest players and not current team", %{four_team_game: game, player_to_add: player} do
      updated_game = TeamGame.add_player(game, player)
      updated_team  = Enum.at(updated_game.teams, 2)

      assert length(updated_team.players) == 3
      assert Enum.at(updated_team.players, 0) == player
    end
  end
end
