defmodule Gamenite.Timer do
  defmacro __using__(_opts) do
    quote do
      alias Gamenite.Timer
      alias Gamenite.Game.Server

      def handle_info({:tick, timer_field}, game) do
        case Timing.get_timer(game, timer_field) do
          nil ->
            {:noreply, game}

          timer ->
            decremented_timer = Timer.decrement_time(timer)

            new_game =
              game
              |> apply_tick(decremented_timer, timer_field)
              |> Server.broadcast_game_update()

            {:noreply, new_game}
        end
      end

      def apply_tick(game, timer, timer_field) when timer.time_remaining <= 1 do
        stopped_timer = Timing.stop_timer(game, timer, timer_field)
        new_game = timer.end_func(game)
      end

      def apply_tick(game, timer, timer_field) do
        new_game = timer.tick_func(game, timer_field)
      end
    end
  end

  def stop_timer(game, timer_field) do
    do_stop_timer(game, get_timer(game, timer_field), timer_field)
  end

  def do_stop_timer(game, nil, _timer_field), do: game

  def do_stop_timer(game, timer, timer_field) do
    Process.cancel_timer(timer.timer_ref)

    game
    |> Map.put(timer_field, %{timer | timer_ref: nil})
  end

  def start_timer(
        game,
        timer_field,
        tick_func \\ &default_tick_func/3,
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

  def default_tick_func(game, timer, timer_field) do
    new_timer =
      timer
      |> decrement_time()
      |> send_tick(timer_field)

    game
    |> put_timer(timer_field, new_timer)
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

  def decrement_time(timer) do
    %{timer | time_remaining: timer.time_remaining - timer.decrement}
  end
end
