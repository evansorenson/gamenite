defmodule HorsePasteTest do
  use ExUnit.Case
  use GameBuilders

  alias Gamenite.Games.Horsepaste
  alias Gamenite.Games.Horsepaste.{Game, Player, Card}

  defp create_game() do
    teams = build_teams([2, 2], %{})

    deck = [
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

    Horsepaste.create_game(%{room_slug: "ABCDEF", teams: teams, deck: deck})
  end

  defp working_game(context) do
    {:ok, game} = create_game()

    {:ok, Map.put(context, :game, game)}
  end

  def game_already_setup(context) do
    {:ok, game} = create_game()
    {:ok, Map.put(context, :setup_game, Horsepaste.setup_game(game, false))}
  end

  defp defined_board() do
    create_game()
    |> elem(1)
    |> Map.put(
      :board,
      %{
        {0, 0} => Card.new(%{type: :blue}),
        {0, 1} => Card.new(%{type: :red}),
        {0, 2} => Card.new(%{type: :bystander}),
        {0, 3} => Card.new(%{type: :assassin})
      }
    )
  end

  defp game_with_defined_board(context) do
    game = defined_board()

    {:ok, Map.put(context, :defined_board, game)}
  end

  describe "creating game" do
    setup [:working_game]

    test "game must have at only two teams with four players total" do
      teams = build_teams([1], %Player{})
      assert match?({:error, _}, Horsepaste.create_game(%{teams: teams}))

      teams = build_teams([2], %Player{})
      assert match?({:error, _}, Horsepaste.create_game(%{teams: teams}))

      teams = build_teams([1, 2], %Player{})
      assert match?({:error, _}, Horsepaste.create_game(%{teams: teams}))

      teams = build_teams([2, 2, 3], %Player{})
      assert match?({:error, _}, Horsepaste.create_game(%{teams: teams}))

      teams = build_teams([2, 2], %Player{})
      assert match?({:ok, _}, Horsepaste.create_game(%{room_slug: "ABCDEF", teams: teams}))
    end

    test "randomize which team goes first" do
    end
  end

  describe "creating board: cards and types" do
    setup [:working_game]

    test "board must be initialized with 25 words in 5x5 grid", %{game: game} do
      new_game = Horsepaste.setup_game(game, false)

      assert map_size(new_game.board) == 25
    end

    test "removes words used from deck", %{game: game} do
      new_game = Horsepaste.setup_game(game, false)

      assert length(new_game.deck) == 0
    end

    test "cards with proper counts when starting team is index 0", %{game: game} do
      new_game = Horsepaste.setup_game(game, false)
      assert count_card_types(new_game, :red) == 9
      assert count_card_types(new_game, :blue) == 8
      assert count_card_types(new_game, :bystander) == 7
      assert count_card_types(new_game, :assassin) == 1
    end

    test "cards with proper counts when starting team is index 1", %{game: game} do
      new_game =
        game
        |> TeamGame.next_team()
        |> Horsepaste.setup_game(false)

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
      new_game = Horsepaste.setup_game(game, false)
      assert new_game.current_team.score == 9
      IO.inspect(new_game)
      assert Enum.at(new_game.teams, 1).score == 8
    end

    test "teams with proper score when starting team is index 1", %{game: game} do
      new_game =
        game
        |> TeamGame.next_team()
        |> Horsepaste.setup_game(false)

      assert new_game.current_team.score == 9
      assert Enum.at(new_game.teams, 0).score == 8
    end
  end

  describe "giving clues" do
    setup [:game_already_setup]

    test "invalid empty clue", %{setup_game: game} do
      assert {:error, "Clue must not be empty."} ==
               Horsepaste.give_clue(game, "", 1)
    end

    test "invalid clue with more than one word (has spaces)", %{setup_game: game} do
      assert {:error, "Clue must be one word (no spaces)."} ==
               Horsepaste.give_clue(game, "two words", 1)
    end

    test "invalid number of words", %{setup_game: game} do
      assert {:error, "Number of words must be between 1 and 9 or 'Unlimited'"} ==
               Horsepaste.give_clue(game, "correct", 0)

      assert {:error, "Number of words must be between 1 and 9 or 'Unlimited'"} ==
               Horsepaste.give_clue(game, "correct", 10)

      assert {:error, "Number of words must be between 1 and 9 or 'Unlimited'"} ==
               Horsepaste.give_clue(game, "correct", "some string")
    end

    test "valid unlimited clue", %{setup_game: game} do
      new_game = Horsepaste.give_clue(game, "correct", "Unlimited")
      assert new_game.current_turn.clue == "correct"
      assert new_game.current_turn.number_of_words == "Unlimited"
    end

    test "valid one word clue", %{setup_game: game} do
      new_game = Horsepaste.give_clue(game, "correct", 1)
      assert new_game.current_turn.clue == "correct"
      assert new_game.current_turn.number_of_words == 1
    end
  end

  describe "selecting words" do
    setup [:game_with_defined_board]

    test "selecting own color with words left continues turn", %{defined_board: game} do
    end

    test "selecting own color with no extra guess and number correct equal to clue total ends turn",
         %{
           defined_board: game
         } do
    end

    test "selecting own color with extra guess and number correct equal to clue total continues turn",
         %{
           defined_board: game
         } do
    end

    test "selecting own color decrements current team score", %{defined_board: game} do
    end

    test "selecting other teams color decrements their score", %{defined_board: game} do
    end

    test "selecting other teams color ends turn", %{defined_board: game} do
    end

    test "selecting bystander ends turn", %{defined_board: game} do
    end

    test "selecting bystander doesn't change scores", %{defined_board: game} 
    end

    test "selecting assassin ends game and other team wins", %{defined_board: game} do
    end

    test "getting to 0 score wins game" do
    end
  end
end