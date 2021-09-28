defmodule Gamenite.RoomsTest do
  use ExUnit.Case
  alias Gamenite.Rooms.{Room, Roommate}
  alias Gamenite.Rooms

  def build_empty_room(context) do
    empty_room = Room.new(%{})
    {:ok, Map.put(context, :empty_room, empty_room)}
  end

  def build_room_with_some(context) do
    players = for i <- 1..4, reduce: %{} do
      acc -> Map.put_new(acc, i, Roommate.new(%{user_id: i}))
    end
    some_room = Room.new(%{connected_users: players})

    {:ok, Map.put(context, :some_room, some_room)}
  end

  def build_full_room(context) do
    players = for i <- 1..8, reduce: %{} do
      acc -> Map.put_new(acc, i, Roommate.new(%{user_id: i}))
    end
    full_room = Room.new(%{connected_users: players})

    {:ok, Map.put(context, :full_room, full_room)}
  end

  def player_to_join(context) do
    {:ok, Map.put(context, :player_to_join, Roommate.new(%{user_id: 123454}))}
  end

  def player_in_room(context) do
    {:ok, Map.put(context, :player_in_room, Roommate.new(%{user_id: 1, host?: true}))}
  end

  describe "players joining room" do
    setup [:build_empty_room, :build_room_with_some, :build_full_room, :player_to_join, :player_in_room]

    test "join empty room and make player host", %{empty_room: empty_room, player_to_join: player} do
      new_room = empty_room
      |> Rooms.join(player)

      assert map_size(new_room.connected_users) == 1
      assert Map.get(new_room.connected_users, player.user_id).host? == true
    end

    test "join full room and get error", %{full_room: full_room, player_to_join: player} do
      assert {:error, "Room is full."} == Rooms.join(full_room, player)
    end

    test "player already in room and tries to join", %{some_room: some_room, player_in_room: player} do
      new_room = some_room
      |> Rooms.join(player)

      assert map_size(new_room.connected_users) == 4
    end

    test "player joins successfully", %{some_room: some_room, player_to_join: player} do
      new_room = some_room
      |> Rooms.join(player)

      assert map_size(new_room.connected_users) == 5
    end
  end

  describe "player leaving room" do
    setup [:build_room_with_some, :player_in_room]

    test "player leaves room successfully", %{some_room: some_room, player_in_room: player} do
      new_room = some_room
      |> Rooms.leave(player)

      assert map_size(new_room.connected_users) == 3
    end
  end

  describe "muting/unmuting players" do
    setup [:build_room_with_some, :player_in_room]

    test "mute unmuted player",  %{some_room: some_room, player_in_room: player} do
      some_room
      |> Rooms.invert_mute(player)
      |> assert_mute_status(player, true)
    end

    test "unmute muted player", %{some_room: some_room, player_in_room: player} do
      some_room
      |> Rooms.invert_mute(%{ player | muted?: true})
      |> assert_mute_status(player, false)
    end

    test "unmute all players", %{some_room: some_room } do
      some_room
      |> Rooms.unmute_all
      |> assert_unmute_all
    end

    test "mute all players except host", %{some_room: some_room, player_in_room: host} do
      some_room
      |> Rooms.mute_all(host)
      |> assert_mute_all
    end

    defp assert_mute_status(%{connected_users: connected_users} = room, %{user_id: id} = _player, muted?) do
      player = Map.get(connected_users, id)
      assert player.muted? == muted?
      room
    end

    defp assert_unmute_all(room) do
      for {_k, user} <- room.connected_users do
        assert_mute_status(room, user, false)
      end
    end

    defp assert_mute_all(room) do
      for {_k, user} <- room.connected_users do
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
end
