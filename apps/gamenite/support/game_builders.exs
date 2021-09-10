defmodule GameBuilders do
  defmacro __using__(_options) do
    quote do
      alias Gamenite.Core.TeamGame
      alias Gamenite.Core.TeamGame.{Team, Player, Turn}
      import GameBuilders, only: :functions
    end
  end

  alias Gamenite.Core.TeamGame.{Team, Player, Turn}
  alias Gamenite.Core.TeamGame

  def build_game(number_of_players_on_each_team \\ [3, 3]) do
    deck = build_deck()
    teams = build_teams(number_of_players_on_each_team)
    TeamGame.new(teams, deck)
  end


  def build_teams(number_of_players_on_each_team) do
    Enum.map(number_of_players_on_each_team, &build_team(&1))
  end

  def build_team(num_players \\ 4, team_number \\ 1)do
    players = Enum.map(1..num_players, fn n -> build_player("Player#{n}") end)
    {:ok, team } = Team.new(players, team_number)
    team
  end

  def build_player(name) do
    {:ok, player} = Player.new(%{name: name, user_id: 0})
    player
  end

  def build_deck(cards \\ 0..20) do
    Enum.map(cards, &%Gamenite.Core.Cards.Card{face: Integer.to_string(&1)})
  end
end
