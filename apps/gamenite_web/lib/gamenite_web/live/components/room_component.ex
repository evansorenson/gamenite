defmodule GameniteWeb.RoomComponent do
  use GameniteWeb, :live_component
  require Logger

  alias Gamenite.RoomKeeper
  alias Gamenite.Rooms.{Roommate}
  alias Phoenix.Socket.Broadcast
  alias GameniteWeb.LiveMonitor

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{user: user, slug: slug} = _assigns, socket) do
    monitor_live_view_process(slug, user)

    with :ok <- start_or_get_room_process(slug),
    {:ok, room} <- join_room(slug, user)
    do
      broadcast_room_update(slug, room)
      {:ok, socket
      |> assign(room: room)
      }
    else
      {:error, reason} ->
        socket
        |> put_flash(:error, reason)
        |> push_redirect(to: Routes.game_path(socket, :index))
    end
  end

  def update(%{room: room} = _assigns, socket) do
    IO.puts "hi"
    {:ok, assign(socket, room: room)}
  end

  defp start_or_get_room_process(slug) do
    case RoomKeeper.create_room(slug) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      _ -> {:error, "Failed starting or getting room: #{slug}"}
    end
  end

  defp join_room(room_id, user) do
    RoomKeeper.join(room_id, Roommate.new_from_user(user))
  end

  defp broadcast_room_update(room_id, room) do
    GameniteWeb.Endpoint.broadcast_from(
      self(),
      "room:" <> room_id,
      "room_state_update",
      room
    )
  end


  defp monitor_live_view_process(room_slug, user) do
    LiveMonitor.monitor(
     self(),
     __MODULE__,
     %{user: user, room_slug: room_slug}
     )
   end

  @doc """
  Callback that happens when the LV process is terminating.
  This allows the player to be removed from the game, and
  the entire game server process can also be terminated if
  there are no remaining players.
  """
  @spec unmount(term(), map()) :: :ok
  def unmount(_reason, %{user: user, room_slug: room_slug}) do
    Logger.info("Unmounting LiveView")
    {:ok, room} = RoomKeeper.leave(room_slug, user.id)
    broadcast_room_update(room_slug, room)

    :ok
  end
end
