defmodule Gamenite.Core.Cards.CardTest do
  use ExUnit.Case

  alias Gamenite.Core.Cards.Card

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

  def build_card_list(length) do
    Enum.map(1..length, &card_fixture(%{face: Integer.to_string(&1)}))
  end

  def build_face_up_card(context) do
    {:ok, Map.put(context, :face_up, card_fixture(%{face_up?: true}))}
  end

  def build_face_down_card(context) do
    {:ok, Map.put(context, :face_down, card_fixture(%{face_up?: false}))}
  end

  describe "flipping_cards" do
    setup [:build_face_down_card, :build_face_up_card]

    test "flip_card/1 when face up flips card to face down", %{face_up: card} do
      flipped_card = Card.flip(card)
      assert flipped_card.face_up? == false
    end

    test "flip_card/1 when face down flips card to face up", %{face_down: card} do
      flipped_card = Card.flip(card)
      assert flipped_card.face_up? == true
    end

    test "flip_face_up/1 when face up, flip to face up", %{face_up: card} do
      flipped_card = Card.flip_face_up(card)
      assert flipped_card.face_up? == true
    end

    test "flip_face_up/1 when face down, flip to face up", %{face_down: card} do
      flipped_card = Card.flip_face_up(card)
      assert flipped_card.face_up? == true
    end

    test "flip_face_up/1 when face up, flip to face down", %{face_up: card} do
      flipped_card = Card.flip_face_down(card)
      assert flipped_card.face_up? == false
    end

    test "flip_face_up/1 when face down, flip to face down", %{face_down: card} do
      flipped_card = Card.flip_face_down(card)
      assert flipped_card.face_up? == false
    end
  end



  test "draw/3 draw negative Card" do
    deck = build_card_list(10)
    assert Card.draw(deck, -5) == {:error, "Number of cards drawn must be positive integer."}
  end

  test "draw/3 draw zero Card" do
    deck = build_card_list(10)
    assert Card.draw(deck, 0) == {:error, "Number of cards drawn must be positive integer."}
  end

  test "draw/3 draw decimal Card" do
    deck = build_card_list(10)
    assert Card.draw(deck, 5.6) == {:error, "Number of cards drawn must be positive integer."}
  end

  test "draw/3 draw too many Card" do
    deck = build_card_list(10)
    assert Card.draw(deck, 11) == { :error, "Not enough cards in deck."}
  end

  def test_drawn_Card(deck, drawn_Card, remaining_deck, num) do
    assert Kernel.length(drawn_Card) == num
    assert Kernel.length(remaining_deck) == Kernel.length(deck) - num
    assert drawn_Card == Enum.take(deck, num)
  end

  test "draw/3 draw 1 card" do
    deck = build_card_list(10)
    num = 1
    { drawn_Card, remaining_deck } = Card.draw(deck, num, false)
    test_drawn_Card(deck, drawn_Card, remaining_deck, num)
  end

  test "draw/3 draw 3 Card" do
    deck = build_card_list(10)
    num = 3
    { drawn_Card, remaining_deck } = Card.draw(deck, num, false)
    test_drawn_Card(deck, drawn_Card, remaining_deck, num)
  end

  test "draw/3 draw all Card in deck" do
    num = 10
    deck = build_card_list(num)
    { drawn_Card, remaining_deck } = Card.draw(deck, num, false)
    test_drawn_Card(deck, drawn_Card, remaining_deck, num)
  end

  def test_reshuffled_Card(deck, discard_pile, drawn_Card, remaining_deck, num) do
    assert Kernel.length(drawn_Card) == num
    assert Kernel.length(remaining_deck) == Kernel.length(deck) + Kernel.length(discard_pile) - num
  end

  test "draw_with_reshuffle/4 draw more than in deck and discard pile combined" do
    deck = build_card_list(5)
    discard_pile = build_card_list(5)
    num = 11
    assert Card.draw_with_reshuffle(deck, discard_pile, num) == { :error, "Number of cards drawn must be less than left in deck and discard pile combined."}
  end

  test "draw_with_reshuffle/4 deck has zero Card, reshuffle and draw from discard pile" do
    deck = []
    discard_pile = build_card_list(10)
    num = 4
    { drawn_Card, remaining_deck } = Card.draw_with_reshuffle(deck, discard_pile, num, false)
    test_reshuffled_Card(deck, discard_pile, drawn_Card, remaining_deck, num)
  end

  test "draw_with_reshuffle/4 deck has some Card, reshuffle and draw rest from discard pile" do
    deck = build_card_list(4)
    discard_pile = build_card_list(10)
    num = 7
    { drawn_Card, remaining_deck } = Card.draw_with_reshuffle(deck, discard_pile, num, false)
    test_reshuffled_Card(deck, discard_pile, drawn_Card, remaining_deck, num)
  end

  test "draw_with_reshuffle/4 draw all Card from deck and from discard pile" do
    deck = build_card_list(5)
    discard_pile = build_card_list(5)
    num = 10
    { drawn_Card, remaining_deck } = Card.draw_with_reshuffle(deck, discard_pile, num, false)
    test_reshuffled_Card(deck, discard_pile, drawn_Card, remaining_deck, num)
  end
end
