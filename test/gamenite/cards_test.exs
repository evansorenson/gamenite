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

    @valid_attrs %{front: "some front"}
    @update_attrs %{front: "some updated front"}
    @invalid_attrs %{front: nil}

    def card_fixture(attrs \\ %{}) do
      {:ok, card} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Cards.create_card()

      card
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
      assert card.front == "some front"
    end

    test "create_card/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Cards.create_card(@invalid_attrs)
    end

    test "update_card/2 with valid data updates the card" do
      card = card_fixture()
      assert {:ok, %Card{} = card} = Cards.update_card(card, @update_attrs)
      assert card.front == "some updated front"
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
  end

  describe "drawing" do
    test "draw/1 draw -5 cards" do
      deck = deck_fixture()
      assert {:error, "Must draw a positive integer of cards."} == Cards.draw(deck, -5)
    end
    test "draw/1 draw 0 cards" do
      deck = deck_fixture()
      assert {:error, "Must draw a positive integer of cards."} == Cards.draw(deck, 0)
    end
    test "draw/1 draw 1 card" do
      deck = deck_fixture()
      {cards, remaining_deck} = Cards.draw(deck)
    end
    test "draw/1 draw 5 cards" do
      deck = deck_fixture()
      {cards, remaining_deck} = Cards.draw(deck, 5)
    end
    test "draw/1 draw 10 cards" do
      deck = deck_fixture()
      {cards, remaining_deck} = Cards.draw(deck, 10)
    end
    test "draw more cards than left in deck" do
      deck = deck_fixture()
      Cards.draw(deck)
    end

    test "draw_into_hand/2 "
  end


end
