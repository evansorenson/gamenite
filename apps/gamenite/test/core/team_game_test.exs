defmodule Gamenite.GameTest do
  use ExUnit.Case
  use GameBuilders

  defp working_game(context) do
    {:ok, game} = build_game([2, 2], %{})

    new_context =
      context
      |> Map.put(:game, game)
      |> Map.put(:team_one_id, Enum.at(game.teams, 0).id)
      |> Map.put(:team_two_id, Enum.at(game.teams, 1).id)

    {:ok, new_context}
  end

  defp seven_players(context) do
    players = Enum.map(1..7, fn _i -> %{} end)
    {:ok, Map.put(context, :seven_players, players)}
  end

  defp six_players(context) do
    players = Enum.map(1..6, fn _i -> %{} end)
    {:ok, Map.put(context, :six_players, players)}
  end

  @max_teams Application.get_env(:gamenite, :max_teams)
  @min_players Application.get_env(:gamenite, :min_players)

  defp add_player(context) do
    {:ok, Map.put(context, :player_to_add, %{id: "not in game"})}
  end

  describe "new game" do
    setup [:working_game]

    test "current team is set to first team", %{game: game} do
      assert game.current_team.id == List.first(game.teams).id
    end
  end

  describe "teams required and must be between 2 and max teams in config" do
    test "game with 0 teams are invalid" do
      changeset = build_game_changeset([])
      refute changeset.valid?
    end

    test "games with 1 teams are invalid" do
      changeset = build_game_changeset([2])
      refute changeset.valid?
    end

    test "games with 2 teams create successfully" do
      changeset = build_game_changeset([2, 2])
      assert changeset.valid?
    end

    test "games at max teams create successfully" do
      changeset = build_game_changeset(Enum.map(1..@max_teams, &(&1 + @min_players)))
      assert changeset.valid?
    end

    test "games above max teams are invalid" do
      changeset =
        build_game_changeset(Enum.map(1..(@max_teams + 1), &(&1 + @min_players)))

      refute changeset.valid?
    end
  end

  defp four_teams(context) do
    {:ok, game} = build_game([4, 4, 3, 3])
    {:ok, Map.put(context, :four_team_game, game)}
  end

  describe "adding players" do
    setup [:four_teams, :add_player]

    test "add_player/2 adding player, adds to team with fewest players and not current team", %{
      four_team_game: game,
      player_to_add: player
    } do
      updated_game =
        game
        |> TeamGame.add_player(player)
        |> assert_player_added(game, 2)
        |> TeamGame.add_player(%{player | id: "not in game yet"})
        |> assert_player_added(game, 3)
        |> TeamGame.add_player(%{player | id: "still not in game yet"})
        |> assert_current_team_added_player(game)
        |> TeamGame.add_player(%{player | id: "nope not there already"})
        |> assert_player_added(game, 1)
    end
  end

  defp assert_player_added(%{teams: teams} = game, %{teams: old_teams} = _old_game, index) do
    len_old_team = Team.team_length(Enum.at(old_teams, index))
    len_new_team = Team.team_length(Enum.at(teams, index))
    assert len_old_team + 1 == len_new_team
    game
  end

  defp assert_current_team_added_player(
         %{current_team: current_team} = game,
         %{current_team: old_current_team} = _old_game
       ) do
    assert Team.team_length(old_current_team) + 1 == Team.team_length(current_team)
    game
  end

  describe "ending turns" do
    setup [:working_game]

    test "end_turn/1 appends turn to current team", %{
      game: game,
      team_one_id: team_one_id,
      team_two_id: team_two_id
    } do

      game
      |> TeamGame.end_turn
      |> assert_turns_appended(team_one_id, 1)
      |> TeamGame.end_turn
      |> assert_turns_appended(team_two_id, 1)
      |> TeamGame.end_turn
      |> assert_turns_appended(team_one_id, 2)
      |> TeamGame.end_turn
      |> assert_turns_appended(team_two_id, 2)
    end

    test "end_turn/1 increments player on current team", %{game: game} do

      game
      |> TeamGame.end_turn
      |> assert_current_player(1)
      |> TeamGame.end_turn
      |> assert_current_player(2)
      |> TeamGame.end_turn
      |> assert_current_player(2)
      |> TeamGame.end_turn
      |> assert_current_player(1)
      |> TeamGame.end_turn
      |> assert_current_player(1)
      |> TeamGame.end_turn
      |> assert_current_player(2)
    end

    test "end_turn/1 changes current team to next team in list", %{
      game: game,
      team_one_id: team_one_id,
      team_two_id: team_two_id
    } do
      game
      |> TeamGame.end_turn
      |> assert_next_team(team_two_id)
      |> TeamGame.end_turn
      |> assert_next_team(team_one_id)
      |> TeamGame.end_turn
      |> assert_next_team(team_two_id)
      |> TeamGame.end_turn
      |> assert_next_team(team_one_id)
    end
  end

  defp assert_turns_appended(game, team_id, appended_length) do
    team = Gamenite.Lists.find_element_by_id(game.teams, team_id)
    assert length(team.turns) == appended_length
    game
  end

  defp assert_current_player(game, id) do
    assert game.current_team.current_player.id == id
    game
  end

  defp assert_next_team(game, team_id) do
    assert game.current_team.id == team_id
    game
  end

  describe "splitting into two teams" do
    setup [:six_players, :seven_players]

    test "splitting odd number of players", %{seven_players: players} do
      teams = TeamGame.split_teams(players, 2)
      team_one = Enum.at(teams, 0)
      team_two = Enum.at(teams, 1)
      assert length(teams) == 2
      assert length(team_one.players) == 4
      assert length(team_two.players) == 3
    end

    test "splitting even number of players", %{six_players: players} do
      teams = TeamGame.split_teams(players, 2)
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
      teams = TeamGame.split_teams(players, 3)
      team_one = Enum.at(teams, 0)
      team_two = Enum.at(teams, 1)
      team_three = Enum.at(teams, 2)

      assert length(teams) == 3
      assert length(team_one.players) == 3
      assert length(team_two.players) == 2
      assert length(team_three.players) == 2
    end

    test "splitting even number of players", %{six_players: players} do
      teams = TeamGame.split_teams(players, 3)
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
