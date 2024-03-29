defmodule GameBuilders do
  defmacro __using__(_options) do
    quote do
      alias Gamenite.TeamGame
      alias Gamenite.TeamGame.{Team, Player}
      import GameBuilders, only: :functions
    end
  end

  alias Gamenite.TeamGame.{Team, Player}
  alias Gamenite.TeamGame

  def build_game_changeset(number_of_players_on_each_team, player \\ %{}) do
    teams = build_teams(number_of_players_on_each_team, player)
    TeamGame.changeset(%TeamGame{}, %{teams: teams})
  end

  def build_game(number_of_players_on_each_team, player \\ %{}) do
    teams = build_teams(number_of_players_on_each_team, player)
    TeamGame.new(%{teams: teams})
  end

  def build_teams(number_of_players_on_each_team, player \\ %{}) do
    Enum.map(
      Enum.with_index(number_of_players_on_each_team), &build_team(&1, player))
  end

  def build_team({num_players, index}, player)do
    players = build_players(num_players, player)
    Team.new(%{players: players})
    |> Team.assign_color_and_index(index)
  end

  def build_players(num_players, player \\ %{}) do
    players = Enum.map(
      1..num_players,
      fn n -> Map.put(player, :id, n) end)
  end

  def build_deck(deck_length) do
    1..deck_length
  end
end
