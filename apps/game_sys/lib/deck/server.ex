defmodule Deck.Server do
  use GenServer

  alias Gamenite.Cards

  def handle_cast({:draw, num_cards}, _from, {deck, discard_pile}) do
    {:reply, Cards.draw(deck, num_cards)}
  end

  def handle_cast(:shuffle, _from, {deck, discard_pile}) do
    {:noreply, Cards.shuffle(deck)}
  end

  def handle_cast({:draw_with_reshuffle, num}, _from, {deck, discard_pile}) do
    {:noreply, Cards.draw_with_reshuffle(deck, discard_pile, num)}
  end

  def handle_cast({:skip_card, card, hand}, _from, {deck, discard_pile, hands}) do
    {:noreply, Cards.discard(card, hand, discard_pile)}
  end

end
