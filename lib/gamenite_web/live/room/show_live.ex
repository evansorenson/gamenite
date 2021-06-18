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
    <h1><%= @room.title %></h1>
    <h3>Connected Users:</h3>
    <ul>
      <%= for username <- @connected_users do %>
        <li><%= username %></li>
      <% end %>
    </ul>

    <video id="local-video" playsinline autoplay muted width="500"></video>
    <button class="button" phx-hook="JoinCall">Join Call</button>
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
        }
    end
  end

  @impl true
  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply,
      socket
      |> assign(:connected_users, list_present(socket))}
  end

  def list_present(socket) do
    Presence.list("room:" <> socket.assigns.slug)
    |> Enum.map(fn {k, _} -> k end)
  end
end
