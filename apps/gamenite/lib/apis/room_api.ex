defmodule Gamenite.Room.API do
  import Gamenite.Room.Server, only: [via: 1, start_child: 1]

  def start_room do
    generate_slug()
    |> start_child
  end

  def join(room_slug, player) do
    GenServer.call(via(room_slug), {:join, player})
  end

  def leave(room_slug, user_id) do
    GenServer.call(via(room_slug), {:leave, user_id})
  end

  def invert_mute(room_slug, player) do
    GenServer.call(via(room_slug), {:invert_mute, player})
  end

  def set_game(room_slug, game_id) do
    GenServer.call(via(room_slug), {:set_game, game_id})
  end

  def set_game_in_progress(room_slug, in_progress?) do
    GenServer.call(via(room_slug), {:set_game_in_progress, in_progress?})
  end

  def send_message(room_slug, message) do
    GenServer.call(via(room_slug), {:send_message, message})
  end

  def slug_exists?(slug) do
    case Registry.lookup(Gamenite.Registry.Room, slug) do
      [{_pid, _val}] -> true
      [] -> false
    end
  end

  def generate_slug do
    slug = do_generate_slug()

    if slug_exists?(slug) do
      generate_slug()
    end

    slug
  end

  defp do_generate_slug() do
    :random.seed(:erlang.now())
    letters_numbers = Enum.map(Enum.to_list(?A..?Z) ++ Enum.to_list(?0..?9), fn n -> <<n>> end)
    slug = Enum.take_random(letters_numbers, 6)
    Enum.join(slug, "")
  end
end
