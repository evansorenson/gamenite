defmodule GameniteWeb.RoomLive do
  @moduledoc """
  A LiveView for hosting games and managing social interactions.
  """
  use GameniteWeb, :live_view
  require Logger

  alias Phoenix.PubSub
  alias Phoenix.Socket.Broadcast
  alias GamenitePersistance.Accounts
  alias Gamenite.RoomAPI
  alias Gamenite.Rooms.{Roommate}
  alias GameniteWeb.LiveMonitor

  @impl true
  def mount(_params, %{"slug" => slug} = session, socket) do
    user = mount_socket_user(socket, session)

    if connected?(socket) do
      monitor_live_view_process(slug, user)

      PubSub.subscribe(Gamenite.PubSub, "room:" <> slug)
      PubSub.subscribe(Gamenite.PubSub, "room:" <> slug <> ":" <> user.id)
    end

    with true <- RoomAPI.slug_exists?(slug),
        {:ok, room} <- RoomAPI.join(slug, Roommate.new_from_user(user))
    do
      {:ok,
       socket
       |> assign(
         room: room,
         user: user,
         game_id: room.game_id,
         slug: slug,
         connected_users: room.connected_users
       )
       |> assign(offer_requests: [], ice_candidate_offers: [], sdp_offers: [], answers: [])}
    else
      false ->
        {:ok,
        socket
        |> put_flash(:error, "Room does not exist.")
        |> push_redirect(to: Routes.game_path(socket, :index))}
      {:error, reason} ->
        {:ok,
        socket
        |> put_flash(:error, reason)
        |> push_redirect(to: Routes.game_path(socket, :index))}
    end
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
  def unmount(_reason, %{user: user, room_slug: room_slug}) do
    Logger.info("Unmounting LiveView")
    RoomAPI.leave(room_slug, user.id)
  end

  defp mount_socket_user(socket, params) do
    user_id = Map.get(params, "user_id")
    user = Accounts.get_user(user_id)

    socket
    |> assign(:user, user)

    user
  end

  defp room_response(:ok, socket) do
    {:noreply, socket}
  end
  defp room_response({:error, reason}, socket) do
    {:noreply,
  socket
  |> put_flash(:error, reason)}
  end

  def handle_event("mute", %{"user_id" => user_id}, socket) do
    RoomAPI.invert_mute(
        socket.assigns.room.slug,
        Map.get(socket.assigns.room.connected_users, user_id)
      )
    |> room_response(socket)
  end

  def handle_info({:room_update, room}, socket) do
    {:noreply, assign(socket, room: room, connected_users: room.connected_users)}
  end

  def handle_info({:game_changeset_update, game_changeset}, socket) do
    send_update(self(), GameniteWeb.GameLive, %{id: socket.assigns.game_id, game_changeset: game_changeset})
    {:noreply, socket}
  end

  def handle_info({:game_update, game}, socket) do
    send_update(self(), GameniteWeb.GameLive, %{id: socket.assigns.game_id, game: game})
    {:noreply, socket}
  end
end
