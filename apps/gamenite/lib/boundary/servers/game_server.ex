defmodule Gamenite.GameServer do
  alias Phoenix.PubSub

  def via(room_uuid) do
    {:via,
    Registry,
    {Gamenite.Registry.Game, room_uuid}}
  end

  def start_child(module, game, room_uuid) do
    DynamicSupervisor.start_child(
      Gamenite.Supervisor.Game,
      child_spec(module, {game, room_uuid}))
    broadcast_game_update(game)
    :ok
  end

  def child_spec(module, {game, room_uuid}) do
    %{
      id: {module, room_uuid},
      start: {module, :start_link, [{game, room_uuid}]},
      restart: :temporary
    }
  end

  def game_exists?(room_slug) do
    case Registry.lookup(Gamenite.Registry.Game, room_slug) do
      [{_pid, _val}] -> true
      [] -> false
    end
  end

  def broadcast_game_update(game) do
    PubSub.broadcast(Gamenite.PubSub, "room:" <> game.room_slug, {:game_update, game})
  end

  def game_response({:error, reason}, old_state) do
    {:reply, {:error, reason}, old_state}
  end
  def game_response(new_state, _old_state) do
    broadcast_game_update(new_state)
    {:reply, :ok, new_state}
  end
end
