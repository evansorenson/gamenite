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
    {:ok, Map.put(context, :player_in_room, Roommate.new(%{user_id: 1}))}
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

    test "join room with password requires password", %{player_to_join: player} do
      password_room = Room.new(%{password: "123"})
      assert Rooms.join(password_room, player) == {:error, "Room requires password."}
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
end
