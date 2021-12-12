defmodule Gamenite.Timing.Timer do
  defstruct time_remaining: nil,
            timer_ref: nil,
            end_func: nil,
            tick_func: nil,
            interval: 1000,
            decrement: 1

  def new(fields) do
    struct!(__MODULE__, fields)
  end
end
