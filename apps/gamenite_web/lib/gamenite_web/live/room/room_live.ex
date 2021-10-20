defmodule GameniteWeb.RoomLive do
  @moduledoc """
  A LiveView for hosting games and managing social interactions.
  """
  use GameniteWeb, :live_view
  require Logger

  alias GamenitePersistance.Accounts
  alias Phoenix.Socket.Broadcast
  alias Gamenite.RoomAPI
  alias Gamenite.Rooms.{Roommate}
  alias GameniteWeb.LiveMonitor

  @impl true
  def mount( _params, %{"slug" => slug } = session, socket) do
    user = mount_socket_user(socket, session)

    if connected?(socket) do
      monitor_live_view_process(slug, user)

      Phoenix.PubSub.subscribe(GamenitePersistance.PubSub, "room:" <> slug)
      Phoenix.PubSub.subscribe(GamenitePersistance.PubSub, "room:" <> slug <> ":" <> user.id)
      Phoenix.PubSub.subscribe(GamenitePersistance.PubSub, "game:" <> slug)
    end

    with true <- RoomAPI.slug_exists?(slug),
         {:ok, room } = RoomAPI.join(slug, Roommate.new_from_user(user)) do
      broadcast_room_update(room.id, room)
      {:ok,
      socket
      |> assign(room: room, user: user, game_id: room.game_id, slug: slug, connected_users: room.connected_users)
      |> assign(offer_requests: [], ice_candidate_offers: [], sdp_offers: [], answers: [])}
    else
      false ->
        {:ok, socket
        |> put_flash(:error, "Room does not exist.")
        |> push_redirect(to: Routes.game_path(socket, :index))}
      {:error, reason} ->
        {:ok, socket
        |> put_flash(:error, reason)
        |> push_redirect(to: Routes.game_path(socket, :index))}
    end
  end

  defp broadcast_room_update(room_id, room) do
    GameniteWeb.Endpoint.broadcast_from(
      self(),
      "room:" <> room_id,
      "room_state_update",
      room
    )
  end

  def handle_event("mute", %{"user_id" => user_id}, socket) do
    {:ok, room} = RoomAPI.invert_mute(socket.assigns.room.id, Map.get(socket.assigns.room.connected_users, user_id))
    broadcast_room_update(socket.assigns.slug, room)
    {:noreply, assign(socket, room: room)}
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
    # {:ok, room} = RoomAPI.leave(room_slug, user.id)
    # broadcast_room_update(room_slug, room)

    :ok
  end

  def handle_info(%Broadcast{event: "room_state_update", payload: room}, socket) do
    {:noreply, assign(socket, room: room, connected_users: room.connected_users)}
  end

  def handle_info(%Broadcast{event: "game_state_update", payload: game}, socket) do
    send_update(self(), GameniteWeb.GameLive, %{ id: socket.assigns.game_id, game: game })
    {:noreply, socket}
  end

  # @impl true
  # def handle_event("change_display_name", %{"new_name" => new_name}, socket) do
  #   socket
  # end

  defp mount_socket_user(socket, params) do
    user_id = Map.get(params, "user_id")
    user = Accounts.get_user(user_id)
    socket
    |> assign(:user, user)
    user
  end

    ## All RPC logic >>>
    @impl true
    @doc """
    When an offer requested has been received, add it to the '@offer_request' list.
    """
    defp send_direct_message(slug, to_user, event, payload) do
      GameniteWeb.Endpoint.broadcast_from(
        self(),
        "room:" <> slug <> ":" <> to_user,
        event,
        payload
      )
    end

    @impl true
    def handle_event("join_call", _params, socket) do
      for user <- socket.assigns.room.connected_users do
        send_direct_message(
          socket.assigns.slug,
          user,
          "request_offers",
          %{from_user: socket.assigns.user}
        )
      end

      {:noreply, socket}
    end

    @impl true
    def handle_event("new_ice_candidate", payload, socket) do
      payload = Map.merge(payload, %{"from_user" => socket.assigns.user.username})

      send_direct_message(socket.assigns.slug, payload["toUser"], "new_ice_candidate", payload)
      {:noreply, socket}
    end

    @impl true
    def handle_event("new_sdp_offer", payload, socket) do
      payload = Map.merge(payload, %{"from_user" => socket.assigns.user.username})

      send_direct_message(socket.assigns.slug, payload["toUser"], "new_sdp_offer", payload)
      {:noreply, socket}
    end

    @impl true
    def handle_event("new_answer", payload, socket) do
      payload = Map.merge(payload, %{"from_user" => socket.assigns.user.username})

      send_direct_message(socket.assigns.slug, payload["toUser"], "new_answer", payload)
      {:noreply, socket}
    end

    def handle_info(%Broadcast{event: "request_offers", payload: request}, socket) do
      {:noreply,
        socket
        |> assign(:offer_requests, socket.assigns.offer_requests ++ [request])}
    end

    @impl true
    def handle_info(%Broadcast{event: "new_ice_candidate", payload: payload}, socket) do
      {:noreply,
        socket
        |> assign(:ice_candidate_offers, socket.assigns.ice_candidate_offers ++ [payload])
      }
    end

    @impl true
    def handle_info(%Broadcast{event: "new_sdp_offer", payload: payload}, socket) do
      {:noreply,
        socket
        |> assign(:sdp_offers, socket.assigns.ice_candidate_offers ++ [payload])
      }
    end

    @impl true
    def handle_info(%Broadcast{event: "new_answer", payload: payload}, socket) do
      {:noreply,
        socket
        |> assign(:answers, socket.assigns.answers ++ [payload])
      }
    end

    def handle_info({:tick, game}, socket) do
      IO.puts "hiiiiiii"
      broadcast_game_update(socket.assigns.slug, game)
      {:noreply, socket}
    end

    defp broadcast_game_update(room_id, game) do
      GameniteWeb.Endpoint.broadcast_from(
        self(),
        "game:" <> room_id,
        "game_state_update",
        game
      )
    end
end
