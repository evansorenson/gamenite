defmodule Gamenite.RoomAPI do
  use GenServer
  import Gamenite.RoomServer, only: [ via: 1, start_child: 1 ]
  alias Gamenite.Rooms

  def start_room do
    generate_slug()
    |> start_child
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

  def slug_exists?(slug) do
    case Registry.lookup(Gamenite.Registry.Room, slug) do
      [{_pid, _val}] -> true
      [] -> false
    end
  end

  defp generate_slug do
    slug = do_generate_slug()
    if slug_exists?(slug) do
       generate_slug()
    end

    slug
  end

  defp do_generate_slug() do
    :random.seed(:erlang.now)
    letters_numbers = Enum.map(Enum.to_list(?A..?Z) ++ Enum.to_list(?0..?9), fn(n) -> <<n>> end)
    slug = Enum.take_random(letters_numbers, 6)
    Enum.join(slug, "")
  end
end
