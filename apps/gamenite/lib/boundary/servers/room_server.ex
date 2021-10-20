defmodule Gamenite.RoomServer do
  use GenServer
  require Logger

  alias Phoenix.PubSub
  alias Gamenite.Rooms
  alias Gamenite.Rooms.Room

  # Server
  def init(slug) do
    {:ok, Room.new(%{slug: slug})}
  end

  def start_link(slug) do
    GenServer.start_link(
      __MODULE__,
      slug,
      name: via(slug)
    )
  end

  def via(slug) do
    {:via, Registry, {Gamenite.Registry.Room, slug}}
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

  defp response({:error, reason}, old_state) do
    {:reply, {:error, reason}, old_state}
  end

  defp response(new_state, _old_state) do
    broadcast_room_update(new_state)
    {:reply, :ok, new_state}
  end

  defp broadcast_room_update(room) do
    PubSub.broadcast(Gamenite.PubSub, "room:" <> room.slug, {:room_update, room})
  end

  def handle_call({:join, player}, _from, room) do
    case Rooms.join(room, player) do
      {:error, reason} ->
        {:reply, {:error, reason}, room}
      new_room ->
        broadcast_room_update(new_room)
        {:reply, {:ok, new_room}, new_room}
    end
  end

  def handle_call({:leave, _player}, _from, %{connected_users: connected_users} = room)
      when map_size(connected_users) == 1 do
    Logger.info("Exiting Room: #{room.slug}. No players connected.")
    reason = "No players connected."
    {:stop, reason, {:stop, reason}, room}
  end

  def handle_call({:leave, user_id}, _from, room) do
    room
    |> Rooms.leave(user_id)
    |> response(room)
  end

  def handle_call({:invert_mute, player}, _from, room) do
    room
    |> Rooms.invert_mute(player)
    |> response(room)
  end

  # def handle_call({:kick, player}, _from, room) do
  #   {:reply, :ok, Rooms.kick(room, player)}
  # end

  # def handle_call({:game_started, game_id}, _from, room) do
  #   {:reply, :ok, Room.start_game(room, game_id)}
  # end

  # def handle_call({:game_ended}, _from, room) do
  #   {:reply, :ok, Room.end_game(room)}
  # end

  # def handle_call({:message, message}, _from, room) do
  #   {:reply, :ok, Rooms.message(room, message)}
  # end

  def handle_call({:set_game, game_id}, _from, room) do
    room
    |> Rooms.set_game(game_id)
    |> response(room)
  end
end
