defmodule Gamenite.SaladBowlAPI do
  import Gamenite.SaladBowlServer, only: [via: 1, start_child: 2, game_exists?: 1]

  def start_game(game, room_slug) do
    start_child(game, room_slug)
  end

  def exists?(room_slug) do
    game_exists?(room_slug)
  end

  def state(room_slug) do
    GenServer.call(via(room_slug), :state)
  end

  def add_player(room_slug, player) do
    GenServer.call(via(room_slug), {:add_player, player})
  end

  def start_turn(room_slug) do
    GenServer.call(via(room_slug), :start_turn)
  end

  def shuffle(room_slug) do
    GenServer.call(via(room_slug), :shuffle)
  end

  def next_player(room_slug) do
    GenServer.call(via(room_slug), :next_player)
  end

  def card_completed(room_slug, outcome) do
    GenServer.call(via(room_slug), {:completed_card, outcome})
  end

  def review_cards(room_slug) do
    GenServer.call(via(room_slug), :review_cards )
  end

  def submit_cards(room_slug, word_list, user_id) do
    GenServer.call(via(room_slug), {:submit_cards, word_list, user_id})
  end
end
