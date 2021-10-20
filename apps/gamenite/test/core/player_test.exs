defmodule Gamenite.PlayerTest do
  use ExUnit.Case
  use GameBuilders

  def build_valid_player(context) do
    player = GameBuilders.build_player("Johnny")
    {:ok, Map.put(context, :player, player)}
  end

  def invalid_short_name(context) do
    player = GameBuilders.build_player("X")
    {:ok, Map.put(context, :player, player)}
  end

  def invalid_long_name(context) do
    player = GameBuilders.build_player("11Char-Name")
    {:ok, Map.put(context, :player, player)}
  end

  describe "player constructor" do
    setup [:build_valid_player]

    test "player with valid name", %{player: player} do
      assert player.name == "Johnny"
    end
  end
end
