defmodule Gamenite.Room do
  import Ecto.Changeset
  use Accessible

  alias Gamenite.Room.{Message, Roommate}

  defstruct slug: nil,
            name: nil,
            roommates: %{},
            messages: [],
            game_title: nil,
            game_in_progress?: false,
            chat_enabled?: true

  def new(attrs) do
    struct!(__MODULE__, attrs)
  end

  @max_room_size 8
  def join(%{roommates: roommates} = room, player)
      when map_size(roommates) >= @max_room_size do
    if Map.has_key?(roommates, player.id) do
      do_join(player, room)
    else
      {:error, "Room is full."}
    end
  end

  def join(%{roommates: %{}} = room, player) do
    player
    |> Map.put(:host?, true)
    |> do_join(room)
  end

  def join(room, player), do: do_join(player, room)

  defp do_join(%{id: id} = player, %{roommates: roommates} = room) do
    %{room | roommates: Map.put(roommates, id, player)}
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
    %{room | roommates: Map.delete(roommates, id)}
  end

  def create_roommate(attrs \\ %{}) do
    change_roommate(attrs)
    |> apply_action(:update)
  end

  def change_roommate(attrs \\ %{}) do
    %Roommate{}
    |> Roommate.changeset(attrs)
  end

  def new_roommate_from_user(%{id: id, username: username} = _user) do
    create_roommate(%{id: id, name: username})
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

  def send_message(room, message, id)
      when length(room.messages) == 100 do
    room
    |> Map.update!(
      :messages,
      &List.delete_at(&1, 99)
    )
    |> do_send_message(message, id)
  end

  def send_message(room, message, id), do: do_send_message(room, message, id)

  defp do_send_message(room, message, id) do
    roommate = Map.get(room.roommates, id)
    new_message = %{message | roommate: roommate}

    room
    |> Map.update!(
      :messages,
      fn messages -> [new_message | messages] end
    )
  end
end
