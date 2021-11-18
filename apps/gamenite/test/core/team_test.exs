defmodule TeamTest do
  use ExUnit.Case
  use GameBuilders

  defp create_team(context) do
    {:ok, Map.put(context, :team, build_team({3, 0}, %{}))}
  end

  describe "new team constructor" do
    setup [:create_team]

    test "current player is first player", %{team: team} do
      assert team.current_player == List.first(team.players)
    end

    test "team color is chosen properly", %{team: team} do
      assert team.color == "#C0392B"
    end
  end
end
