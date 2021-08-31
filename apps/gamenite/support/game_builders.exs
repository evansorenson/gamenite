defmodule GameBuilders do
  defmacro __using__(_options) do
    quote do
      alias Gamenite.Core.{TeamGame, Team, Player, PartyTurn}
      import GameBuilders, only: :functions
    end
  end

  alias Gameplay.{TeamGame, Team, Player, PartyTurn}

  def build_game(number_of_players_on_each_team \\ [3, 3]) do
    teams = build_teams(number_of_players_on_each_team)
    deck = build_deck()
    TeamGame.new(teams %{ deck: deck })
  end


  def build_teams(number_of_players_on_each_team) do
    Enum.map(number_of_players_on_each_team, &build_team(&1))
  end

  def build_team(num_players \\ 4, team_number \\ 1)do
    players = Enum.map(1..num_players, fn player -> build_player(player) end)
    Team.new(players, team_number)
  end

  def build_player(name) do
    %Player{ name: name }
  end

  def build_deck(cards \\ 0..20) do
    Enum.map(cards, &%Gamenite.Cards.Card{face: Integer.to_string(&1)})
  end
end
