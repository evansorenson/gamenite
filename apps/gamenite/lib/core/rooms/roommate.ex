defmodule Gamenite.Rooms.Roommate do
  use Accessible

  defstruct user_id: nil, display_name: nil, muted?: false, host?: false

  def new(attrs) do
    struct!(__MODULE__, attrs)
  end

  def new_from_user(%{id: id, username: username} = user) do
    struct!(__MODULE__, %{user_id: id, display_name: username})
  end
end
