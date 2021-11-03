defmodule Gamenite.SaladBowl.API do
  import Gamenite.GameServer

  def start_game(game, room_slug) do
    start_child(Gamenite.SaladBowlServer, game, room_slug)
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

  def end_turn(room_slug) do
    GenServer.call(via(room_slug), :end_turn)
  end

  def submit_cards(room_slug, word_list, user_id) do
    GenServer.call(via(room_slug), {:submit_cards, word_list, user_id})
  end

  def change_card_outcome(room_slug, card_index, outcome) do
    GenServer.call(via(room_slug), {:change_card_outcome, card_index, outcome})
  end
end
