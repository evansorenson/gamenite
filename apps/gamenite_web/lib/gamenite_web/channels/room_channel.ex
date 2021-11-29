defmodule GameniteWeb.RoomChannel do
  use Phoenix.Channel

  require Logger

  @impl true
  def join("room:" <> room_slug, %{user_id: user_id} = params, socket) do
    IO.inspect(params)

    if Rooms.slug_exists?(room_slug) do
      Rooms.add_peer_channel(room_slug, self(), user_id)
      {:ok, Phoenix.Socket.assign(socket, %{room_slug: room_slug, user_id: user_id})}
    else
      Logger.error("""
      Room does not exist.
      Room: #{inspect(room_slug)}
      """)

      {:error, "Failed to join room."}
    end
  end

  @impl true
  def handle_in("mediaEvent", %{"data" => event}, socket) do
    Rooms.media_event(socket.assigns.room_slug, event, socket.assigns.user_id)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:media_event, event}, socket) do
    push(socket, "mediaEvent", %{data: event})

    {:noreply, socket}
  end
end
