defmodule Gamenite.Core.GameTest do
  use ExUnit.Case
  use GameBuilders

  defp working_game(context) do
    {:ok, game } =  GameBuilders.build_game([2, 2])

    new_context = context
    |> Map.put(:game, game)
    |> Map.put(:team_one_id, Enum.at(game.teams, 0).id)
    |> Map.put(:team_two_id, Enum.at(game.teams, 1).id)

    {:ok , new_context}
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

  defp four_teams(context) do
    {:ok, game } = build_game([4, 4, 3, 3])
    {:ok, Map.put(context, :four_team_game, game)}
  end

  describe "adding players" do
    setup [:four_teams, :add_player]

    test "add_player/2 adding player, adds to team with fewest players and not current team", %{four_team_game: game, player_to_add: player} do
      updated_game = game
      |> TeamGame.add_player(player)
      |> assert_player_added(game, 2)
      |> TeamGame.add_player(player)
      |> assert_player_added(game, 3)
      |> TeamGame.add_player(player)
      |> assert_current_team_added_player(game)
      |> TeamGame.add_player(player)
      |> assert_player_added(game, 1)
    end
  end

  defp assert_player_added(%{ teams: teams } = game, %{teams: old_teams } = _old_game, index) do
    len_old_team = Team.team_length(Enum.at(old_teams, index))
    len_new_team = Team.team_length(Enum.at(teams, index))
    assert len_old_team + 1 == len_new_team
    game
  end

  defp assert_current_team_added_player(%{ current_team: current_team } = game, %{ current_team: old_current_team } = _old_game) do
    assert Team.team_length(old_current_team) + 1 == Team.team_length(current_team)
    game
  end

  describe "ending turns" do
    setup [:working_game]

    test "end_turn/1 appends turn to current team", %{ game: game, team_one_id: team_one_id, team_two_id: team_two_id} do
      game
      |> TeamGame.end_turn()
      |> assert_turns_appended(team_one_id, 1)
      |> TeamGame.end_turn()
      |> assert_turns_appended(team_two_id, 1)
      |> TeamGame.end_turn()
      |> assert_turns_appended(team_one_id, 2)
      |> TeamGame.end_turn()
      |> assert_turns_appended(team_two_id, 2)
    end

    test "end_turn/1 increments player on current team", %{ game: game } do
      game
      |> TeamGame.end_turn()
      |> assert_current_player("Player1")
      |> TeamGame.end_turn()
      |> assert_current_player("Player2")
      |> TeamGame.end_turn()
      |> assert_current_player("Player2")
      |> TeamGame.end_turn()
      |> assert_current_player("Player1")
      |> TeamGame.end_turn()
      |> assert_current_player("Player1")
      |> TeamGame.end_turn()
      |> assert_current_player("Player2")
    end

    test "end_turn/1 changes current team to next team in list", %{ game: game, team_one_id: team_one_id, team_two_id: team_two_id} do
      game
      |> TeamGame.end_turn()
      |> assert_next_team(team_two_id)
      |> TeamGame.end_turn()
      |> assert_next_team(team_one_id)
      |> TeamGame.end_turn()
      |> assert_next_team(team_two_id)
      |> TeamGame.end_turn()
      |> assert_next_team(team_one_id)
    end

    ## todo
    test "end_turn/1 creates new turn", %{ game: game} do
      game
      |> TeamGame.end_turn()
    end
  end

  defp assert_turns_appended(game, team_id, appended_length) do
    team = Gamenite.Core.Lists.find_element_by_id(game.teams, team_id)
    assert length(team.turns) == appended_length
    game
  end

  defp assert_current_player(game, player_name) do
    assert game.current_team.current_player.name == player_name
    game
  end

  defp assert_next_team(game, team_id) do
    assert game.current_team.id == team_id
    game
  end

  defp game_with_deck_with_no_cards(context) do
    {:ok, game } =  GameBuilders.build_game([2, 2], 0)

    new_context = context
    |> Map.put(:deck_no_cards, game)

    {:ok , new_context}
  end

  describe "drawing cards" do
    setup [:working_game]

    test "draw cards", %{game: game} do
      updated_game = game
      |> TeamGame.draw_card
      |> assert_deck_length(4)
      |> assert_hand_length(1)
      |> TeamGame.draw_card
      |> assert_deck_length(3)
      |> assert_hand_length(2)
      |> TeamGame.draw_card
      |> assert_deck_length(2)
      |> assert_hand_length(3)
      |> TeamGame.draw_card(2)
      |> assert_deck_length(0)
      |> assert_hand_length(5)
      |> TeamGame.draw_card

      assert updated_game == {:error, "Not enough cards in deck." }
    end
  end

  defp assert_deck_length(%{deck: deck } = game, deck_length) do
    assert length(deck) == deck_length
    game
  end

  defp assert_hand_length(%{current_team: current_team} = game, hand_length) do
    assert length(current_team.current_player.hand) == hand_length
    game
  end

  describe "update fields" do
    setup [:working_game]

    test "update deck", %{game: game} do
      game_with_new_deck = TeamGame.update_deck(game, [1, 2, 3])
      assert game_with_new_deck.deck == [1, 2, 3]
    end

    test "update current hand", %{game: game} do
      updated_game = TeamGame.update_current_hand(game, [1, 2, 3])
      assert updated_game.current_team.current_player.hand == [1, 2, 3]
    end
  end
end
