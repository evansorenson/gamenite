defmodule Gamenite.RoomsTest do
  use ExUnit.Case
  alias Rooms.{Room, Roommate}

  def build_room(num_players) do
    players =
      for i <- 1..num_players, reduce: %{} do
        acc ->
          id = Ecto.UUID.generate()

          Map.put_new(
            acc,
            id,
            Room.create_roommate(%{id: id, name: "Player #{i}"})
            |> elem(1)
          )
      end

    Room.new(%{roommates: players})
  end

  def build_empty_room(context) do
    empty_room = Room.new(%{})
    {:ok, Map.put(context, :empty_room, empty_room)}
  end

  def build_room_with_some(context) do
    some_room = build_room(4)
    {player_id_in_room, player_in_room} = hd(Map.to_list(some_room.roommates))

    {:ok,
     context
     |> Map.put(:some_room, some_room)
     |> Map.put(:player_id_in_room, player_id_in_room)
     |> Map.put(:player_in_room, player_in_room)}
  end

  def build_full_room(context) do
    full_room = build_room(8)
    {:ok, Map.put(context, :full_room, full_room)}
  end

  def player_to_join(context) do
    {:ok,
     Map.put(
       context,
       :player_to_join,
       Room.create_roommate(%{id: Ecto.UUID.generate(), name: "Player 99"}) |> elem(1)
     )}
  end

  def build_message(context) do
    {:ok,
     Map.put(
       context,
       :message,
       Room.create_message(%{roommate: %{}, body: "hello world!"}) |> elem(1)
     )}
  end

  def some_messages(context) do
    messages =
      for i <- 1..10 do
        i
      end

    room = %{build_room(4) | messages: messages}
    {:ok, Map.put(context, :some_messages, room)}
  end

  def full_messages(context) do
    messages =
      for i <- 1..100 do
        i
      end

    room = %{build_room(4) | messages: messages}
    {:ok, Map.put(context, :full_messages, room)}
  end

  describe "players joining room" do
    setup [
      :build_empty_room,
      :build_room_with_some,
      :build_full_room,
      :player_to_join
    ]

    test "join empty room and make player host", %{
      empty_room: empty_room,
      player_to_join: player
    } do
      new_room =
        empty_room
        |> Room.join(player)
        |> assert_connected(player.id)
        |> assert_roommates_length(1)

      assert Map.get(new_room.roommates, player.id).host? == true
    end

    test "reassign host when current host leaves", %{some_room: some_room, player_to_join: player} do
    end

    test "join full room and get error", %{full_room: full_room, player_to_join: player} do
      assert {:error, "Room is full."} == Room.join(full_room, player)
    end

    test "player already in room and tries to join", %{
      some_room: some_room,
      player_in_room: player
    } do
      some_room
      |> Room.join(player)
      |> assert_connected(player.id)
      |> assert_roommates_length(4)
    end

    test "player joins successfully", %{some_room: some_room, player_to_join: player} do
      some_room
      |> Room.join(player)
      |> assert_connected(player.id)
      |> assert_roommates_length(5)
    end
  end

  defp refute_connected(room, player_id) do
    refute Map.get(room.roommates, player_id).connected?
    room
  end

  defp assert_connected(room, player_id) do
    assert Map.get(room.roommates, player_id).connected?
    room
  end

  defp assert_roommates_length(room, length) do
    assert map_size(room.roommates) == length
    room
  end

  describe "player leaving room" do
    setup [:build_room_with_some]

    test "player leaving room when game not in progress, removes player", %{
      some_room: some_room,
      player_id_in_room: player_id
    } do
      some_room
      |> Room.leave(player_id)
      |> assert_roommates_length(3)
    end

    test "player leaving room when game in progress, sets player status to disconnected", %{
      some_room: some_room,
      player_id_in_room: player_id
    } do
      %{some_room | game_in_progress?: true}
      |> Room.leave(player_id)
      |> refute_connected(player_id)
      |> assert_roommates_length(4)
    end

    test "player leaves and joins, when game is started", %{
      some_room: some_room,
      player_id_in_room: player_id,
      player_in_room: player
    } do
      %{some_room | game_in_progress?: true}
      |> Room.leave(player_id)
      |> refute_connected(player_id)
      |> Room.join(player)
      |> assert_connected(player_id)
    end
  end

  describe "muting/unmuting players" do
    setup [:build_room_with_some]

    test "mute unmuted player", %{some_room: some_room, player_in_room: player} do
      some_room
      |> Room.invert_mute(player)
      |> assert_mute_status(player, true)
    end

    test "unmute muted player", %{some_room: some_room, player_in_room: player} do
      some_room
      |> Room.invert_mute(%{player | muted?: true})
      |> assert_mute_status(player, false)
    end

    test "unmute all players", %{some_room: some_room} do
      some_room
      |> Room.unmute_all()
      |> assert_unmute_all
    end

    test "mute all players except host", %{some_room: some_room, player_in_room: host} do
      some_room
      |> Room.mute_all(host)
      |> assert_mute_all
    end

    defp assert_mute_status(
           %{roommates: roommates} = room,
           %{id: id} = _player,
           muted?
         ) do
      player = Map.get(roommates, id)
      assert player.muted? == muted?
      room
    end

    defp assert_unmute_all(room) do
      for {_k, user} <- room.roommates do
        assert_mute_status(room, user, false)
      end
    end

    defp assert_mute_all(room) do
      for {_k, user} <- room.roommates do
        do_assert_mute_all(room, user)
      end

      room
    end

    defp do_assert_mute_all(room, %{host?: false} = player) do
      assert_mute_status(room, player, true)
    end

    defp do_assert_mute_all(room, player) do
      assert_mute_status(room, player, false)
    end
  end

  describe "messaging" do
    setup [:build_message, :build_room_with_some, :some_messages, :full_messages]

    test "message with empty body is invalid" do
    end

    test "message with body over 500 characters is invalid" do
    end

    test "valid message" do
    end

    test "roommate required" do
    end

    test "sent datetime required" do
    end

    test "send message in empty chat", %{message: message, some_room: room} do
      room
      |> Room.send_message(message)
      |> assert_message_sent(message)
    end

    test "send message with some chat", %{message: message, some_messages: room} do
      room
      |> Room.send_message(message)
      |> assert_message_sent(message)
    end

    test "send message with message capacity full, deletes earliest message", %{
      message: message,
      full_messages: room
    } do
      new_room =
        room
        |> Room.send_message(message)
        |> assert_message_sent(message)

      assert length(new_room.messages) == 100
      assert Enum.at(new_room.messages, 99) == 99
    end

    defp assert_message_sent(room, message) do
      assert hd(room.messages) == message
      room
    end
  end
end
