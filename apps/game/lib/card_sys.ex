defmodule CardSys do
  @server CardSys.Server

  def start_link(room_uuid, card_struct) do
    GenServer.start_link(@server, card_struct, name: room_uuid)
  end

  def draw(room_uuid, num_cards) do
    GenServer.cast(room_uuid, {:draw, num_cards})
  end

  def draw_with_reshuffle(room_uuid, num_cards) do
    GenServer.cast(room_uuid, {:draw_with_reshuffle, num_cards})
  end

  def shuffle_deck(room_uuid) do
    GenServer.cast(room_uuid, :shuffle)
  end

  def discard(room_uuid, card, hand, discard_pile) do
    GenServer.cast(room_uuid, {:discard, card, hand, discard_pile})
  end
end
