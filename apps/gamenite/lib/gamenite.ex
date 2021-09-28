defmodule Gamenite do

  def start_game("Salad Bowl", room_uuid) do
    Gamenite.SaladBowlGameKeeper.start_game()
  end
  def start_game("Charades", room_uuid) do
    Gamenite.Charades.start_game()
  end
  def draw(room_uuid, num_cards) do
    GenServer.cast(room_uuid, {:draw, num_cards})
  end

  def draw_with_reshuffle(room_uuid, num_cards) do
    GenServer.cast(room_uuid, {:draw_with_reshuffle, num_cards})
  end

  def shuffle_deck(room_uuid) do
    GenServer.call(room_uuid, :shuffle)
  end

  def skip_card(room_uuid, card) do
    GenServer.call(room_uuid, {:skip_card, card})
  end

  def add_player(room_uuid, player) do
    GenServer.call(room_uuid, {:add_player, player})
  end

  def state(room_uuid) do
    GenServer.call(room_uuid, :state)
  end
end
