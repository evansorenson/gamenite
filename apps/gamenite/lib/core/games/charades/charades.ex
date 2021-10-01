defmodule Gamenite.Games.Charades do
  alias Gamenite.TeamGame
  alias Gamenite.Cards
  alias Gamenite.Lists

  @doc """
  Moves to next player's and team's turn.

  Returns %__MODULE__{}.
  """
  def end_turn(game) do
    game
    |> move_cards_after_review
    |> TeamGame.new_turn
  end

  def draw_card(%{ current_team: %{current_player: current_player}, options: %{deck: deck}} = game) do
    case Cards.draw(deck) do
      {:error, reason} ->
        {:error, reason}
      { drawn_cards, remaining_deck } ->
        game
        |> replace_current_player(%{current_player | hand: [ drawn_cards | hand ]})
        |> put_in([:options, :deck], remaining_deck)
    end
  end

  def skip_card(%{ current_turn: current_turn, options: options } = _game, _card)
  when current_turn.num_cards_skipped >= options.skip_limit
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
    |> inc_skipped_card
    |> draw_card()
  end

  defp inc_skipped_card(game) do
    game
    |> update_in([:team_game][:current_turn][:num_cards_skipped], &(&1 + 1))
  end

  def card_is_correct(game, card) do
    correct_card = Cards.correct_card(card)

    game
    |> update_card_in_hand(correct_card)
    |> maybe_review_cards
  end

  defp update_card_in_hand(%{ current_team: current_team } = game, card) do
    game
    |> put_in(
      [:current_team][:current_player][:hand][Access.at(Enum.find_index(current_team.current_player.hand, &(&1.id == card.id)))], card)
  end

  defp maybe_review_cards(%{ deck: deck } = game)
  when length(deck) == 0 do
    game
    |> put_in([:current_turn][:needs_review], true)
  end
  defp maybe_review_cards(game), do: game

  defp move_cards_after_review(%{ current_team: current_team} = game) do
    correct_cards = Enum.filter(current_team.current_player.hand, &is_card_correct?(&1))
    incorrect_cards = Enum.reject(current_team.current_player.hand, &is_card_correct?(&1))

    game
    |> add_correct_cards_to_turn(correct_cards)
    |> move_incorrect_back_to_deck(incorrect_cards)
    |> TeamGame.clear_current_player_hand
  end

  defp is_card_correct?(card) when card.is_correct, do: true
  defp is_card_correct?(_card), do: false

  defp add_correct_cards_to_turn(game, cards_correct) do
    game
    |> put_in([:current_turn][:cards_correct], cards_correct)
  end

  defp move_incorrect_back_to_deck(%{ deck: deck } = game, incorrect_cards) do
    new_deck = deck ++ incorrect_cards

    game
    |> TeamGame.update_deck(new_deck)
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
    |> TeamGame.update_deck([ cards | deck ])
  end
  defp do_add_cards_to_deck(_game, _cards, errors), do: {:error, errors}


  # Salad Bowl Logic
  def inc_round(%{ rounds: rounds, current_round: current_round} = game) do
    _inc_round(game, Lists.next_list_element(rounds, current_round))
  end
  defp _inc_round(game, { 0, _ }) do
    Map.replace!(game, :is_finished, true)
  end
  defp _inc_round(game, { _, next_round }) do
    game
    |> put_in([:options][:current_round], next_round)
  end

  def end_round(%{ starting_deck: starting_deck } = game) do
    game
    |> inc_round
    |> move_cards_after_review
    |> TeamGame.update_deck(starting_deck)
  end
end
