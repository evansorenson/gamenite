defmodule Gamenite.TeamGame do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset

  alias Gamenite.Lists

  alias Gamenite.TeamGame.{Turn, Team}

  embedded_schema do
    field :title, :string
    field :room_id, :string
    field :current_turn, :map
    field :options, :map
    field :is_finished, :boolean, default: false
    embeds_one :current_team, Team
    embeds_many :teams, Team
  end
  @fields [:current_turn, :title]

  @max_teams Application.get_env(:gamenite, :max_teams)
  def finalize_game_changeset(team_game, %{teams: teams} = fields) do
    team_game
    |> cast(fields, @fields)
    |> put_embed(:teams, teams)
    |> put_embed(:current_team, hd(teams))
    |> put(:current_turn, Turn.new(hd(teams).current_player))
    |> validate_required([:teams, :options, :current_team, :current_turn, :title])
    |> validate_length(:teams, min: 2, max: @max_teams)
  end

  def teams_changeset(team_game, fields) do
    team_game
    |> cast(fields, @fields)
    |> cast_embed(:teams)
    |> validate_required([:teams])
    |> validate_length(:teams, min: 2, max: @max_teams)
  end
  def new(teams, options) do
    %__MODULE__{}
    |> finalize_game_changeset(%{teams: teams, options: options})
    |> apply_action(:update)
  end


  def end_turn(game) do
    game
    |> append_turn_to_team
    |> inc_player
    |> inc_team
    |> new_turn
  end

  defp append_turn_to_team(%__MODULE__{ current_team: current_team, current_turn: current_turn } = game) do
    game
    |> replace_current_team(Team.add_turn(current_team, current_turn))
  end

  defp inc_player(%__MODULE__{ current_team: current_team } = game) do
    update_current_item_and_increment_list(
      game,
      current_team.players,
      current_team.current_player,
      &update_player/2,
      &replace_current_player/2)
  end

  defp inc_team(%__MODULE__{ teams: teams, current_team: current_team } = game) do
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

  defp update_team(%__MODULE__{ teams: teams } = game, team) do
    team_index = Lists.find_element_index_by_id(teams, team.id)

    game
    |> put_in([:teams, Access.at(team_index)], team)
  end

  defp replace_current_team(game, next_team) do
    game
    |> Map.replace!(:current_team, next_team)
  end

  defp update_player(%{ current_team: current_team } = game, player) do
    player_index = Lists.find_element_index_by_id(current_team.players, current_team.current_player.id)

    game
    |> put_in([:current_team, :players, Access.at(player_index)], player)
  end

  def replace_current_player(game, next_player) do
    game
    |> put_in([:current_team, :current_player], next_player)
  end

  def new_turn(%__MODULE__{ current_team: current_team } = game) do
    turn = Turn.new(current_team.current_player)

    game
    |> Map.replace!(:current_turn, turn)
  end

  @doc """
  Adds player to either team with lowest number of players or if no teams, to list of players.

  Returns %__MODULE__{}.
  """
  def add_player( %__MODULE__{ teams: teams } = game, player) do
    team_with_lowest_players(teams)
    |> _add_player(game, player)
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

  def start_turn(%__MODULE__{ current_turn: current_turn } = game) do
    game
    |> put_in(current_turn.started_at, DateTime.utc_now())
  end
end
