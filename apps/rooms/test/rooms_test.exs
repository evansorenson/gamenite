defmodule RoomsTest do
  use ExUnit.Case
  doctest Rooms

  test "greets the world" do
    assert Rooms.hello() == :world
  end
end
