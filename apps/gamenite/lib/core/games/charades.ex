defmodule Gamenite.Games.Charades do
  alias Gamenite.Games.Charades.{Turn, Game}
  import Ecto.Changeset

  def create_charades_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> apply_action(:update)
  end

  def create_salad_bowl_game(attrs \\ %{}) do
    %Game{}
    |> Game.salad_bowl_changeset(attrs)
    |> apply_action(:update)
  end

  def create_turn(attrs \\ %{}) do
    Turn.new(attrs)
  end

  def new_turn(%{current_team: current_team} = _game) do
    Turn.new(%{player_name: current_team.current_player.name})
  end

  def skip_card(%{ current_turn: current_turn, skip_limit: skip_limit } = _game)
  when length(current_turn.skipped_cards) >= skip_limit
  do
    {:error, "You have reached skip limit of #{skip_limit}."}
  end
  def skip_card(%{ deck: deck} = _game)
  when length(deck) == 0
  do
    {:error, "Cannot skip card. No cards left in deck."}
  end
  def skip_card(%{current_turn: current_turn} = _game)
  when is_nil(current_turn.card) do
    {:error, "Card is nil."}
  end
  def skip_card(game) do
    game
    |> update_turn_cards(:skipped_cards)
  end

  def correct_card(%{current_turn: current_turn} = _game)
  when is_nil(current_turn.card) do
    {:error, "Card in nil."}
  end
  def correct_card(game) do
    game
    |> update_turn_cards(:correct_cards)
  end

  def move_card_during_review(game, card) do
    ## move from correct to incorrect
  end

  defp update_turn_cards(%{current_turn: current_turn} = game, _card_key)
  when is_nil(current_turn.card) do
    game
  end
  defp update_turn_cards(%{current_turn: current_turn} = game, card_key) do
    game
    |> update_in([:current_turn, card_key], fn cards -> [current_turn.card | cards] end)
    |> put_in([:current_turn, :card], nil)
  end

  def move_cards_after_review(game) do
    game
    |> update_turn_cards(:skipped_cards)
    |> move_incorrect_back_to_deck
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

  def update_deck(game, new_deck) do
    %{game | deck: new_deck}
  end
end
