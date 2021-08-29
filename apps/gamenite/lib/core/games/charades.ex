defmodule Gamenite.Core.Charades

  @doc """
  Moves to next player's and team's turn.

  Returns %__MODULE__{}.
  """
  def end_turn(game) do
    game
    |> move_cards_after_review
    |> TeamGame.end_turn
  end

  def skip_card(%__MODULE__{ current_turn: current_turn, skip_limit: skip_limit } = _game, _card)
  when current_turn.num_cards_skipped >= skip_limit
  do
    {:error, "You have reached skip limit of #{current_turn.skip_limit}"}
  end
  def skip_card(%__MODULE__{ deck: deck} = _game, _card)
  when length(deck) == 0
  do
    {:error, "Cannot skip card. No cards left in deck."}
  end
  def skip_card(salad_blow) do
    game
    |> inc_skipped_card
    |> draw_card
  end

  defp inc_skipped_card(game) do
    game
    |> update_in([:team_game][:current_turn][:num_cards_skipped], &(&1 + 1))
  end

  def card_is_correct(charades, card) do
    correct_card = Cards.correct_card(card)

    charades
    |> update_card_in_hand(correct_card)
    |> maybe_review_cards
  end

  defp update_card_in_hand(%__MODULE__{ team_game: team_game } = charades, card) do
    game
    |> put_in([:team_game][:current_player][:hand][Access.filter(&match?(%{id: card.id}, &1))], card)
  end

  defp maybe_review_cards(%__MODULE__{ current_team } = charades)
  when length(current_team.deck) == 0 do
    charades
    |> put_in([:team_game][:current_turn][:needs_review], true)
  end
  defp maybe_review_cards(game), do: game

  defp move_cards_after_review(%__MODULE__{ team_game: team_game} = charades) do
    correct_cards = Enum.filter(team_game.current_team.current_player.hand, &is_card_correct?(&1))
    incorrect_cards = Enum.reject(team_game.current_team.current_player.hand, &is_card_correct?(&1))

    charades
    |> add_correct_cards_to_turn(correct_cards)
    |> move_incorrect_back_to_deck(incorrect_cards)
    |> clear_current_player_hand
  end

  defp is_card_correct?(card) when card.is_correct, do: true
  defp is_card_correct?(_card), do: false

  defp add_correct_cards_to_turn(charades, cards_correct) do
    charades
    |> put_in([:team_game][:current_turn][:cards_correct], cards_correct)
  end

  defp move_incorrect_back_to_deck(%__MODULE__{ team_game: team_game } = charades, incorrect_cards) do
    new_deck = team_game.deck ++ incorrect_cards
    updated_game = TeamGame.update_deck(team_game, new_deck)

    charades
    |> update_game(updated_game)
  end

  defp update_game(charades, updated_game) do
    charades
    |> Map.replace!(:team_game, updated_game)
  end

end
