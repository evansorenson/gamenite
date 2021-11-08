defmodule GameniteWeb.RoomLive do
  @moduledoc """
  A LiveView for hosting games and managing social interactions.
  """
  use GameniteWeb, :live_view
  require Logger

  alias GameniteWeb.ParseHelpers
  alias Phoenix.PubSub
  alias Gamenite.Room
  alias Gamenite.Room.API
  alias GameniteWeb.LiveMonitor
  alias GameniteWeb.GameConfig
  alias Gamenite.GameServer

  alias Surface.Components.Dynamic
  alias Surface.Components.Form
  alias Surface.Components.Form.{Field, TextInput, Submit, Label, ErrorTag}
  alias GameniteWeb.Components.OptionsTable

  data(game, :map, default: nil)
  data(game_info, :map, default: nil)
  data(user, :map)
  data(slug, :string)
  data(roommates, :map)
  data(roommate, :map)

  @impl true
  def mount(%{"slug" => slug} = _params, session, socket) do
    user_id = mount_socket_user(socket, session)

    with true <- API.slug_exists?(slug) do
      {:ok,
       socket
       |> initialize_game(slug)
       |> assign(
         user_id: user_id,
         roommate_changeset: Room.change_roommate(),
         room: nil,
         slug: slug
       )}
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

  defp monitor_live_view_process(room_slug, user_id) do
    LiveMonitor.monitor(
      self(),
      __MODULE__,
      %{user_id: user_id, room_slug: room_slug}
    )
  end

  @doc """
  Callback that happens when the LV process is terminating.
  This allows the player to be removed from the game, and
  the entire game server process can also be terminated if
  there are no remaining players.
  """
  def unmount(_reason, %{user_id: user_id, room_slug: room_slug}) do
    Logger.info("Unmounting LiveView")
    API.leave(room_slug, user_id)
  end

  defp mount_socket_user(socket, params) do
    user_id = Map.get(params, "user_id")

    socket
    |> assign(:user_id, user_id)

    user_id
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

  defp build_roommate(roommate, socket) do
    roommate
    |> ParseHelpers.key_to_atom()
    |> Map.put(:id, socket.assigns.user_id)
  end

  def handle_event("validate_roommate", %{"roommate" => roommate}, socket) do
    roommate_changeset =
      roommate
      |> build_roommate(socket)
      |> Room.change_roommate()
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, roommate_changeset: roommate_changeset)}
  end

  def handle_event("join_room", %{"roommate" => roommate}, socket) do
    new_roommate =
      roommate
      |> build_roommate(socket)

    with {:ok, roommate} <-
           Room.create_roommate(new_roommate),
         {:ok, room} <- API.join(socket.assigns.slug, roommate) do
      PubSub.subscribe(Gamenite.PubSub, "room:" <> socket.assigns.slug)
      monitor_live_view_process(socket.assigns.slug, socket.assigns.user_id)

      game_config = GameConfig.get_config(room.game_title)

      {:noreply,
       socket
       |> assign(
         room: room,
         game_title: room.game_title,
         game_config: game_config,
         roommate: roommate,
         roommates: room.roommates,
         message: Room.change_message()
       )}
    else
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  defp build_message(message, socket) do
    message
    |> ParseHelpers.key_to_atom()
    |> Map.put(:user_id, socket.assigns.user_id)
  end

  def handle_event("validate_message", %{"message" => message}, socket) do
    message_changeset =
      message
      |> build_message(socket)
      |> Room.change_message()
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(message: message_changeset)}
  end

  def handle_event("send", %{"message" => message}, socket) do
    created_message =
      message
      |> build_message(socket)
      |> Room.create_message()

    IO.inspect(created_message)

    case message
         |> build_message(socket)
         |> Room.create_message() do
      {:ok, created_message} ->
        API.send_message(socket.assigns.slug, created_message)
        |> room_response(assign(socket, message: Room.change_message()))

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not send message.")}
    end
  end

  def handle_event("mute", %{"user_id" => user_id}, socket) do
    API.invert_mute(
      socket.assigns.slug,
      Map.get(socket.assigns.room.roommates, user_id)
    )
    |> room_response(socket)
  end

  @impl true
  def handle_info({:room_update, room}, socket) do
    roommate = Map.get(room.roommates, socket.assigns.user_id)
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
