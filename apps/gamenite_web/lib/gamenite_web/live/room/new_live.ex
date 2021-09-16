defmodule GameniteWeb.Room.NewLive do
  @moduledoc """
  A LiveView for creating and joining chat rooms
  """

  use GameniteWeb, :live_view

  alias GamenitePersistance.Organizer
  alias Gamenite.Core.Games.CharadesOptions

  alias GameniteWeb.Presence
  alias Phoenix.Socket.Broadcast


  @player_colors ['F2F3F4', '222222', 'F3C300', '875692', 'F38400', 'A1CAF1', 'BE0032', 'C2B280', '848482', '008856', 'E68FAC', '0067A5', 'F99379', '604E97', 'F6A600', 'B3446C', 'DCD300', '882D17', '8DB600', '654522', 'E25822', '2B3D26']
  @default_rounds ["Catchphrase", "Password", "Charades"]

  @impl true
  def mount(_params, %{"slug" => slug, "game_id" => game_id, "_csrf_token" => csrf_token} = session, socket) do
    user = mount_socket_user(socket, session)
    game = GamenitePersistance.Gaming.get_game!(game_id)
    game_options_changeset = CharadesOptions.new_salad_bowl(%{ rounds: ["Catchphrase", "Password", "Charades"]})

    # This PubSub subscription will also handle other events from the users.
    Phoenix.PubSub.subscribe(GamenitePersistance.PubSub, "room:" <> slug)

    # This PubSub subscription will allow the user to receive messages from
    # other users.
    Phoenix.PubSub.subscribe(GamenitePersistance.PubSub, "room:" <> slug <> ":" <> user.id)

    # Track the connecting user with the `room:slug` topic.
    {:ok, _} = Presence.track(self(), "room:" <> slug, user.id, %{})

    case Organizer.get_room(slug) do
      nil ->
        {:ok,
          socket
          |> put_flash(:error, "That room does not exist.")
          |> push_redirect(to: Routes.game_path(socket, :index))
        }
      room ->
        {:ok,
          socket
          |> assign(:room, room)
          |> assign(:game, game)
          |> assign(:game_options_changeset, game_options_changeset)
          |> assign(:user, user)
          |> assign(:slug, slug)
          |> assign(:connected_users, [])
          |> assign(:offer_requests, [])
          |> assign(:ice_candidate_offers, [])
          |> assign(:sdp_offers, [])
          |> assign(:answers, [])
        }
    end
  end

  @impl true
  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply,
      socket
      |> assign(:connected_users, list_present(socket))}
  end

  @impl true
  @doc """
  When an offer requested has been received, add it to the '@offer_request' list.
  """
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

  @impl true
  def handle_event("join_call", _params, socket) do
    for user <- socket.assigns.connected_users do
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

  @impl true
  def handle_event("validate", %{"game_options_changeset" => game_options_changeset}, socket) do
    IO.inspect game_options_changeset


    {:noreply, assign(socket, game_options_changeset: game_options_changeset)}
  end

  @impl true
  def handle_event("change_display_name", %{"new_name" => new_name}, socket) do
    socket
  end

  @impl true
  def handle_event("start_game", _payload, socket) do
    {:noreply,
    socket
    |> push_redirect(to: Routes.room_path(socket, :show, socket.assigns.slug))
    }
  end


  @spec list_present(
          atom
          | %{:assigns => atom | %{:slug => binary, optional(any) => any}, optional(any) => any}
        ) :: list
  def list_present(socket) do
    IO.inspect  Presence.list("room:" <> socket.assigns.slug)
    Presence.list("room:" <> socket.assigns.slug)
    |> Enum.map(fn {_, %{user: user, metas: _}} -> user.username
     end)
  end

  defp send_direct_message(slug, to_user, event, payload) do
    GameniteWeb.Endpoint.broadcast_from(
      self(),
      "room:" <> slug <> ":" <> to_user,
      event,
      payload
    )
  end

  defp mount_socket_user(socket, params) do
    user_id = Map.get(params, "user_id")
    user = GamenitePersistance.Accounts.get_user(user_id)
    socket
    |> assign(:user, user)
    user
  end
end
