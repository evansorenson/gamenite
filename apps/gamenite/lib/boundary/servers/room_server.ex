defmodule Gamenite.RoomServer do
  use GenServer
  require Logger

  alias Gamenite.Rooms
  alias Gamenite.Rooms.Room

  # Server
  def init(slug) do
    {:ok, Room.new(%{id: slug})}
  end

  def start_link(slug) do
    GenServer.start_link(
      __MODULE__,
      slug,
      name: via(slug))
  end

  def via(slug) do
    {:via,
    Registry,
    {Gamenite.Registry.Room, slug}}
  end

  def child_spec(slug) do
    %{
      id: {__MODULE__, slug},
      start: {__MODULE__, :start_link, [slug]},
      restart: :temporary
    }
  end

  def start_child(slug) do
    with {:ok, _pid} <- DynamicSupervisor.start_child(Gamenite.Supervisor.Room, child_spec(slug)) do
      {:ok, slug}
    else
      {:error, reason} ->
        Logger.info(%{message: reason, title: "Error starting room"})
        {:error, reason}
    end
  end

  defp reply_ok_new_state(new_state) do
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:join, player}, _from, room) do
    reply_ok_new_state(Rooms.join(room, player))
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
    reply_ok_new_state(Rooms.invert_mute(room, player))
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
end
