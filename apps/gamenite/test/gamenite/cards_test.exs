defmodule Gamenite.CardsTest do
  use Gamenite.DataCase

  alias Gamenite.Cards

  describe "decks" do
    alias Gamenite.Cards.Deck

    @valid_attrs %{title: "some title"}
    @update_attrs %{title: "some updated title"}
    @invalid_attrs %{title: nil}

    def deck_fixture(attrs \\ %{}) do
      {:ok, deck} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Cards.create_deck()

      deck
    end

    test "list_decks/0 returns all decks" do
      deck = deck_fixture()
      assert Cards.list_decks() == [deck]
    end

    test "get_deck!/1 returns the deck with given id" do
      deck = deck_fixture()
      assert Cards.get_deck!(deck.id) == deck
    end

    test "create_deck/1 with valid data creates a deck" do
      assert {:ok, %Deck{} = deck} = Cards.create_deck(@valid_attrs)
      assert deck.title == "some title"
    end

    test "create_deck/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Cards.create_deck(@invalid_attrs)
    end

    test "update_deck/2 with valid data updates the deck" do
      deck = deck_fixture()
      assert {:ok, %Deck{} = deck} = Cards.update_deck(deck, @update_attrs)
      assert deck.title == "some updated title"
    end

    test "update_deck/2 with invalid data returns error changeset" do
      deck = deck_fixture()
      assert {:error, %Ecto.Changeset{}} = Cards.update_deck(deck, @invalid_attrs)
      assert deck == Cards.get_deck!(deck.id)
    end

    test "delete_deck/1 deletes the deck" do
      deck = deck_fixture()
      assert {:ok, %Deck{}} = Cards.delete_deck(deck)
      assert_raise Ecto.NoResultsError, fn -> Cards.get_deck!(deck.id) end
    end

    test "change_deck/1 returns a deck changeset" do
      deck = deck_fixture()
      assert %Ecto.Changeset{} = Cards.change_deck(deck)
    end
  end

  describe "cards" do
    alias Gamenite.Cards.Card

    @valid_attrs %{face: "some face"}
    @update_attrs %{face: "some updated face"}
    @invalid_attrs %{face: nil}

    def card_fixture(attrs \\ %{}) do
      {:ok, card} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Cards.create_card()

      card
    end

    def build_card_list(length) do
      Enum.map(1..length, &card_fixture(%{face: Integer.to_string(&1)}))
    end

    test "list_cards/0 returns all cards" do
      card = card_fixture()
      assert Cards.list_cards() == [card]
    end

    test "get_card!/1 returns the card with given id" do
      card = card_fixture()
      assert Cards.get_card!(card.id) == card
    end

    test "create_card/1 with valid data creates a card" do
      assert {:ok, %Card{} = card} = Cards.create_card(@valid_attrs)
      assert card.face == "some face"
    end

    test "create_card/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Cards.create_card(@invalid_attrs)
    end

    test "update_card/2 with valid data updates the card" do
      card = card_fixture()
      assert {:ok, %Card{} = card} = Cards.update_card(card, @update_attrs)
      assert card.face == "some updated face"
    end

    test "update_card/2 with invalid data returns error changeset" do
      card = card_fixture()
      assert {:error, %Ecto.Changeset{}} = Cards.update_card(card, @invalid_attrs)
      assert card == Cards.get_card!(card.id)
    end

    test "delete_card/1 deletes the card" do
      card = card_fixture()
      assert {:ok, %Card{}} = Cards.delete_card(card)
      assert_raise Ecto.NoResultsError, fn -> Cards.get_card!(card.id) end
    end

    test "change_card/1 returns a card changeset" do
      card = card_fixture()
      assert %Ecto.Changeset{} = Cards.change_card(card)
    end

    test "flip_card/1 when face up flips card to face down" do
      card = card_fixture()
      card = %{card | is_face_up: true}
      flipped_card = Cards.flip_card(card)
      assert flipped_card.is_face_up == false
    end

    test "flip_card/1 when face down flips card to face up" do
      card = card_fixture(%{is_face_up: false})
      flipped_card = Cards.flip_card(card)
      assert flipped_card.is_face_up == true
    end

    test "flip_card/2 when face up, flip to face up" do
      card = card_fixture(%{is_face_up: true})
      flipped_card = Cards.flip_card(card, true)
      assert flipped_card.is_face_up == true
    end

    test "flip_card/2 when face up, flip to face down" do
      card = card_fixture(%{is_face_up: true})
      flipped_card = Cards.flip_card(card, false)
      assert flipped_card.is_face_up == false
    end

    test "flip_card/2 when face down, flip to face down" do
      card = card_fixture(%{is_face_up: false})
      flipped_card = Cards.flip_card(card, false)
      assert flipped_card.is_face_up == false
    end

    test "flip_card/2 when face down, flip to face up" do
      card = card_fixture(%{is_face_up: false})
      flipped_card = Cards.flip_card(card, true)
      assert flipped_card.is_face_up == true
    end

    test "draw/3 draw negative cards" do
      deck = build_card_list(10)
      assert Cards.draw(deck, -5) == {:error, "Number of cards drawn must be positive integer."}
    end

    test "draw/3 draw zero cards" do
      deck = build_card_list(10)
      assert Cards.draw(deck, 0) == {:error, "Number of cards drawn must be positive integer."}
    end

    test "draw/3 draw decimal cards" do
      deck = build_card_list(10)
      assert Cards.draw(deck, 5.6) == {:error, "Number of cards drawn must be positive integer."}
    end

    test "draw/3 draw too many cards" do
      deck = build_card_list(10)
      assert Cards.draw(deck, 11) == { :error, "Not enough cards in deck."}
    end

    def test_drawn_cards(deck, drawn_cards, remaining_deck, num) do
      assert Kernel.length(drawn_cards) == num
      assert Kernel.length(remaining_deck) == Kernel.length(deck) - num
      assert drawn_cards == Enum.take(deck, num)
    end

    test "draw/3 draw 1 card" do
      deck = build_card_list(10)
      num = 1
      { drawn_cards, remaining_deck } = Cards.draw(deck, num, false)
      test_drawn_cards(deck, drawn_cards, remaining_deck, num)
    end

    test "draw/3 draw 3 cards" do
      deck = build_card_list(10)
      num = 3
      { drawn_cards, remaining_deck } = Cards.draw(deck, num, false)
      test_drawn_cards(deck, drawn_cards, remaining_deck, num)
    end

    test "draw/3 draw all cards in deck" do
      num = 10
      deck = build_card_list(num)
      { drawn_cards, remaining_deck } = Cards.draw(deck, num, false)
      test_drawn_cards(deck, drawn_cards, remaining_deck, num)
    end

    def test_reshuffled_cards(deck, discard_pile, drawn_cards, remaining_deck, num) do
      assert Kernel.length(drawn_cards) == num
      assert Kernel.length(remaining_deck) == Kernel.length(deck) + Kernel.length(discard_pile) - num
    end

    test "draw_with_reshuffle/4 draw more than in deck and discard pile combined" do
      deck = build_card_list(5)
      discard_pile = build_card_list(5)
      num = 11
      assert Cards.draw_with_reshuffle(deck, discard_pile, num) == { :error, "Number of cards drawn must be less than left in deck and discard pile combined."}
    end

    test "draw_with_reshuffle/4 deck has zero cards, reshuffle and draw from discard pile" do
      deck = []
      discard_pile = build_card_list(10)
      num = 4
      { drawn_cards, remaining_deck } = Cards.draw_with_reshuffle(deck, discard_pile, num, false)
      test_reshuffled_cards(deck, discard_pile, drawn_cards, remaining_deck, num)
    end

    test "draw_with_reshuffle/4 deck has some cards, reshuffle and draw rest from discard pile" do
      deck = build_card_list(4)
      discard_pile = build_card_list(10)
      num = 7
      { drawn_cards, remaining_deck } = Cards.draw_with_reshuffle(deck, discard_pile, num, false)
      test_reshuffled_cards(deck, discard_pile, drawn_cards, remaining_deck, num)
    end

    test "draw_with_reshuffle/4 draw all cards from deck and from discard pile" do
      deck = build_card_list(5)
      discard_pile = build_card_list(5)
      num = 10
      { drawn_cards, remaining_deck } = Cards.draw_with_reshuffle(deck, discard_pile, num, false)
      test_reshuffled_cards(deck, discard_pile, drawn_cards, remaining_deck, num)
    end
  end
end
