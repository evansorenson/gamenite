defmodule SaladBowlTest do



  test "score correct cards and add to team score", %{turn_over: game} do
    new_game = Charades.end_turn(game)
    assert hd(new_game.teams).score == 2
  end

  describe "card logic"  do
    setup [:working_game]

    test "drawing card puts card into current player until deck is empty", %{charades: charades} do
      charades
      |> SaladBowlAPI.draw_card()
      |> assert_card_drawn("1")
      |> SaladBowlAPI.draw_card()
      |> assert_card_drawn("2")
      |> SaladBowlAPI.draw_card()
      |> assert_card_drawn("3")
      |> SaladBowlAPI.draw_card()
      |> assert_not_enough_in_deck()
    end

    test "card is added to correct cards in turn when correct", %{charades: charades} do
      charades
      |> SaladBowlAPI.draw_card()
      |> SaladBowlAPI.card_is_correct()
      |> assert_card_moved(:correct_cards, 1)
      |> assert_card_drawn("2")
      |> SaladBowlAPI.card_is_correct()
      |> assert_card_moved(:correct_cards, 2)
      |> assert_card_drawn("3")
      |> SaladBowlAPI.card_is_correct()
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
      assert error == {:error, "You have reached skip limit of #{SaladBowlAPI.skip_limit}"}
    end

    test "skips cards and reaches limit", %{charades: charades} do
      charades
      |> SaladBowlAPI.draw_card
      |> SaladBowlAPI.skip_card
      |> assert_card_moved(:skipped_cards, 1)
      |> assert_card_drawn("2")
      |> SaladBowlAPI.skip_card
      |> assert_skip_limit_reached(charades)
    end

    test "skip cards and deck is depleted", %{charades: charades} do
      charades
      |> SaladBowlAPI.draw_card()
      |> SaladBowlAPI.skip_card()
      |> assert_card_moved(:skipped_cards, 1)
      |> assert_card_drawn("2")
      |> SaladBowlAPI.skip_card()
      |> assert_card_moved(:skipped_cards, 2)
      |> assert_card_drawn("3")
      |> SaladBowlAPI.skip_card()
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
end
