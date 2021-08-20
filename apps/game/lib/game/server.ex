defmodule Game.Server do
  use GenServer

  alias Gamenite.Cards
  alias Gameplay.TeamGame

  def init(game) do
    {:ok, game}
  end

  def handle_cast({:add_player, player}, game) do
    { :noreply, TeamGame.add_player(game, player)}
  end

  def handle_cast({:draw_card, num_cards}, game) do
    { :noreply, TeamGame.draw_card(game, num_cards)}
  end

  def handle_call(:state, _from, game) do
    { :reply, game, game }
  end

  def handle_call(:shuffle, _from, game = %{ deck: deck }) do
    shuffled_deck = Cards.shuffle(deck)
    {:reply, shuffled_deck, %{ game | deck: shuffled_deck} }
  end

  def handle_call(:next_player, _from, game) do
    updated_game = TeamGame.next_player(game)
    { :reply, Map.get(updated_game, :current_team), updated_game }
  end

  def handle_call({ :correct_card, card }, _from, game) do
    { :reply, :ok, TeamGame.correct_card(game, card)}
  end

  def handle_call({ :skip_card, card }, _from, game) do
    { :reply, TeamGame.skip_card(game, card) }
  end

end
