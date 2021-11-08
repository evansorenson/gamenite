defmodule Gamenite.Room do
  import Ecto.Changeset
  use Accessible

  alias Gamenite.Room.{Message, Roommate}

  defstruct slug: nil,
            name: nil,
            roommates: %{},
            previous_roommates: %{},
            messages: [],
            game_title: nil,
            game_in_progress?: false,
            chat_enabled?: true

  def new(attrs) do
    struct!(__MODULE__, attrs)
  end

  def join_if_previous_or_current(%{previous_roommates: previous_roommates} = room, user_id)
      when is_map_key(previous_roommates, user_id) do
    {roommate_to_join, new_previous_roommates} = Map.pop!(previous_roommates, user_id)

    join(
      %{room | previous_roommates: new_previous_roommates},
      roommate_to_join
    )
  end

  def join_if_previous_or_current(%{roommates: roommates} = room, user_id)
      when is_map_key(roommates, user_id) do
    Map.fetch!(roommates, user_id)
    |> do_join(room)
  end

  def join_if_previous_or_current(_room, _user_id),
    do: {:error, "User not previously or currently in room."}

  @max_room_size 8
  def join(%{roommates: roommates} = room, roommate)
      when map_size(roommates) >= @max_room_size do
    if Map.has_key?(roommates, roommate.id) do
      do_join(roommate, room)
    else
      {:error, "Room is full."}
    end
  end

  def join(%{roommates: %{}} = room, roommate) do
    roommate
    |> Map.put(:host?, true)
    |> do_join(room)
  end

  def join(room, roommate), do: do_join(roommate, room)

  defp do_join(%{id: id} = roommate, %{roommates: roommates} = room) do
    %{room | roommates: Map.put(roommates, id, roommate)}
  end

  def leave(%{roommates: roommates, game_in_progress?: true} = room, id) do
    new_roommates =
      Map.update!(
        roommates,
        id,
        fn roommate -> %{roommate | connected?: false} end
      )

    %{room | roommates: new_roommates}
  end

  def leave(%{roommates: roommates} = room, id) do
    {roommate_leaving, new_roommates} = Map.pop!(roommates, id)

    room
    |> Map.put(:roommates, new_roommates)
    |> Map.update!(:previous_roommates, fn prev_roommates ->
      Map.put(prev_roommates, roommate_leaving.id, roommate_leaving)
    end)
  end

  def create_roommate(attrs \\ %{}) do
    change_roommate(attrs)
    |> apply_action(:update)
  end

  def change_roommate(attrs \\ %{}) do
    %Roommate{}
    |> Roommate.changeset(attrs)
  end

  def fetch_roommate_or_previous_roommate(%{roommates: roommates} = _room, user_id)
      when is_map_key(roommates, user_id) do
    Map.fetch!(roommates, user_id)
  end

  def fetch_roommate_or_previous_roommate(
        %{previous_roommates: previous_roommates} = _room,
        user_id
      )
      when is_map_key(previous_roommates, user_id) do
    Map.fetch!(previous_roommates, user_id)
  end

  def invert_mute(room, %{muted?: muted?} = player) do
    do_mute(room, player, not muted?)
  end

  def mute_all(room, host_player) do
    do_mute_all(room, true)
    |> do_mute(host_player, false)
  end

  def unmute_all(room) do
    do_mute_all(room, false)
  end

  defp do_mute(%{roommates: roommates} = room, %{id: id} = player, mute?) do
    roommates = Map.put(roommates, id, %{player | muted?: mute?})

    room
    |> Map.put(:roommates, roommates)
  end

  defp do_mute_all(%{roommates: roommates} = room, mute?) do
    users =
      for {k, v} <- roommates, into: %{} do
        {k, %{v | muted?: mute?}}
      end

    %{room | roommates: users}
  end

  def set_game(room, game_title) do
    room
    |> Map.put(:game_title, game_title)
  end

  def change_message(attrs \\ %{}) do
    sent_at = DateTime.utc_now()

    %Message{}
    |> Message.changeset(Map.put(attrs, :sent_at, sent_at))
  end

  def create_message(attrs \\ %{}) do
    change_message(attrs)
    |> apply_action(:update)
  end

  def send_message(room, message)
      when length(room.messages) == 100 do
    room
    |> Map.update!(
      :messages,
      &List.delete_at(&1, 99)
    )
    |> do_send_message(message)
  end

  def send_message(room, message), do: do_send_message(room, message)

  defp do_send_message(room, message) do
    room
    |> Map.update!(
      :messages,
      fn messages -> [message | messages] end
    )
  end
end
