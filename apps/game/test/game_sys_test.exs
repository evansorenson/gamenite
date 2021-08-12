defmodule GameSysTest do
  use ExUnit.Case
  doctest GameSys

  test "greets the world" do
    assert GameSys.hello() == :world
  end
end
