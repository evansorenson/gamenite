defmodule Gamenite.GameServer do
  alias Phoenix.PubSub
  require Logger

  alias Gamenite.Room

  def via(room_slug) do
    {:via, Registry, {Gamenite.Registry.Game, room_slug}}
  end

  def start_game(module, game, room_slug, notify_room? \\ true) do
    case DynamicSupervisor.start_child(
           Gamenite.Supervisor.Game,
           child_spec(module, {game, room_slug})
         ) do
      {:ok, _pid} ->
        if notify_room? do
          Room.API.set_game_in_progress(room_slug, true)
        else
          :ok
        end

      _ ->
        :error
    end
  end

  def child_spec(module, {game, room_slug}) do
    %{
      id: {module, room_slug},
      start: {module, :start_link, [{game, room_slug}]},
      restart: :temporary
    }
  end

  def game_exists?(room_slug) do
    case Registry.lookup(Gamenite.Registry.Game, room_slug) do
      [{_pid, _val}] -> true
      [] -> false
    end
  end

  def state(room_slug) do
    GenServer.call(via(room_slug), :state)
  end

  def broadcast_game_update(game) do
    PubSub.broadcast(Gamenite.PubSub, "game:" <> game.room_slug, {:game_update, game})
  end

  @timeout Application.get_env(:gamenite, :game_timeout)
  def game_response({:error, reason}, old_state) do
    {:reply, {:error, reason}, old_state, @timeout}
  end

  def game_response(new_state, _old_state) do
    broadcast_game_update(new_state)
    {:reply, :ok, new_state, @timeout}
  end

  def handle_call(:state, _from, game) do
    {:reply, {:ok, game}, game}
  end

  def handle_info(:timeout, game) do
    Logger.info("Game inactive. Shutting down.")
    {:stop, :normal, game}
  end
end
