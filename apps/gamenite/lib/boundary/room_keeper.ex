defmodule Gamenite.RoomKeeper do
  use GenServer

  alias Gamenite.Rooms

  def init({room_uuid, name, password}) do
    {:ok, Rooms.new(%{id: room_uuid, name: name, password: password})}
  end

  def child_spec({room_uuid, name, password}) do
    %{
      id: room_uuid,
      start: {__MODULE__, :start_link, [{room_uuid, name, password}]},
      restart: :temporary
    }
  end

  def start_link({room_uuid, name, password}) do
    GenServer.start_link(__MODULE__, {room_uuid, name, password})
  end

  def start_room({room_uuid, name, password}) do
    DynamicSupervisor.start_child(
      Gamenite.Supervisor.Room,
      child_spec({room_uuid, name, password}))
  end

  def handle_call({:join, player}, _from, room) do
    {:reply, :ok, Rooms.join(room, player)}
  end

  def handle_call({:leave, player}, _from, room) do
    {:reply, :ok, Rooms.leave(room, player)}
  end

  def handle_call({:mute, player}, _from, room) do
    {:reply, :ok, Rooms.mute(room, player)}
  end

  def handle_call({:kick, player}, _from, room) do
    {:reply, :ok, Rooms.kick(room, player)}
  end

  def handle_call({:game_started, game_id}, _from, room) do
    {:reply, :ok, Room.start_game(room, game_id)}
  end

  def handle_call({:game_ended, game_id}, _from, room) do
    {:reply, :ok, Rooms.end_game(room, game_id)}
  end

  def handle_call({:message, message}, _from, room) do
    {:reply, :ok, Rooms.message(room, message)}
  end
end
