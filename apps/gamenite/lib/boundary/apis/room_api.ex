defmodule Gamenite.RoomAPI do
  use GenServer
  import Gamenite.RoomKeeper, only: [ via: 1, start_child: 0 ]

  def start_room do
    start_child()
  end

  def join(room_id, player) do
    GenServer.call(via(room_id), {:join, player})
  end

  def leave(room_id, user_id) do
    GenServer.call(via(room_id), {:leave, user_id})
  end

  def invert_mute(room_id, player) do
    GenServer.call(via(room_id), {:invert_mute, player})
  end

  def set_game(room_id, game_id) do
    GenServer.call(via(room_id), {:set_game, game_id})
  end
end
