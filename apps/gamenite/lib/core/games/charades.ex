defmodule Gamenite.Games.Charades do
  alias Gamenite.Games.Charades.{Turn, Game}
  alias Gamenite.Lists
  alias Gamenite.TeamGame
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
    new_turn =
      Turn.new(%{
        player_name: current_team.current_player.name,
        time_remaining_in_sec: turn_length
      })

    %{game | current_turn: new_turn}
  end

  def draw_card(%{deck: deck} = game) do
    case Cards.draw(deck) do
      {:error, reason} ->
        {:error, reason}

      {drawn_cards, remaining_deck} ->
        game
        |> put_in([:current_turn, :card], hd(drawn_cards))
        |> Map.put(:deck, remaining_deck)
    end
  end

  def add_card_to_completed(%{current_turn: current_turn} = _game, _card_outcome)
      when is_nil(current_turn.card) do
    {:error, "Card is nil."}
  end

  def add_card_to_completed(
        %{deck: deck, current_turn: current_turn, skip_limit: skip_limit} = game,
        :skipped = _card_outcome
      ) do
    skipped_card_count = count_cards_with_outcome(current_turn.completed_cards, :skipped)

    cond do
      skipped_card_count >= skip_limit ->
        {:error, "You have reached skip limit of #{skip_limit}."}

      deck == [] ->
        {:error, "Cannot skip card. No cards left in deck."}

      true ->
        do_add_card_to_completed(game, :skipped)
        |> draw_card
    end
  end

  def add_card_to_completed(%{deck: deck, current_turn: current_turn} = game, card_outcome) do
    skipped_card_count = count_cards_with_outcome(current_turn.completed_cards, :skipped)

    cond do
      deck == [] and skipped_card_count > 0 ->
        game
        |> do_add_card_to_completed(card_outcome)
        |> move_skipped_to_card

      deck == [] and skipped_card_count == 0 ->
        {:review, do_add_card_to_completed(game, card_outcome)}

      true ->
        do_add_card_to_completed(game, card_outcome)
        |> draw_card
    end
  end

  defp do_add_card_to_completed(%{current_turn: current_turn} = game, card_outcome) do
    game
    |> update_in([:current_turn, :completed_cards], fn cards ->
      [{card_outcome, current_turn.card} | cards]
    end)
    |> put_in([:current_turn, :card], nil)
  end

  def count_cards_with_outcome(completed_cards, target_outcome) do
    Enum.count(completed_cards, fn {outcome, _card} -> outcome == target_outcome end)
  end

  defp move_skipped_to_card(%{current_turn: current_turn} = game) do
    first_skipped =
      {:skipped, card} =
      Enum.find(current_turn.completed_cards, fn {outcome, _card} -> outcome == :skipped end)

    game
    |> put_in([:current_turn, :card], card)
    |> update_in([:current_turn, :completed_cards], &List.delete(&1, first_skipped))
  end

  def change_card_outcome(%{current_turn: current_turn} = game, index, new_outcome) do
    completed_cards =
      List.update_at(current_turn.completed_cards, index, fn {_outcome, card} ->
        {new_outcome, card}
      end)

    game
    |> put_in([:current_turn, :completed_cards], completed_cards)
  end

  def move_incorrect_back_to_deck(%{current_turn: current_turn} = game)
      when not is_nil(current_turn.card) do
    game
    |> do_add_card_to_completed(:incorrect)
    |> do_move_incorrect_back_to_deck
  end

  def move_incorrect_back_to_deck(game), do: do_move_incorrect_back_to_deck(game)

  defp do_move_incorrect_back_to_deck(%{deck: deck, current_turn: current_turn} = game) do
    incorrect_cards =
      current_turn.completed_cards
      |> Enum.reduce(
        [],
        fn
          {:correct, _card}, acc ->
            acc

          {_outcome, card}, acc ->
            [card | acc]
        end
      )

    new_deck = deck ++ incorrect_cards

    game
    |> update_deck(new_deck)
  end

  defp check_words_unique_in_list(word_list) do
    if Enum.uniq(word_list) != word_list do
      {:error, "Duplicate cards sumbitted. Must all be unique."}
    else
      :ok
    end
  end

  defp check_words_unique_in_deck([] = _deck, _word_list), do: :ok

  defp check_words_unique_in_deck(deck, word_list) do
    errors =
      Enum.reduce(word_list, [], fn word, acc ->
        if word in deck do
          ["#{word} was submitted by another player.\n" | acc]
        else
          acc
        end
      end)

    if Enum.any?(errors) do
      {:error, errors}
    else
      :ok
    end
  end

  def add_cards_to_deck(%{deck: deck} = game, word_list, user_id) do
    with :ok <- check_words_unique_in_list(word_list),
         :ok <- check_words_unique_in_deck(deck, word_list) do
      do_add_cards_to_deck(game, word_list, user_id)
    else
      {:error, errors} ->
        {:error, errors}
    end
  end

  defp do_add_cards_to_deck(%{deck: deck} = game, cards, user_id) do
    game
    |> Map.update(:submitted_users, [user_id], fn users -> [user_id | users] end)
    |> update_deck(cards ++ deck)
  end

  def end_turn(game) do
    game
    |> score_correct_cards
    |> move_incorrect_back_to_deck
    |> do_end_turn
  end

  defp do_end_turn(%{current_turn: current_turn, deck: []} = game)
       when current_turn.time_remaining_in_sec != 0 do
    game
    |> maybe_end_round
  end

  defp do_end_turn(game) do
    game
    |> TeamGame.end_turn()
    |> new_turn
  end

  defp score_correct_cards(%{current_turn: current_turn} = game) do
    turn_score = count_cards_with_outcome(current_turn.completed_cards, :correct)

    game
    |> TeamGame.add_score(turn_score)
  end

  # Salad Bowl Logic
  def inc_round(%{rounds: rounds, current_round: current_round} = game) do
    case Lists.next_list_index(rounds, current_round) do
      0 ->
        Map.replace!(game, :finished?, true)

      index ->
        next_round = Enum.at(rounds, index)

        game
        |> Map.put(:current_round, next_round)
    end
  end

  def maybe_end_round(%{rounds: rounds, deck: []} = game), do: end_round(game)
  def maybe_end_round(game), do: game

  defp end_round(%{starting_deck: starting_deck} = game) do
    game
    |> inc_round
    |> update_deck(starting_deck)
  end

  def update_deck(game, new_deck) do
    %{game | deck: new_deck}
  end
end
