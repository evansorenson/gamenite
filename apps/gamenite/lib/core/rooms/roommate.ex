defmodule Gamenite.Rooms.Roommate do
  defstruct user_id: nil, muted?: false, host?: false

  def new(attrs) do
    struct!(__MODULE__, attrs)
  end
end
