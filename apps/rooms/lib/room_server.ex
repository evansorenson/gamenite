defmodule Rooms.Room.Server do
  use GenServer
  require Logger
  require Membrane.Logger

  alias Phoenix.PubSub
  alias Rooms.Room

  @impl true
  def init(slug) do
    Membrane.Logger.info("Spawning room process: #{inspect(self())}")

    sfu_options = [
      id: slug,
      network_options: [
        stun_servers: Application.fetch_env!(:rooms, :stun_servers),
        turn_servers: Application.fetch_env!(:rooms, :turn_servers),
        use_integrated_turn: Application.fetch_env!(:rooms, :use_integrated_turn),
        integrated_turn_ip: Application.fetch_env!(:rooms, :integrated_turn_ip),
        dtls_pkey: Application.get_env(:rooms, :dtls_pkey),
        dtls_cert: Application.get_env(:rooms, :dtls_cert)
      ],
      packet_filters: %{
        OPUS: [silence_discarder: %Membrane.RTP.SilenceDiscarder{vad_id: 1}]
      },
      payload_and_depayload_tracks?: false
    ]

    {:ok, pid} = Membrane.RTC.Engine.start(sfu_options, [])
    send(pid, {:register, self()})

    {:ok, Room.new(%{slug: slug, sfu_engine: pid, peer_channels: %{}})}
  end

  def start_link(slug) do
    GenServer.start_link(
      __MODULE__,
      slug,
      name: via(slug)
    )
  end

  def via(slug) do
    {:via, Registry, {Rooms.Registry.Room, slug}}
  end

  def child_spec(slug) do
    %{
      id: {__MODULE__, slug},
      start: {__MODULE__, :start_link, [slug]},
      restart: :temporary
    }
  end

  def start_child(slug) do
    with {:ok, _pid} <- DynamicSupervisor.start_child(Rooms.Supervisor.Room, child_spec(slug)) do
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
    PubSub.broadcast(Rooms.PubSub, "room:" <> room.slug, {:room_update, room})
  end

  def handle_call(:state, _from, room) do
    {:reply, room, room}
  end

  def handle_call({:join, player}, _from, room) do
    room
    |> Room.join(player)
    |> response(room)
  end

  def handle_call({:join_if_previous_or_current, user_id}, _from, room) do
    room
    |> Room.join_if_previous_or_current(user_id)
    |> response(room)
  end

  @timeout Application.get_env(:rooms, :room_timeout)
  def handle_call({:leave, user_id}, _from, %{roommates: roommates} = room)
      when map_size(roommates) == 1 do
    new_room =
      room
      |> Room.leave(user_id)

    {:reply, :ok, new_room, @timeout}
  end

  def handle_call({:leave, user_id}, _from, room) do
    room
    |> Room.leave(user_id)
    |> response(room)
  end

  def handle_call({:invert_mute, player}, _from, room) do
    room
    |> Room.invert_mute(player)
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

  def handle_call({:send_message, message}, _from, room) do
    room
    |> Room.send_message(message)
    |> response(room)
  end

  def handle_call({:set_game, game_id}, _from, room) do
    room
    |> Room.set_game(game_id)
    |> response(room)
  end

  def handle_call({:set_game_in_progress, in_progress?}, _from, room) do
    %{room | game_in_progress?: in_progress?}
    |> response(room)
  end

  def handle_info(:timeout, room) do
    Logger.info("Room inactive. Shutting down.")
    {:stop, :normal, room}
  end

  #### Membrane
  @impl true
  def handle_call({:add_peer_channel, peer_channel_pid, peer_id}, _from, state) do
    state = put_in(state, [:peer_channels, peer_id], peer_channel_pid)
    Process.monitor(peer_channel_pid)
    {:reply, :ok, state}
  end

  @impl true
  def handle_info({_sfu_engine, {:sfu_media_event, :broadcast, event}}, state) do
    for {_peer_id, pid} <- state.peer_channels, do: send(pid, {:media_event, event})
    {:noreply, state}
  end

  @impl true
  def handle_info({_sfu_engine, {:sfu_media_event, to, event}}, state) do
    if state.peer_channels[to] != nil do
      send(state.peer_channels[to], {:media_event, event})
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({sfu_engine, {:new_peer, peer_id, _metadata}}, state) do
    # get node the peer with peer_id is running on
    peer_channel_pid = Map.get(state.peer_channels, peer_id)
    peer_node = node(peer_channel_pid)
    send(sfu_engine, {:accept_new_peer, peer_id, peer_node})
    {:noreply, state}
  end

  @impl true
  def handle_info({_sfu_engine, {:peer_left, _peer_id}}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call({:media_event, _user_id, _event} = msg, _from, state) do
    send(state.sfu_engine, msg)
    {:reply, :ok, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {peer_id, _peer_channel_id} =
      state.peer_channels
      |> Enum.find(fn {_peer_id, peer_channel_pid} -> peer_channel_pid == pid end)

    send(state.sfu_engine, {:remove_peer, peer_id})
    {_elem, state} = pop_in(state, [:peer_channels, peer_id])
    {:noreply, state}
  end
end
