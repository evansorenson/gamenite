defmodule KodenamesTest do
  use ExUnit.Case
  use GameBuilders

  alias Gamenite.Kodenames
  alias Gamenite.Kodenames.{Card, Turn}

  @deck [
    "AFRICA",
    "AGENT",
    "AIR",
    "ALIEN",
    "ALPS",
    "AMAZON",
    "AMBULANCE",
    "AMERICA",
    "ANGEL",
    "ANTARCTICA",
    "APPLE",
    "ARM",
    "ATLANTIS",
    "AUSTRALIA",
    "AZTEC",
    "BACK",
    "BALL",
    "BAND",
    "BANK",
    "BAR",
    "BARK",
    "BAT",
    "BATTERY",
    "BEACH",
    "BEAR"
  ]

  defp create_game() do
    teams = build_teams([2, 2], %{})

    Kodenames.create(%{room_slug: "ABCDEF", teams: teams, deck: @deck})
  end

  defp working_game(context) do
    {:ok, game} = create_game()

    {:ok, Map.put(context, :game, game)}
  end

  def game_already_setup(context) do
    {:ok, game} = create_game()
    {:ok, Map.put(context, :setup_game, Kodenames.setup_game(game, false))}
  end

  defp defined_board(game) do
    game
    |> elem(1)
    |> Map.put(
      :board,
      %{
        {0, 0} => Card.new(%{type: :red}),
        {0, 1} => Card.new(%{type: :blue}),
        {0, 2} => Card.new(%{type: :bystander}),
        {0, 3} => Card.new(%{type: :assassin})
      }
    )
  end

  defp new_turn(game, attrs \\ %{}) do
    game
    |> Map.put(:current_turn, Turn.new(attrs))
  end

  defp give_teams_scores(game, first_team_score, second_team_score) do
    game
    |> put_in([:current_team, :score], first_team_score)
    |> put_in([:teams, Access.at!(1), :score], second_team_score)
  end

  defp game_with_defined_board(context) do
    game =
      create_game()
      |> defined_board()
      |> new_turn()
      |> give_teams_scores(9, 8)

    {:ok, Map.put(context, :defined_board, game)}
  end

  describe "creating game" do
    setup [:working_game]

    test "game must have at only two teams with four players total" do
      teams = build_teams([1], %Player{})

      deck =
        assert match?(
                 {:error, _},
                 Kodenames.create(%{teams: teams, deck: @deck, room_slug: "ABCDEF"})
               )

      teams = build_teams([2], %Player{})

      assert match?(
               {:error, _},
               Kodenames.create(%{teams: teams, deck: @deck, room_slug: "ABCDEF"})
             )

      teams = build_teams([1, 2], %Player{})

      assert match?(
               {:error, _},
               Kodenames.create(%{teams: teams, deck: @deck, room_slug: "ABCDEF"})
             )

      teams = build_teams([2, 2, 3], %Player{})

      assert match?(
               {:error, _},
               Kodenames.create(%{teams: teams, deck: @deck, room_slug: "ABCDEF"})
             )

      teams = build_teams([2, 2], %Player{})

      assert match?(
               {:ok, _},
               Kodenames.create(%{teams: teams, deck: @deck, room_slug: "ABCDEF"})
             )
    end

    test "randomize which team goes first" do
    end
  end

  describe "creating board: cards and types" do
    setup [:working_game]

    test "board must be initialized with 25 words in 5x5 grid", %{game: game} do
      new_game = Kodenames.setup_game(game, false)

      assert map_size(new_game.board) == 25
    end

    test "removes words used from deck", %{game: game} do
      new_game = Kodenames.setup_game(game, false)

      assert length(new_game.deck) == 0
    end

    test "cards with proper counts when starting team is index 0", %{game: game} do
      new_game = Kodenames.setup_game(game, false)
      assert count_card_types(new_game, :red) == 9
      assert count_card_types(new_game, :blue) == 8
      assert count_card_types(new_game, :bystander) == 7
      assert count_card_types(new_game, :assassin) == 1
    end

    test "cards with proper counts when starting team is index 1", %{game: game} do
      new_game =
        game
        |> TeamGame.end_turn_same_player()
        |> Kodenames.setup_game(false)

      assert count_card_types(new_game, :blue) == 9
      assert count_card_types(new_game, :red) == 8
      assert count_card_types(new_game, :bystander) == 7
      assert count_card_types(new_game, :assassin) == 1
    end

    defp count_card_types(game, card_type) do
      Enum.count(
        Map.to_list(game.board),
        fn {_key, card} -> card.type == card_type end
      )
    end

    test "teams with proper score when starting team is index 0", %{game: game} do
      new_game = Kodenames.setup_game(game, false)
      assert new_game.current_team.score == 9
      assert Enum.at(new_game.teams, 1).score == 8
    end

    test "teams with proper score when starting team is index 1", %{game: game} do
      new_game =
        game
        |> TeamGame.end_turn_same_player()
        |> Kodenames.setup_game(false)

      assert new_game.current_team.score == 9
      assert Enum.at(new_game.teams, 0).score == 8
    end
  end

  describe "giving clues" do
    setup [:game_already_setup]

    test "invalid empty clue", %{setup_game: game} do
      assert {:error, "Clue must not be empty."} ==
               Kodenames.give_clue(game, "", 1)
    end

    test "invalid clue with more than one word (has spaces)", %{setup_game: game} do
      assert {:error, "Clue must be one word (no spaces)."} ==
               Kodenames.give_clue(game, "two words", 1)
    end

    test "invalid number of words", %{setup_game: game} do
      assert {:error, "Number of words must be between 1 and 9 or 'Unlimited'"} ==
               Kodenames.give_clue(game, "correct", 0)

      assert {:error, "Number of words must be between 1 and 9 or 'Unlimited'"} ==
               Kodenames.give_clue(game, "correct", 10)

      assert {:error, "Number of words must be between 1 and 9 or 'Unlimited'"} ==
               Kodenames.give_clue(game, "correct", "some string")
    end

    test "valid unlimited clue", %{setup_game: game} do
      new_game = Kodenames.give_clue(game, "correct", "Unlimited")
      assert new_game.current_turn.clue == "correct"
      assert new_game.current_turn.number_of_words == "Unlimited"
    end

    test "valid one word clue", %{setup_game: game} do
      new_game = Kodenames.give_clue(game, "correct", 1)
      assert new_game.current_turn.clue == "correct"
      assert new_game.current_turn.number_of_words == 1
    end
  end

  describe "selecting words" do
    setup [:game_with_defined_board]

    test "select own color, words left -> continues turn", %{defined_board: game} do
      new_game =
        game
        |> Kodenames.select_card({0, 0})

      assert new_game.current_team.index == 0
    end

    test "select own color, no extra guess, correct equal to clue total -> ends turn",
         %{
           defined_board: game
         } do
      new_game =
        game
        |> new_turn(%{number_of_words: 2, num_correct: 1})
        |> Kodenames.select_card({0, 0})

      assert new_game.current_team.index == 1
    end

    test "select own color, extra guess, correct equal to clue total -> continues turn",
         %{
           defined_board: game
         } do
      new_game =
        game
        |> new_turn(%{number_of_words: 2, num_correct: 1, extra_guess?: true})
        |> Kodenames.select_card({0, 0})

      assert new_game.current_team.index == 0
    end

    test "selecting own color decrements current team score", %{defined_board: game} do
      new_game =
        game
        |> Kodenames.select_card({0, 0})

      assert new_game.current_turn.num_correct == 1
      assert new_game.current_team.score == 8
    end

    test "selecting other teams color decrements their score", %{defined_board: game} do
      new_game =
        game
        |> Kodenames.select_card({0, 1})

      assert new_game.current_team.score == 7
    end

    test "selecting other teams color ends turn", %{defined_board: game} do
      new_game =
        game
        |> Kodenames.select_card({0, 1})

      assert new_game.current_team.index == 1
    end

    test "selecting bystander ends turn", %{defined_board: game} do
      new_game =
        game
        |> Kodenames.select_card({0, 2})

      assert new_game.current_team.index == 1
    end

    test "selecting bystander doesn't change scores", %{defined_board: game} do
      new_game =
        game
        |> Kodenames.select_card({0, 2})

      assert Enum.at(new_game.teams, 0).score == 9
      assert Enum.at(new_game.teams, 1).score == 8
    end

    test "selecting assassin ends game and other team wins", %{defined_board: game} do
      new_game =
        game
        |> Kodenames.select_card({0, 3})

      assert new_game.finished?
      assert new_game.winning_team_idx == 1
    end

    test "selecting own color and getting to 0 score wins game", %{defined_board: game} do
      new_game =
        game
        |> give_teams_scores(1, 1)
        |> Kodenames.select_card({0, 0})

      assert new_game.finished?
      assert new_game.winning_team_idx == 0
    end

    test "selecting other team's color and getting to 0 score wins them the game", %{
      defined_board: game
    } do
      new_game =
        game
        |> give_teams_scores(1, 1)
        |> Kodenames.select_card({0, 1})

      assert new_game.finished?
      assert new_game.winning_team_idx == 1
    end
  end
end
