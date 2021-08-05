defmodule GameSys.DeckServer do
  use GenServer

  def handle_call({:draw_card, num_cards}, _from, current_game) do
    {:reply, Gamenite.Cards.draw(current_game.deck, num_cards)}
  end

  def handle_call(:shuffle_deck, _from, current_game) do

  end

  def handle_call({:skip_card, })
end
