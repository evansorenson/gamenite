defmodule TeamTest do
  use ExUnit.Case
  use GameBuilders

  defp create_team(context) do
    {:ok, Map.put(context, :team, build_team(3, %{}))}
  end

  describe "new team constructor" do
    setup [:create_team]

    test "current player is first player", %{team: team} do
      assert team.current_player == List.first(team.players)
    end

    test "team name is generated properly", %{team: team} do
      assert team.name == "Team 1"
    end

    test "team color is choser properly", %{team: team} do
      assert team.color == :red
    end

    test "update team name", %{team: team} do
      new_name = "FeatherRufflers"
      team_with_new_name = Team.update_name(team, "FeatherRufflers")
      assert team_with_new_name.name == new_name
    end
  end
end
