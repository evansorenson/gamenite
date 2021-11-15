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
  alias Gamenite.Game.API, as: GameAPI

  alias Surface.Components.Dynamic
  alias Surface.Components.Form
  alias Surface.Components.Form.{Field, TextInput, Submit, Label, ErrorTag}
  alias GameniteWeb.Components.{Game, OptionsTable, Chat}

  data(game, :map, default: nil)
  data(game_info, :map, default: nil)
  data(user, :map)
  data(slug, :string)
  data(roommates, :map)
  data(roommate, :map)

  @impl true
  def mount(%{"slug" => slug} = _params, session, socket) do
    user_id = mount_socket_user(socket, session)

    with true <- API.slug_exists?(slug),
         room <- API.state(slug) do
      game_config = GameConfig.get_config(room.game_title)
      PubSub.subscribe(Gamenite.PubSub, "room:" <> slug)
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
        IO.puts("false")

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
    case API.join_if_previous_or_current(slug, user_id) do
      {:ok, roommate} ->
        monitor_live_view_process(slug, user_id)
        assign(socket, roommate: roommate)

      {:error, _reason} ->
        assign(socket, roommate: nil)
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
      GameAPI.game_exists?(slug) ->
        {:ok, game} = GameAPI.state(slug)
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
         :ok <- API.join(socket.assigns.slug, roommate) do
      monitor_live_view_process(socket.assigns.slug, socket.assigns.user_id)

      {:noreply,
       socket
       |> assign(roommate: roommate)}
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

    # send_update(OptionsTable, %{
    #   id: "options",
    #   roommates: room.roommates
    # })

    {:noreply, assign(socket, room: room, roommate: roommate)}
  end

  def handle_info({:game_update, game}, socket) do
    {:noreply,
     socket
     |> assign(game: game)}
  end
end
