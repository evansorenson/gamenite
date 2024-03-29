defmodule Gamenite.Cards.CardTest do
  use ExUnit.Case

  alias Gamenite.Cards
  alias Gamenite.Cards.Card

  defp build_deck_10(context) do
    deck = for i <- 1..10, do: i
    {:ok, Map.put(context, :deck, deck)}
  end

  defp build_discard_pile_5(context) do
    pile = for i <- 1..5, do: i
    {:ok, Map.put(context, :discard_pile, pile)}
  end

  describe "drawing cards" do
    setup [:build_deck_10]

    test "draw/2 draw negative Card", %{deck: deck} do
      assert Cards.draw(deck, -5) == {:error, "Number of cards drawn must be positive integer."}
    end

    test "draw/2 draw zero Card", %{deck: deck} do
      assert Cards.draw(deck, 0) == {:error, "Number of cards drawn must be positive integer."}
    end

    test "draw/2 draw decimal Card", %{deck: deck} do
      assert Cards.draw(deck, 5.6) == {:error, "Number of cards drawn must be positive integer."}
    end

    test "draw/2 draw too many Card", %{deck: deck} do
      assert Cards.draw(deck, 11) == {:error, "Not enough cards in deck."}
    end

    def test_drawn_card(deck, drawn_card, remaining_deck, num) do
      assert Kernel.length(drawn_card) == num
      assert Kernel.length(remaining_deck) == Kernel.length(deck) - num
      assert drawn_card == Enum.take(deck, num)
    end

    test "draw/2 draw 1 card", %{deck: deck} do
      num = 1
      {drawn_card, remaining_deck} = Cards.draw(deck, num)
      test_drawn_card(deck, drawn_card, remaining_deck, num)
    end

    test "draw/2 draw 3 Card", %{deck: deck} do
      num = 3
      {drawn_card, remaining_deck} = Cards.draw(deck, num)
      test_drawn_card(deck, drawn_card, remaining_deck, num)
    end

    test "draw/2 draw all Card in deck", %{deck: deck} do
      num = 10
      {drawn_card, remaining_deck} = Cards.draw(deck, num)
      test_drawn_card(deck, drawn_card, remaining_deck, num)
    end
  end

  def test_reshuffled_card(
        deck,
        discard_pile,
        drawn_card,
        remaining_deck,
        remaining_discard_pile,
        num
      ) do
    assert Kernel.length(drawn_card) == num

    assert Kernel.length(remaining_deck) + Kernel.length(remaining_discard_pile) ==
             Kernel.length(deck) + Kernel.length(discard_pile) - num
  end

  describe "draw_with_reshuffle" do
    setup [:build_deck_10, :build_discard_pile_5]

    test "draw_with_reshuffle/4 draw more than in deck and discard pile combined", %{
      deck: deck,
      discard_pile: discard_pile
    } do
      assert Cards.draw_with_reshuffle(deck, discard_pile, 50) ==
               {:error,
                "Number of cards drawn must be less than left in deck and discard pile combined."}
    end

    test "draw_with_reshuffle/4 deck has zero cards, reshuffle and draw from discard pile", %{
      discard_pile: discard_pile
    } do
      deck = []
      num = 4

      {drawn_card, remaining_deck, remaining_discard_pile} =
        Cards.draw_with_reshuffle(deck, discard_pile, num)

      test_reshuffled_card(
        deck,
        discard_pile,
        drawn_card,
        remaining_deck,
        remaining_discard_pile,
        num
      )
    end

    test "draw_with_reshuffle/4 deck has some cards, reshuffle and draw rest from discard pile",
         %{deck: deck, discard_pile: discard_pile} do
      num = 12

      {drawn_card, remaining_deck, remaining_discard_pile} =
        Cards.draw_with_reshuffle(deck, discard_pile, num)

      test_reshuffled_card(
        deck,
        discard_pile,
        drawn_card,
        remaining_deck,
        remaining_discard_pile,
        num
      )
    end

    test "draw_with_reshuffle/4 draw all cards from deck and from discard pile", %{
      deck: deck,
      discard_pile: discard_pile
    } do
      num = 15

      {drawn_card, remaining_deck, remaining_discard_pile} =
        Cards.draw_with_reshuffle(deck, discard_pile, num)

      test_reshuffled_card(
        deck,
        discard_pile,
        drawn_card,
        remaining_deck,
        remaining_discard_pile,
        num
      )
    end
  end

  describe "draw into hand" do
    setup [:build_deck_10]

    test "draw a card", %{deck: deck} do
      {hand, remaining_deck} = Cards.draw_into_hand(deck, [])
      assert length(hand) == 1
      assert length(remaining_deck) == 9
      assert hd(deck) == hd(hand)
    end

    test "draw multiple cards", %{deck: deck} do
      {hand, remaining_deck} = Cards.draw_into_hand(deck, [], 5)
      assert length(hand) == 5
      assert length(remaining_deck) == 5
    end

    test "draw a card from empty deck", %{deck: deck} do
      assert {:error, _} = Cards.draw_into_hand([], [])
    end
  end

  describe "shuffle cards" do
    setup [:build_deck_10]

    test "shuffle changes order", %{deck: deck} do
      assert deck != Cards.shuffle(deck)
    end
  end

  describe "move cards" do
    setup [:build_deck_10, :build_discard_pile_5]

    test "card moves successfully", %{deck: deck, discard_pile: discard_pile} do
      card = 1
      {changed_deck, changed_discard_pile} = Cards.move_card(card, deck, discard_pile)
      assert length(changed_deck) == 9
      assert length(changed_discard_pile) == 6
      assert card in changed_discard_pile
      refute card in changed_deck
    end

    test "card not in pile", %{deck: deck, discard_pile: discard_pile} do
      card = "not in deck"
      {unchanged_deck, unchanged_discard_pile} = Cards.move_card(card, deck, discard_pile)
      assert deck == unchanged_deck
      assert discard_pile == unchanged_discard_pile
    end
  end

  describe "correct cards" do
    setup [:build_deck_10]

    test "card moves successfully" do
    end

    test "card not in pile" do
    end
  end
end
