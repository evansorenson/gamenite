defmodule Gamenite.TeamGame do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset

  alias Gamenite.Lists
  alias Gamenite.TeamGame.Team

  @max_teams Application.get_env(:gamenite, :max_teams)
  def changeset(team_game, %{teams: teams} = fields) do
    current_team = hd(teams)
    current_player = hd(current_team.players)

    team_game
    |> Map.put(:current_team, current_team)
    |> Map.put(:current_player, current_player)
    |> cast(fields, [])
    |> cast_embed(:teams)
    |> cast_embed(:current_team)
    |> cast_embed(:current_player)
    |> validate_required([:teams, :current_team, :current_player])
    |> validate_length(:teams, min: 2, max: @max_teams)
  end

  def end_turn(game, turn_constructor) do
    game
    |> append_turn_to_team
    |> inc_player
    |> inc_team
    |> new_turn(turn_constructor)
  end

  defp append_turn_to_team(%{ current_team: current_team, current_turn: current_turn } = game) do
    game
    |> replace_current_team(Team.add_turn(current_team, current_turn))
  end

  defp inc_player(%{ current_team: current_team, current_player: current_player } = game) do
    update_current_item_and_increment_list(
      game,
      current_team.players,
      current_player,
      &update_player/2,
      &replace_current_player/2)
  end

  defp inc_team(%{ teams: teams, current_team: current_team } = game) do
    update_current_item_and_increment_list(
      game,
      teams,
      current_team,
      &update_team/2,
      &replace_current_team/2)
  end

  defp update_current_item_and_increment_list(game, list, current_item, update_func, replace_func) do
    next_element = Lists.next_list_element_by_id(list, current_item.id)

    game
    |> update_func.(current_item)
    |> replace_func.(next_element)
  end

  defp update_team(%{ teams: teams } = game, team) do
    team_index = Lists.find_element_index_by_id(teams, team.id)

    game
    |> put_in([:teams, Access.at(team_index)], team)
  end

  defp replace_current_team(game, next_team) do
    game
    |> Map.replace!(:current_team, next_team)
  end

  defp update_player(%{ current_team: current_team, current_player: current_player } = game, player) do
    player_index = Lists.find_element_index_by_id(current_team.players, current_player.id)

    game
    |> put_in([:current_team, :players, Access.at(player_index)], player)
  end

  def replace_current_player(game, next_player) do
    game
    |> Map.put(:current_player, next_player)
  end

  def new_turn(%{ current_player: current_player } = game, turn_constructor) do
    turn = turn_constructor.(current_player)

    game
    |> Map.replace!(:current_turn, turn)
  end

  @doc """
  Adds player to either team with lowest number of players or if no teams, to list of players.

  Returns game struct.
  """
  def add_player( %{ teams: teams } = game, player) do
    if player_exists?(game, player) do
       {:error, "Player is already in game."}
    else
      team_with_lowest_players(teams)
      |> _add_player(game, player)
    end
  end

  defp _add_player(team, %{ current_team: current_team } = game, player) when current_team.id == team.id do
    added_team = Team.add_player(current_team, player)

    game
    |> update_team(added_team)
    |> replace_current_team(added_team)
  end
  defp _add_player(team, game, player) do
    added_team = Team.add_player(team, player)

    game
    |> update_team(added_team)
  end

  defp team_with_lowest_players(teams) do
    teams
    |> Enum.sort_by(fn team -> length(team.players) end, :asc)
    |> List.first()
  end

  defp player_exists?(%{teams: teams} = _game, player) do
    teams
    |> Enum.flat_map(fn team -> team.players end)
    |> Enum.any?(fn current_player -> current_player.id == player.id end)
  end

  def start_turn(%{ current_turn: current_turn } = game) do
    game
    |> put_in(current_turn.started_at, DateTime.utc_now())
  end

  def on_current_team?(%{current_team: current_team} = _game, id) do
    Enum.any?(current_team.players, fn player -> player.id == id end)
  end

  def current_player?(%{current_player: current_player} = _game, id) do
    current_player.id == id
  end
end
