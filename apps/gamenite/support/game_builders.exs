defmodule GameBuilders do
  defmacro __using__(_options) do
    quote do
      alias Gamenite.TeamGame
      alias Gamenite.TeamGame.{Team, Player}
      import GameBuilders, only: :functions
      use GamenitePersistance.DataCase
    end
  end

  alias Gamenite.TeamGame.{Team, Player}
  alias Gamenite.TeamGame

  def build_game_changeset(number_of_players_on_each_team \\ [3, 3]) do
    teams = build_teams(number_of_players_on_each_team)
    TeamGame.changeset(%TeamGame{}, %{teams: teams})
  end

  def build_game(number_of_players_on_each_team \\ [3, 3]) do
    teams = build_teams(number_of_players_on_each_team)
    TeamGame.new(%{teams: teams})
  end

  def build_teams(number_of_players_on_each_team) do
    Enum.map(number_of_players_on_each_team, &build_team(&1))
  end

  def build_team(num_players \\ 4, team_number \\ 1)do
    Enum.map(1..num_players, fn n -> build_player("Player#{n}") end)
    |> Team.new(team_number)
  end

  def build_player(name) do
    {:ok, player} = Player.new(%{name: name, user_id: 0, color: "something"})
    player
  end

  def build_deck(deck_length) do
    Enum.map(1..deck_length, &%Gamenite.Cards.Card{face: Integer.to_string(&1)})
  end
end
