defmodule Gamenite.Rooms.Room do
  use Accessible

  defstruct slug: nil, name: nil, roommates: %{}, messages: [], game_id: nil, game_in_progress?: false, chat_enabled?: true

  def new(attrs) do
    struct!(__MODULE__, attrs)
  end
end
