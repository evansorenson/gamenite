defmodule Gamenite.Games.Charades do
  alias Gamenite.Games.Charades.{Turn, Game}
  alias Gamenite.Lists
  alias Gamenite.Cards.Card
  alias Gamenite.Cards
  import Ecto.Changeset

  def change_charades(%Game{} = game, attrs \\ %{}) do
    game
    |> Game.changeset(attrs)
  end

  def change_salad_bowl(%Game{} = game, attrs \\ %{}) do
    game
    |> Game.salad_bowl_changeset(attrs)
  end
  def create_charades(attrs) do
    %Game{}
    |> Game.changeset(attrs)
    |> apply_action(:update)
  end

  def create_salad_bowl(attrs) do
    %Game{}
    |> Game.salad_bowl_changeset(attrs)
    |> apply_action(:update)
  end

  def create_turn(attrs \\ %{}) do
    Turn.new(attrs)
  end

  def new_turn(%{current_team: current_team, turn_length: turn_length} = game) do
    new_turn = Turn.new(%{player_name: current_team.current_player.name, time_remaining_in_sec: turn_length})
    %{game | current_turn: new_turn}
  end

  def card_completed(%{deck: deck, current_turn: current_turn, skip_limit: skip_limit} = game, card_outcome) do
    skipped_card_count = count_cards_with_outcome(current_turn.completed_cards, :skipped)
    cond do
      card_outcome == :skipped and skipped_card_count >= skip_limit ->
        {:error, "You have reached skip limit of #{skip_limit}."}
      card_outcome == :skipped and deck == [] ->
        {:error, "Cannot skip card. No cards left in deck."}
      is_nil(current_turn.card) ->
        {:error, "Current card is nil."}
      deck == [] and skipped_card_count == 0 ->
        {:review, do_card_completed(game, card_outcome)}
      deck == [] and skipped_card_count > 0 ->
        game
        |> do_card_completed(card_outcome)
        |> move_skipped_to_card
      true ->
        do_card_completed(game, card_outcome)
    end
  end

  defp do_card_completed(%{current_turn: current_turn} = game, card_outcome) do
    game
    |> update_in([:current_turn, :completed_cards], fn cards -> [{card_outcome, current_turn.card} | cards] end)
    |> put_in([:current_turn, :card], nil)
  end

  def count_cards_with_outcome(completed_cards, target_outcome) do
    Enum.count(completed_cards, fn {outcome, _card} -> outcome == target_outcome end)
  end

  defp move_skipped_to_card(%{current_turn: current_turn} = game) do
    first_skipped = Enum.find(current_turn.completed_cards, fn {outcome, _card} -> outcome == :skipped end)

    game
    |> put_in([:current_turn, :card], first_skipped)
    |> update_in([:current_turn, :completed_cards], &List.delete(&1, first_skipped))
  end

  def move_card_during_review(%{current_turn: current_turn} = game, index, new_outcome) do
    completed_cards = List.update_at(current_turn.completed_cards, index, fn {_outcome, card} -> {new_outcome, card} end)
    game
    |> put_in([:current_turn, :completed_cards], completed_cards)
  end

  def move_cards_after_review(game) do
    game
    |> move_incorrect_back_to_deck
  end

  defp move_incorrect_back_to_deck(%{ deck: deck, current_turn: current_turn } = game) do
    incorrect_cards = current_turn.completed_cards
    |> Enum.reduce(
      [],
      fn {:correct, _card}, acc ->
          acc
        {_outcome, card}, acc ->
          [card | acc]
      end)
    new_deck = deck ++ incorrect_cards

    game
    |> update_deck(new_deck)
  end

  def list_of_words_to_cards(word_list) do
    Enum.map(word_list, &Card.new(%{face: &1}))
  end

  def add_cards_to_deck(%{ deck: [] } = game, word_list, user_id) do
    cards = list_of_words_to_cards(word_list)
    do_add_cards_to_deck(game, cards, user_id, [])
  end
  def add_cards_to_deck(%{ deck: deck } = game, word_list, user_id) do
    cards = list_of_words_to_cards(word_list)
    errors = Enum.reduce(deck, fn card, acc ->
      case Cards.card_in_deck?(cards, card) do
      true  -> [ "#{card.face} already in deck." | acc ]
      _ -> acc
      end
    end )

    do_add_cards_to_deck(game, cards, user_id, errors)
  end
  defp do_add_cards_to_deck(%{ deck: deck } = game, cards, user_id, []) do
    game
    |> Map.update(:submitted_users, [user_id], fn users -> [user_id | users] end)
    |> update_deck(cards ++ deck)
  end
  defp do_add_cards_to_deck(_game, _cards,_user_id, errors), do: {:error, errors}




  # Salad Bowl Logic
  def inc_round(%{ rounds: rounds, current_round: current_round} = game) do
    _inc_round(game, Lists.next_list_element(rounds, current_round))
  end
  defp _inc_round(game, { 0, _ }) do
    Map.replace!(game, :finished?, true)
  end
  defp _inc_round(game, { _, next_round }) do
    game
    |> Map.put(:current_round, next_round)
  end

  def end_round(%{ starting_deck: starting_deck } = game) do
    game
    |> inc_round
    |> update_deck(starting_deck)
  end

  def update_deck(game, new_deck) do
    %{game | deck: new_deck}
  end
end
