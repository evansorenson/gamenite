defmodule TeamTest do
  use ExUnit.Case
  use GameBuilders

  describe "new team" do
    test "id is not nil", %{team: team} do
      assert not is_nil(team.id)
    end

    test "current player is first player", %{team: team} do
      assert team.current_player == List.first(team.players)
    end

    test "team name is generated properly", %{team: team} do
      assert team.name == "Team 1"
    end

    test "team color is choser properly", %{team: team} do
      assert team.color == :red
    end
  end

  test "update team name", %{team: team} do
    new_name = "FeatherRufflers"
    team_with_new_name = Team.update_name(team, "FeatherRufflers")
    assert team.name == new_name
  end
end
