defmodule Gamenite.RoomKeeper do
  use GenServer
  require Logger

  alias Gamenite.Rooms
  alias Gamenite.Rooms.Room

  # Server
  def init({room_uuid, name, password}) do
    {:ok, Room.new(%{id: room_uuid, name: name, password: password})}
  end

  def child_spec({room_uuid, name, password}) do
    %{
      id: {__MODULE__, room_uuid},
      start: {__MODULE__, :start_link, [{room_uuid, name, password}]},
      restart: :temporary
    }
  end

  def start_link({room_uuid, name, password}) do
    GenServer.start_link(
      __MODULE__,
      {room_uuid, name, password},
      name: via(room_uuid))
  end

  defp via(room_uuid) do
    {:via,
    Registry,
    {Gamenite.Registry.Room, room_uuid}}
  end

  def create_room(room_uuid, name, password \\ nil) do
    DynamicSupervisor.start_child(
      Gamenite.Supervisor.Room,
      child_spec({room_uuid, name, password}))
  end

  def handle_call({:join, player}, _from, room) do
    {:reply, :ok, Rooms.join(room, player)}
  end

  def handle_call({:leave, _player}, _from, %{connected_users: connected_users} = room) when map_size(connected_users) == 1 do
    Logger.info "Exiting Room: #{room.id}. No players connected."
    reason = "No players connected."
    {:stop, reason, {:stop, reason}, room}
  end
  def handle_call({:leave, player}, _from, room) do
    {:reply, :ok, Rooms.leave(room, player)}
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

  # API
  def join(room_id, player) do
    GenServer.call(via(room_id), {:join, player})
  end

  def leave(room_id, player) do
    GenServer.call(via(room_id), {:leave, player})
  end

  def invert_mute(room_id, player) do
    GenServer.call(via(room_id), {:invert_mute, player})
  end
end
