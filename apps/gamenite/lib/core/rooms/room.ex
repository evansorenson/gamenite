defmodule Gamenite.Rooms.Room do
  use Accessible

  defstruct id: nil, name: nil, connected_users: %{}, messages: [], game_id: nil

  def new(attrs) do
    struct!(__MODULE__, attrs)
  end
end
