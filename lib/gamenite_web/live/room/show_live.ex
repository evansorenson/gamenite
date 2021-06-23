defmodule GameniteWeb.Room.ShowLive do
  @moduledoc """
  A LiveView for creating and joining chat rooms
  """

  use GameniteWeb, :live_view

  alias Gamenite.Organizer
  alias Gamenite.Accounts.User

  alias GameniteWeb.Presence
  alias Phoenix.Socket.Broadcast

  @impl true
  def render(assigns) do
    ~L"""
    <style>
    .dot {
      height: 25px;
      width: 25px;
      background-color: #bbb;
      border-radius: 50%;
      display: inline-block;
    }
    </style>

    <h1><%= "Room: #{@room.title}" %></h1>

    <!--
    <div class="streams">
      <div class="video-container video-container--current">
        <video id="local-video" playsinline autoplay muted></video>
        <div class="video-container__controls">

          <button id="join-call" phx-click="join_call" phx-hook="JoinCall" class="video-container__control">Join Call<i class="fas fa-fw fa-phone"></i></button>
          <%= link to: Routes.room_new_path(@socket, :new), id: "leave-call", class: "video-container__control" do %>
            <i class="fas fa-fw fa-phone-slash"></i>
          <% end %>
      </div>

      <%= for username <- @connected_users do %>
        <div class="video-container">
          <video id="video-remote-<%= username %>" username="<%= username %>" playsinline autoplay phx-hook="InitUser"></video>
        </div>
        <% end %>
    </div>
    </div>
     -->

    <h1>Users</h1>
    <div class="row">
      <%= for i <- 0..8 do %>
        <div class="column">
          <%= case Enum.fetch(@connected_users, i) do %>
            <% {:ok, user} -> %>
              <div style="margin:0">
                <span class="dot" background-color="#www"></span>
              </div>
              <div>
                <%= user %>
              </div>
            <% _ -> %>
              <div style="margin:0">
                <span class="dot" background-color="#www"></span>
              </div>
           <% end %>
        </div>
      <% end %>
    </div>

    <div id="offer-requests">
      <%= for request <- @offer_requests do %>
        <span phx-hook="HandleOfferRequest" id="offer-request" data-from-username="<%= request.from_user.username %>"></span>
      <% end %>
    </div>

    <div id="sdp-offers">
      <%= for sdp_offer <- @sdp_offers do %>
        <span phx-hook="HandleSdpOffer" data-from-username="<%= sdp_offer["from_user"] %>" data-sdp="<%= sdp_offer["description"]["sdp"] %>"></span>
      <% end %>
    </div>

    <div id="sdp-answers">
      <%= for answer <- @answers do %>
        <span phx-hook="HandleAnswer" data-from-username="<%= answer["from_user"] %>" data-sdp="<%= answer["description"]["sdp"] %>"></span>
      <% end %>
    </div>

    <div id="ice-candidates">
      <%= for ice_candidate_offer <- @ice_candidate_offers do %>
        <span phx-hook="HandleIceCandidateOffer" data-from-username="<%= ice_candidate_offer["from_user"] %>" data-ice-candidate="<%= Jason.encode!(ice_candidate_offer["candidate"]) %>"></span>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    user = %User{username: "Guest#{:rand.uniform(1000000)}"}
        # This PubSub subscription will also handle other events from the users.
        Phoenix.PubSub.subscribe(Gamenite.PubSub, "room:" <> slug)

        # This PubSub subscription will allow the user to receive messages from
        # other users.
        Phoenix.PubSub.subscribe(Gamenite.PubSub, "room:" <> slug <> ":" <> user.username)

        # Track the connecting user with the `room:slug` topic.
        {:ok, _} = Presence.track(self(), "room:" <> slug, user.username, %{})

    case Organizer.get_room(slug) do
      nil ->
        {:ok,
          socket
          |> put_flash(:error, "That room does not exist.")
          |> push_redirect(to: Routes.room_new_path(socket, :new))
        }
      room ->
        {:ok,
          socket
          |> assign(:room, room)
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

  def list_present(socket) do
    Presence.list("room:" <> socket.assigns.slug)
    |> Enum.map(fn {k, _} -> k end)
  end

  defp send_direct_message(slug, to_user, event, payload) do
    GameniteWeb.Endpoint.broadcast_from(
      self(),
      "room:" <> slug <> ":" <> to_user,
      event,
      payload
    )
  end
end
