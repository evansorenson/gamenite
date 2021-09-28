defmodule Gamenite.Rooms.Roommate do
  use Accessible

  defstruct user_id: nil, muted?: false, host?: false

  def new(attrs) do
    struct!(__MODULE__, attrs)
  end
end
