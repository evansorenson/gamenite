defmodule GameniteWeb.RoomLive do
  @moduledoc """
  A LiveView for hosting games and managing social interactions.
  """
  use GameniteWeb, :live_view
  require Logger

  alias GameniteWeb.ParseHelpers
  alias Phoenix.PubSub
  alias GamenitePersistance.Accounts
  alias Gamenite.Room
  alias Gamenite.Room.API
  alias GameniteWeb.LiveMonitor
  alias GameniteWeb.GameConfig
  alias Gamenite.GameServer

  alias Surface.Components.Dynamic.LiveComponent, as: DynamicLive
  alias Surface.Components.Dynamic.Component
  alias Surface.Components.Form
  alias Surface.Components.Form.{Field, ErrorTag, TextInput, Submit}

  data(game, :map, default: nil)
  data(game_info, :map, default: nil)
  data(user, :map)
  data(slug, :string)
  data(roommates, :map)
  data(roommate, :map)

  @impl true
  def mount(_params, %{"slug" => slug} = session, socket) do
    user = mount_socket_user(socket, session)

    if connected?(socket) do
      monitor_live_view_process(slug, user)

      PubSub.subscribe(Gamenite.PubSub, "room:" <> slug)
      PubSub.subscribe(Gamenite.PubSub, "room:" <> slug <> ":" <> user.id)
    end

    with true <- API.slug_exists?(slug),
         {:ok, roommate} <- Room.new_roommate_from_user(user),
         {:ok, room} <- API.join(slug, roommate) do
      game_config = GameConfig.get_config(room.game_title)

      {:ok,
       socket
       |> initialize_game(slug)
       |> assign(
         room: room,
         user: user,
         game_config: game_config,
         game_title: room.game_title,
         slug: slug,
         roommate: roommate,
         roommates: room.roommates,
         message: Room.change_message()
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
    API.leave(room_slug, user.id)
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

  defp initialize_game(socket, slug) do
    cond do
      GameServer.game_exists?(slug) ->
        {:ok, game} = GameServer.state(slug)
        assign(socket, game: game)

      true ->
        assign(socket, game: nil)
    end
  end

  def handle_event("validate", %{"message" => message}, socket) do
    message_changeset =
      message
      |> ParseHelpers.key_to_atom()
      |> Room.change_message()

    {:noreply,
     socket
     |> assign(message: message_changeset)}
  end

  def handle_event("send", %{"message" => message}, socket) do
    created_message =
      message
      |> ParseHelpers.key_to_atom()
      |> Room.create_message()

    case created_message do
      {:ok, message} ->
        API.send_message(socket.assigns.room.slug, message, socket.assigns.user.id)
        |> room_response(assign(socket, message: Room.change_message()))

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not send message.")}
    end
  end

  def handle_event("mute", %{"user_id" => user_id}, socket) do
    API.invert_mute(
      socket.assigns.room.slug,
      Map.get(socket.assigns.room.roommates, user_id)
    )
    |> room_response(socket)
  end

  @impl true
  def handle_info({:room_update, room}, socket) do
    roommate = Map.get(room.roommates, socket.assigns.user.id)
    {:noreply, assign(socket, room: room, roommates: room.roommates, roommate: roommate)}
  end

  def handle_info({:game_changeset_update, game_changeset}, socket) do
    send_update(self(), GameniteWeb.GameLive, %{
      id: socket.assigns.game_title,
      game_changeset: game_changeset
    })

    {:noreply, socket}
  end

  def handle_info({:game_update, game}, socket) do
    {:noreply,
     socket
     |> assign(game: game)}
  end
end
