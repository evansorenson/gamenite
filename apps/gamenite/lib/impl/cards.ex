defmodule Gamenite.Cards do
  @doc """
  Returns { drawn_cards, remaining_deck}.
  """
  def draw(deck, num \\ 1)

  def draw(_, num) when num < 1 or not is_integer(num),
    do: {:error, "Number of cards drawn must be positive integer."}

  def draw(deck, num) when num > Kernel.length(deck), do: {:error, "Not enough cards in deck."}

  def draw(deck, num) do
    Enum.split(deck, num)
  end

  @doc """
  Similar to draw but includes discard pile for reshuffles. If num > length of deck remaining, then will
  shuffle discard pile and draw remaining cards from there.

  Returns { drawn_cards, remaining_deck, discard_pile }
  """
  def draw_with_reshuffle(deck, discard_pile, num)

  def draw_with_reshuffle(deck, discard_pile, num)
      when num > Kernel.length(discard_pile) + Kernel.length(deck) do
    {:error, "Number of cards drawn must be less than left in deck and discard pile combined."}
  end

  def draw_with_reshuffle(deck, discard_pile, num) when num <= Kernel.length(deck) do
    {drawn_cards, remaining_deck} = draw(deck, num)
    {drawn_cards, remaining_deck, discard_pile}
  end

  def draw_with_reshuffle(deck, discard_pile, num) when Kernel.length(deck) == 0 do
    replenished_deck = Enum.shuffle(discard_pile)
    {drawn_after_reshuffle, remaining_deck} = draw(replenished_deck, num)
    {drawn_after_reshuffle, remaining_deck, []}
  end

  def draw_with_reshuffle(deck, discard_pile, num) do
    cards_left = Kernel.length(deck)
    {initial_drawn_cards, _} = draw(deck, cards_left)

    replenished_deck = Enum.shuffle(discard_pile)
    {drawn_after_reshuffle, remaining_deck} = draw(replenished_deck, num - cards_left)
    {initial_drawn_cards ++ drawn_after_reshuffle, remaining_deck, []}
  end

  @doc """
  Draws cards and adds them to hand.

  Returns {[hand], [remaining_deck], [discard_pile]}
  """

  def draw_into_hand(deck, hand, num \\ 1) do
    case draw(deck, num) do
      {:error, reason} ->
        {:error, reason}

      {drawn_cards, remaining_deck} ->
        {drawn_cards ++ hand, remaining_deck}
    end
  end

  def draw_into_hand_with_reshuffle(deck, hand, discard_pile, num \\ 1) do
    case draw_with_reshuffle(deck, discard_pile, num) do
      {:error, reason} ->
        {:error, reason}

      {drawn_cards, remaining_deck, new_discard_pile} ->
        {drawn_cards ++ hand, remaining_deck, new_discard_pile}
    end
  end

  @doc """
  Shuffles deck.

  Returns deck in random order.
  """
  def shuffle(deck), do: Enum.shuffle(deck)

  @doc """
  Moves card from one pile to another.

  Returns { [origin_pile], [destination_pile] }
  """
  def move_card(card, origin_pile, destination_pile) do
    deleted_from_origin_pile = List.delete(origin_pile, card)

    cond do
      deleted_from_origin_pile == origin_pile -> {origin_pile, destination_pile}
      true -> {List.delete(origin_pile, card), [card | destination_pile]}
    end
  end

  def card_in_deck?(deck, card) do
    Enum.any?(deck, fn x -> x.face == card.face end)
  end
end
