defmodule Gamenite.SaladBowlAPI do
  import Gamenite.SaladBowlServer, only: [via: 1, start_child: 2]

  def start_game(game, room_slug) do
    start_child(game, room_slug)
  end

  def add_player(room_slug, player) do
    GenServer.call(via(room_slug), {:add_player, player})
  end

  def start_turn(room_slug) do
    GenServer.call(via(room_slug), :start_turn)
  end

  def draw_card(room_slug) do
    GenServer.call(via(room_slug), :draw_card)
  end

  def shuffle(room_slug) do
    GenServer.call(via(room_slug), :shuffle)
  end

  def next_player(room_slug) do
    GenServer.call(via(room_slug), :next_player)
  end

  def correct_card(room_slug, card) do
    GenServer.call(via(room_slug), {:correct_card, card})
  end

  def review_cards(room_slug) do
    GenServer.call(via(room_slug), :review_cards )
  end

  def skip_card(room_slug, card) do
    GenServer.call(via(room_slug), {:skip_card, card})
  end
end
