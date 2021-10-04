defmodule Gamenite.Games.Charades do
  alias Gamenite.TeamGame
  alias Gamenite.Cards
  alias Gamenite.Lists
  alias Gamenite.Games.CharadesTurn

  @doc """
  Moves to next player's and team's turn.

  Returns %__MODULE__{}.
  """
  def end_turn(game) do
    game
    |> move_cards_after_review
    |> TeamGame.new_turn(&CharadesTurn.new/1)
  end

  def draw_card (%{ current_player: current_player, deck: deck } = game) do
    case Cards.draw(deck) do
      {:error, reason} ->
        {:error, reason}
      { drawn_cards, remaining_deck } ->
        new_player = %{current_player | card: hd(drawn_cards)}

        game
        |> TeamGame.replace_current_player(new_player)
        |> Map.put(:deck, remaining_deck)
    end
  end

  def skip_card(%{ current_turn: current_turn, skip_limit: skip_limit } = _game, _card)
  when length(current_turn.skipped_cards) >= skip_limit
  do
    {:error, "You have reached skip limit of #{current_turn.skip_limit}"}
  end
  def skip_card(%{ deck: deck} = _game, _card)
  when length(deck) == 0
  do
    {:error, "Cannot skip card. No cards left in deck."}
  end
  def skip_card(game) do
    game
    |> update_turn_cards(:skipped_cards)
    |> draw_or_review_cards
  end

  def card_is_correct(game) do
    game
    |> update_turn_cards(:correct_cards)
    |> draw_or_review_cards
  end

  defp update_turn_cards(%{current_player: current_player} = game, card_key) do
    game
    |> update_in([:current_turn, card_key], fn cards -> [current_player.card | cards] end)
    |> put_in([:current_player, :card], nil)
  end

  defp draw_or_review_cards(%{ deck: deck } = game)
  when length(deck) == 0 do
    game
    |> put_in([:current_turn, :needs_review], true)
  end
  defp draw_or_review_cards(game), do: draw_card(game)

  defp move_cards_after_review(game) do
    game
    |> update_turn_cards(:skipped_cards)
    |> move_incorrect_back_to_deck()
  end

  defp move_incorrect_back_to_deck(%{ deck: deck, current_turn: current_turn } = game) do
    new_deck = deck ++ current_turn.skipped_cards

    game
    |> update_deck(new_deck)
  end

  def add_cards_to_deck(%{ deck: deck } = game, cards) do
    errors = Enum.reduce(deck, fn card, acc ->
      case Cards.card_in_deck?(cards, card) do
      true  -> [ "#{card.face} already in deck." | acc ]
      _ -> acc
      end
    end )

    do_add_cards_to_deck(game, cards, errors)
  end
  defp do_add_cards_to_deck(%{ deck: deck } = game, cards, []) do
    game
    |> update_deck(cards ++ deck)
  end
  defp do_add_cards_to_deck(_game, _cards, errors), do: {:error, errors}


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
    |> move_cards_after_review
    |> update_deck(starting_deck)
  end

  defp update_deck(game, new_deck) do
    %{game | deck: new_deck}
  end
end
