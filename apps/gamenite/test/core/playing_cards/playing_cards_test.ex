defmodule Gamenite.PlayingCardsTest do
  use ExUnit.Case

  alias Gamenite.PlayingCards
  alias Gamenite.PlayingCards.Card

  @valid_attrs %{face: "some face"}
  @update_attrs %{face: "some updated face"}
  @invalid_attrs %{face: nil}

  def card_fixture(attrs \\ %{}) do
    {:ok, card} =
      attrs
      |> Enum.into(@valid_attrs)
      |> Card.new()

    card
  end

  defp build_deck_10(context) do
    {:ok, Map.put(context, :deck, build_card_list(10))}
  end

  defp build_card_list(length) do
    Enum.map(1..length, &card_fixture(%{face: Integer.to_string(&1)}))
  end

  defp build_discard_pile_5(context) do
    {:ok, Map.put(context, :discard_pile, build_card_list(5))}
  end

  defp build_face_up_card(context) do
    {:ok, Map.put(context, :face_up, card_fixture(%{face_up?: true}))}
  end

  defp build_face_down_card(context) do
    {:ok, Map.put(context, :face_down, card_fixture(%{face_up?: false}))}
  end

  describe "flipping_cards" do
    setup [:build_face_down_card, :build_face_up_card]

    test "flip_card/1 when face up flips card to face down", %{face_up: card} do
      flipped_card = Cards.flip(card)
      assert flipped_card.face_up? == false
    end

    test "flip_card/1 when face down flips card to face up", %{face_down: card} do
      flipped_card = Cards.flip(card)
      assert flipped_card.face_up? == true
    end

    test "flip_face_up/1 when face up, flip to face up", %{face_up: card} do
      flipped_card = Cards.flip_face_up(card)
      assert flipped_card.face_up? == true
    end

    test "flip_face_up/1 when face down, flip to face up", %{face_down: card} do
      flipped_card = Cards.flip_face_up(card)
      assert flipped_card.face_up? == true
    end

    test "flip_face_up/1 when face up, flip to face down", %{face_up: card} do
      flipped_card = Cards.flip_face_down(card)
      assert flipped_card.face_up? == false
    end

    test "flip_face_up/1 when face down, flip to face down", %{face_down: card} do
      flipped_card = Cards.flip_face_down(card)
      assert flipped_card.face_up? == false
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
      assert hd(deck).face == hd(hand).face
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
      card = card_fixture(%{face: "1"})
      {changed_deck, changed_discard_pile} = Cards.move_card(card, deck, discard_pile)
      assert length(changed_deck) == 9
      assert length(changed_discard_pile) == 6
      assert card in changed_discard_pile
      refute card in changed_deck
    end

    test "card not in pile", %{deck: deck, discard_pile: discard_pile} do
      card = card_fixture(%{face: "not in deck"})
      {unchanged_deck, unchanged_discard_pile} = Cards.move_card(card, deck, discard_pile)
      assert deck == unchanged_deck
      assert discard_pile == unchanged_discard_pile
    end
  end
end
