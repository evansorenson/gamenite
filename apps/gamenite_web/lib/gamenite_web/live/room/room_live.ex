defmodule GameniteWeb.RoomLive do
  @moduledoc """
  A LiveView for hosting games and managing social interactions.
  """
  use GameniteWeb, :live_view
  require Logger

  alias GameniteWeb.ParseHelpers
  alias Phoenix.PubSub
  alias Rooms.Room
  alias Rooms
  alias GameniteWeb.LiveMonitor
  alias GameniteWeb.GameConfig
  alias Gamenite.Game.API, as: GameAPI

  alias Surface.Components.Dynamic
  alias Surface.Components.Form
  alias Surface.Components.Form.{Field, TextInput, Submit, Label, ErrorTag}
  alias GameniteWeb.Components.{Game, OptionsTable, Chat, ConnectedUsers}

  data game, :map, default: nil
  data game_info, :map, default: nil
  data user, :map
  data slug, :string
  data roommates, :map
  data joined?, :boolean, default: false

  @impl true
  def mount(%{"slug" => slug} = _params, session, socket) do
    user_id = mount_socket_user(socket, session)

    with true <- Rooms.slug_exists?(slug),
         room <- Rooms.state(slug) do
      game_config = GameConfig.get_config(room.game_title)
      PubSub.subscribe(Rooms.PubSub, "room:" <> slug)
      PubSub.subscribe(Gamenite.PubSub, "game:" <> slug)

      {:ok,
       socket
       |> initialize_game(slug)
       |> join_room_if_previous_or_current_roommate(slug, user_id)
       |> assign(
         user_id: user_id,
         room: room,
         game_title: room.game_title,
         game_config: game_config,
         roommate_changeset: Room.change_roommate(),
         slug: slug,
         message: Room.change_message()
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

  defp join_room_if_previous_or_current_roommate(socket, slug, user_id) do
    case Rooms.join_if_previous_or_current(slug, user_id) do
      :ok ->
        joined_room(socket, slug, user_id)

      {:error, _reason} ->
        socket
    end
  end

  defp monitor_live_view_process(room_slug, user_id) do
    LiveMonitor.monitor(
      self(),
      __MODULE__,
      %{user_id: user_id, room_slug: room_slug}
    )
  end

  defp joined_room(socket, slug, user_id) do
    monitor_live_view_process(slug, user_id)

    socket
    |> assign(joined?: true)
    |> push_event("joined_room", %{user_id: user_id, slug: slug})
  end

  @doc """
  Callback that happens when the LV process is terminating.
  This allows the player to be removed from the game, and
  the entire game server process can also be terminated if
  there are no remaining players.
  """
  def unmount(_reason, %{user_id: user_id, room_slug: room_slug}) do
    Logger.info("Unmounting LiveView")
    :ok = Rooms.leave(room_slug, user_id)
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
      GameAPI.game_exists?(slug) ->
        {:ok, game} = GameAPI.state(slug)
        assign(socket, game: game)

      true ->
        assign(socket, game: nil)
    end
  end

  def handle_event("validate_roommate", %{"roommate" => roommate}, socket) do
    roommate_changeset =
      roommate
      |> Room.change_roommate()
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, roommate_changeset: roommate_changeset)}
  end

  def handle_event("join_room", %{"roommate" => roommate}, socket) do
    with {:ok, new_roommate} <-
           Room.create_roommate(roommate),
         :ok <- Rooms.join(socket.assigns.slug, new_roommate) do
      {:noreply, joined_room(socket, socket.assigns.slug, socket.assigns.user_id)}
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

    case message
         |> build_message(socket)
         |> Room.create_message() do
      {:ok, created_message} ->
        Rooms.send_message(socket.assigns.slug, created_message)
        |> room_response(assign(socket, message: Room.change_message()))

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not send message.")}
    end
  end

  def handle_event("mute", %{"user_id" => user_id}, socket) do
    Rooms.invert_mute(
      socket.assigns.slug,
      Map.get(socket.assigns.room.roommates, user_id)
    )
    |> room_response(socket)
  end

  @impl true
  def handle_info({:room_update, room}, socket) do
    # send_update(OptionsTable, %{
    #   id: "options",
    #   roommates: room.roommates
    # })

    {:noreply, assign(socket, room: room)}
  end

  def handle_info({:game_update, game}, socket) do
    {:noreply,
     socket
     |> assign(game: game)}
  end
end
