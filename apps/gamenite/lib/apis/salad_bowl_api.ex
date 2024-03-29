defmodule Gamenite.SaladBowl.API do
  import Gamenite.Game.API, only: [via: 1]

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

  def update_canvas(room_slug, canvas_data, user_id) do
    GenServer.call(via(room_slug), {:update_canvas, canvas_data, user_id})
  end
end
