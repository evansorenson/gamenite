defmodule Gamenite.Timing do
  alias Gamenite.Timing.Timer

  defmacro __using__(_opts) do
    quote do
      alias Gamenite.Timing
      alias Gamenite.Game.Server

      def handle_info({:tick, timer_field}, game) do
        case Timing.get_timer(game, timer_field) do
          nil ->
            {:noreply, game}

          timer ->
            new_game =
              game
              |> Timing.decrement_timer(timer_field)
              |> apply_tick(timer_field)
              |> Server.broadcast_game_update()

            {:noreply, new_game}
        end
      end

      def apply_tick(game, timer_field) do
        timer = Timing.get_timer(game, timer_field)

        if timer.time_remaining > 0 do
          game
          |> timer.tick_func.(timer_field)
        else
          game
          |> Timing.stop_timer(timer_field)
          |> timer.end_func.()
        end
      end
    end
  end

  def stop_timer(game, timer_field) do
    do_stop_timer(game, get_timer(game, timer_field), timer_field)
  end

  def do_stop_timer(game, %{timer_ref: nil} = _timer, _timer_field), do: game

  def do_stop_timer(game, timer, timer_field) do
    Process.cancel_timer(timer.timer_ref)

    game
    |> Map.put(timer_field, %{timer | timer_ref: nil})
  end

  def start_timer(
        game,
        timer_field,
        tick_func \\ &default_tick_func/2,
        end_func,
        length,
        interval \\ 1000
      ) do
    timer_ref = Process.send_after(self(), {:tick, timer_field}, interval)

    timer =
      Timer.new(%{
        timer_ref: timer_ref,
        end_func: end_func,
        tick_func: tick_func,
        interval: interval,
        time_remaining: length
      })

    Map.put(game, timer_field, timer)
  end

  def default_tick_func(game, timer_field) do
    timer =
      get_timer(game, timer_field)
      |> send_tick(timer_field)

    game
    |> put_timer(timer_field, timer)
  end

  def send_tick(timer, timer_field) do
    timer_ref = Process.send_after(self(), {:tick, timer_field}, timer.interval)
    %{timer | timer_ref: timer_ref}
  end

  def get_timer(game, timer_field) do
    Map.get(game, timer_field)
  end

  def put_timer(game, timer_field, new_timer) do
    game
    |> Map.put(timer_field, new_timer)
  end

  def set_time(game, timer_field, new_time) do
    timer = get_timer(game, timer_field)

    game
    |> put_timer(timer_field, %{timer | time_remaining: new_time})
  end

  def decrement_timer(game, timer_field) do
    timer = get_timer(game, timer_field)
    decremented_timer = Map.put(timer, :time_remaining, timer.time_remaining - timer.decrement)
    put_timer(game, timer_field, decremented_timer)
  end
end
