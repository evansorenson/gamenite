defmodule Gamenite.Game.API do
  def start_game(module, game, room_slug) do
    case DynamicSupervisor.start_child(
           Gamenite.Supervisor.Game,
           child_spec(module, {game, room_slug})
         ) do
      {:ok, _pid} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp child_spec(module, {game, room_slug}) do
    %{
      id: {module, room_slug},
      start: {module, :start_link, [{game, room_slug}]},
      restart: :temporary
    }
  end

  def via(room_slug) do
    {:via, Registry, {Gamenite.Registry.Game, room_slug}}
  end

  def game_exists?(room_slug) do
    case Registry.lookup(Gamenite.Registry.Game, room_slug) do
      [{_pid, _val}] -> true
      [] -> false
    end
  end

  def end_game(room_slug) do
    GenServer.stop(via(room_slug))
  end

  def state(room_slug) do
    GenServer.call(via(room_slug), :state)
  end
end
