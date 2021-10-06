defmodule CharadesCoreTest do
  use ExUnit.Case
  use GameBuilders

  alias Gamenite.Games.Charades
  alias Gamenite.Games.Charades.{Game, Player, Turn}

  defp working_game(context) do
    teams = build_teams([2,2], %Player{})
    deck = build_deck(3)

    game = Game.new(%{teams: teams, deck: deck, skip_limit: 1})
    |> Game.create()
    |> elem(1)
    |> Map.put(:current_turn, Turn.new(%{}))

    new_context = context
    |> Map.put(:charades, game)
    {:ok , new_context}
  end

  defp build_salad_bowl(context) do
    teams = build_teams([2,2], %Player{})
    deck = build_deck(3)

    salad_bowl = Game.new(%{teams: teams, deck: deck, skip_limit: 1, rounds: ["Catchphrase", "Password", "Charades"]})
    |> Game.create()
    |> elem(1)
    |> Map.put(:current_turn, Turn.new(%{}))

    {:ok, Map.put(context, :salad_bowl, salad_bowl)}
  end

  describe "setup game" do
    setup [:working_game, :build_salad_bowl]

    test "current round is set to first in list", %{salad_bowl: salad_bowl} do
      assert salad_bowl.current_round == "Catchphrase"
    end
  end

  describe "end turn" do
    test "skipped or incorrect cards back to deck" do

    end

    test "score correct cards and add to team score" do

    end

    test "new turn created" do

    end
  end

  describe "card logic"  do
    setup [:working_game]

    test "drawing card puts card into current player until deck is empty", %{charades: charades} do
      charades
      |> Charades.draw_card()
      |> assert_card_drawn("1")
      |> Charades.draw_card()
      |> assert_card_drawn("2")
      |> Charades.draw_card()
      |> assert_card_drawn("3")
      |> Charades.draw_card()
      |> assert_not_enough_in_deck()
    end

    test "card is added to correct cards in turn when correct", %{charades: charades} do
      charades
      |> Charades.draw_card()
      |> Charades.card_is_correct()
      |> assert_card_moved(:correct_cards, 1)
      |> assert_card_drawn("2")
      |> Charades.card_is_correct()
      |> assert_card_moved(:correct_cards, 2)
      |> assert_card_drawn("3")
      |> Charades.card_is_correct()
      |> assert_needs_review
      |> assert_card_moved(:correct_cards, 3)
    end

    defp assert_card_moved(game, pile, length_of_cards ) do
      assert length(get_in(game, [:current_turn, pile])) == length_of_cards
      game
    end

    defp assert_needs_review({:review_cards, game}) do
      assert game.current_turn.needs_review
      game
    end

    defp assert_skip_limit_reached(error, charades) do
      assert error = {:error, "You have reached skip limit of #{charades.skip_limit}"}
    end

    test "skips cards and reaches limit", %{charades: charades} do
      charades
      |> Charades.draw_card()
      |> Charades.skip_card()
      |> assert_card_moved(:skipped_cards, 1)
      |> assert_card_drawn("2")
      |> Charades.skip_card()
      |> assert_skip_limit_reached(charades)
    end

    test "skip cards and deck is depleted", %{charades: charades} do
      charades
      |> Charades.draw_card()
      |> Charades.skip_card()
      |> assert_card_moved(:skipped_cards, 1)
      |> assert_card_drawn("2")
      |> Charades.skip_card()
      |> assert_card_moved(:skipped_cards, 2)
      |> assert_card_drawn("3")
      |> Charades.skip_card()
      |> assert_needs_review
      |> assert_card_moved(:skipped_cards, 3)
    end
  end

  defp assert_card_drawn(%{current_turn: current_turn} = game, card) do
    assert current_turn.card.face == card
    game
  end

  defp assert_not_enough_in_deck(error) do
    assert error == {:error, "Not enough cards in deck."}
  end

  describe "update fields" do
    setup [:working_game]

    test "update deck", %{charades: charades} do
      game_with_new_deck = Charades.update_deck(charades, [1, 2, 3])
      assert game_with_new_deck.deck == [1, 2, 3]
    end
  end
end
