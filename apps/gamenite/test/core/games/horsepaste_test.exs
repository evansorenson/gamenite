defmodule HorsePasteTest do
  use ExUnit.Case
  use GameBuilders

  alias Gamenite.Games.Horsepaste
  alias Gamenite.Games.Horsepaste.{Game, Player}

  defp build_game(context) do
    teams = build_teams([2, 2], %{})

    {:ok, game} =
      Horsepaste.create_game(%{room_slug: "ABCDEF", teams: teams})

    new_context =
      context
      |> Map.put(:game, game)

    {:ok, Map.put(context, :game, game)}
  end

  describe "creating game" do
    setup [:build_game]

    test "game must have at only two teams with four players total" do
      teams = build_teams([1], %Player{})
      assert match?({:error, _ }, Horsepaste.create_game(%{teams: teams}))

      teams = build_teams([2], %Player{})
      assert match?({:error, _ }, Horsepaste.create_game(%{teams: teams}))

      teams = build_teams([1, 2], %Player{})
      assert match?({:error, _ }, Horsepaste.create_game(%{teams: teams}))

      teams = build_teams([2, 2, 3], %Player{})
      assert match?({:error, _ }, Horsepaste.create_game(%{teams: teams}))

      teams = build_teams([2, 2], %Player{})
      assert match?({:ok, _ }, Horsepaste.create_game(%{room_slug: "ABCDEF", teams: teams}))
    end



    test "randomize which team goes first" do
    end
  end

  describe "creating board: cards and types" do
    test "board must be initialized with 25 words in 5x5 grid", %{game: game} do
      new_game = Horsepaste.setup_game(game)

      assert map_size(new_game.board) == 25
    end

    test "9 cards for starting team", %{game: game} do
      new_game = Horsepaste.setup_game(game)
      assert count_card_types(new_game, :red) == 9
    end

    test "8 cards for second team", %{game: game} do
      new_game = Horsepaste.setup_game(game)
      assert count_card_types(new_game, :blue) == 9

    end

    test "7 bystanders", %{game: game} do
      new_game = Horsepaste.setup_game(game)
      assert count_card_types(new_game, :bystander) == 9
    end

    test "1 assassin", %{game: game} do
      new_game = Horsepaste.setup_game(game)
      assert count_card_types(new_game, :assassin) == 9

    end

    defp count_card_types(game, card_type) do
      Enum.count(
        Map.to_list(game.board),
        fn {_key, {card, type}} -> type == card_type end)
    end
  end

  describe "giving clues" do
    test "invalid empty clue" do
    end

    test "invalid clue with more than one word (has spaces)" do
    end

    test "valid one word clue" do
    end
  end

  describe "selecting words" do
    test "selecting own color with words left continues turn" do
    end

    test "selecting own color with no words or +1 from previous remaining ends turn" do
    end

    test "select bystander or other teams color ends turn" do
    end

    test "selecting assassin ends game and other team wins" do
    end

    test "selecting red or blue removes point from appropraite team score" do
    end
  end
end
