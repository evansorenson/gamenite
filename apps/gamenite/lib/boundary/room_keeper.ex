defmodule Gamenite.RoomKeeper do
  use GenServer
  require Logger

  alias Gamenite.Rooms
  alias Gamenite.Rooms.Room

  # Server
  def init({room_uuid,  password}) do
    {:ok, Room.new(%{id: room_uuid, password: password})}
  end

  def child_spec({room_uuid,  password}) do
    %{
      id: {__MODULE__, room_uuid},
      start: {__MODULE__, :start_link, [{room_uuid, password}]},
      restart: :temporary
    }
  end

  def start_link({room_uuid, password}) do
    GenServer.start_link(
      __MODULE__,
      {room_uuid, password},
      name: via(room_uuid))
  end

  defp via(room_uuid) do
    {:via,
    Registry,
    {Gamenite.Registry.Room, room_uuid}}
  end

  def generate_slug do
    slug = do_generate_slug()
    if slug_exists?(slug) do
       generate_slug()
    end

    slug
  end

  defp do_generate_slug() do
    :random.seed(:erlang.now)
    alphabet = Enum.map(Enum.to_list(?A..?Z), fn(n) -> <<n>> end)
    letters = Enum.take_random(alphabet, 6)
    Enum.join(letters, "")
  end

  def slug_exists?(slug) do
    IO.inspect Registry.lookup(Gamenite.Registry.Room, slug)
    case Registry.lookup(Gamenite.Registry.Room, slug) do
      [{_pid, _val}] -> true
      [] -> false
    end
  end

  def create_room(password \\ nil) do
    room_slug = generate_slug()
    DynamicSupervisor.start_child(
      Gamenite.Supervisor.Room,
      child_spec({room_slug, password}))
    {:ok, room_slug}
  end

  def handle_call({:join, player}, _from, room) do
    new_state = Rooms.join(room, player)
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:leave, _player}, _from, %{connected_users: connected_users} = room) when map_size(connected_users) == 1 do
    Logger.info "Exiting Room: #{room.id}. No players connected."
    reason = "No players connected."
    {:stop, reason, {:stop, reason}, room}
  end
  def handle_call({:leave, user_id}, _from, room) do
    new_state = Rooms.leave(room, user_id)
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:invert_mute, player}, _from, room) do
    {:reply, :ok, Rooms.invert_mute(room, player)}
  end

  def handle_call({:kick, player}, _from, room) do
    {:reply, :ok, Rooms.kick(room, player)}
  end

  def handle_call({:game_started, game_id}, _from, room) do
    {:reply, :ok, Room.start_game(room, game_id)}
  end

  def handle_call({:game_ended}, _from, room) do
    {:reply, :ok, Room.end_game(room)}
  end

  def handle_call({:message, message}, _from, room) do
    {:reply, :ok, Rooms.message(room, message)}
  end

  def handle_call({:set_game, game_id}, _from, room) do
    {:reply, :ok, Rooms.set_game(room, game_id)}
  end

  # API
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
