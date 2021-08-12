defmodule Game.Server do
  use GenServer

  alias Gamenite.Cards
  alias Gameplay.Team
  alias Gameplay.Player

  def init(game) do
    {:ok, game}
  end

  def handle_call(:next_player, _from, game = %{teams: teams, current_team: current_team}) do
    { updated_teams, next_team } = Gameplay.next_player(teams, current_team)

    {:reply,
    next_team,
    %{game | teams: updated_teams, current_team: next_team}
    }
  end

  def handle_cast({:add_player, player}, game = %{teams: teams}) do
    { :noreply, %{ game | teams: Gameplay.add_player(teams, player)} }
  end
  def handle_cast({:add_player, player}, game = %{players: players}) do
    updated_players = Gameplay.add_player(players, player)
    { :noreply, %{ game | players: updated_players} }
  end

  def handle_cast({:draw_into_hand, player, num_cards}, _from, game = %{ teams: teams, deck: deck, discard_pile: discard_pile }) do
    { new_hand, remaining_deck, discard_pile } = Cards.draw_into_hand(deck, player.hand, discard_pile, num_cards)
    player_with_drawn_cards = Map.replace!(player, :hand, new_hand)
    #how to replace hand??

    {:noreply, %{ game | deck: remaining_deck, discard_pile: discard_pile }}
  end

  def handle_call(:shuffle, _from, game = %{ deck: deck }) do
    shuffled_deck = Cards.shuffle(deck)
    {:reply, shuffled_deck, %{ game | deck: shuffled_deck}}
  end

  def handle_cast({:draw_with_reshuffle, num}, _from, {deck, discard_pile}) do
    {:noreply, Cards.draw_with_reshuffle(deck, discard_pile, num)}
  end

  def handle_cast({:discard, card, player}, _from, game = %{ discard_pile: discard_pile }) do
    { new_hand , discard_pile } = Cards.discard(card, player.hand, discard_pile)
    #how to replace hand
    { :noreply, %{game | discard_pile: discard_pile }}
  end

  def handle_call(:state, _from, game) do
    { :reply, game, game }
  end

end
