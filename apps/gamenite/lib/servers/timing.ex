defmodule Gamenite.Timing do
  defmacro __using__(_opts) do
    quote do
      alias Gamenite.Timing
      alias Gamenite.Game.Server

      def handle_info({:tick, func}, game) do
        new_game = func.(game)
        Server.broadcast_game_update(new_game)
        {:noreply, new_game}
      end
    end
  end

  def stop_timer(%{timer: nil} = game) do
    game
  end

  def stop_timer(%{timer: timer} = game) do
    Process.cancel_timer(timer)

    game
    |> Map.put(:timer, nil)
  end

  def start_timer(game, func, interval \\ 1000) do
    timer = Process.send_after(self(), {:tick, func}, interval)
    Map.put(game, :timer, timer)
  end
end
