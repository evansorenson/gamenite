defmodule Gamenite.TeamGame do
  use Ecto.Schema
  import Ecto.Changeset

  alias Gamenite.Lists
  alias Gamenite.TeamGame.Team

  embedded_schema do
    field(:current_turn, :map)
    embeds_one(:current_team, Team)
    embeds_many(:teams, Team)
  end

  @max_teams Application.get_env(:gamenite, :max_teams)
  def changeset(team_game, %{teams: teams} = params) when length(teams) > 0 do
    team_changeset(team_game, Map.put(params, :current_team, hd(teams)))
  end

  def changeset(team_game, params) do
    team_changeset(team_game, params)
  end

  def team_changeset(team_game, params) do
    team_game
    |> cast(params, [])
    |> cast_embed(:current_team)
    |> cast_embed(:teams)
    |> validate_required([:teams, :current_team])
    |> validate_length(:teams, min: 2, max: @max_teams)
  end

  def new(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action(:update)
  end

  def end_turn(game) do
    game
    |> append_turn_to_team
    |> inc_player
    |> next_team
  end

  defp append_turn_to_team(%{current_team: current_team, current_turn: current_turn} = game) do
    game
    |> replace_current_team(Team.add_turn(current_team, current_turn))
  end

  defp inc_player(game) do
    Lists.update_current_item_and_increment_list(
      game,
      [:current_team, :players],
      [:current_team, :current_player]
    )
  end

  def next_team(game) do
    Lists.update_current_item_and_increment_list(
      game,
      [:teams],
      [:current_team]
    )
  end

  def update_team(%{teams: teams} = game, team) do
    new_teams = Lists.replace_element_by_id(teams, team)
    %{game | teams: new_teams}
  end

  def replace_current_team(game, next_team) do
    game
    |> Map.replace!(:current_team, next_team)
  end

  def new_turn(game, turn) do
    game
    |> Map.replace!(:current_turn, turn)
  end

  @doc """
  Adds player to either team with lowest number of players or if no teams, to list of players.

  Returns game struct.
  """
  def add_player(%{teams: teams} = game, player) do
    if player_exists?(game, player) do
      {:error, "Player is already in game."}
    else
      team_with_lowest_players(teams)
      |> _add_player(game, player)
    end
  end

  defp _add_player(team, %{current_team: current_team} = game, player)
       when current_team.id == team.id do
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
    |> Enum.any?(fn team_player -> team_player.id == player.id end)
  end

  def start_turn(%{current_turn: current_turn} = game) do
    game
    |> put_in(current_turn.started_at, DateTime.utc_now())
  end

  def on_current_team?(%{current_team: current_team} = _game, id) do
    Enum.any?(current_team.players, fn player -> player.id == id end)
  end

  def current_player?(%{current_team: current_team} = _game, id) do
    current_team.current_player.id == id
  end

  def add_score(game, score) do
    game
    |> update_in([:current_team, :score], &(&1 + score))
  end

  def split_teams(players, n) do
    _split_teams([], Enum.shuffle(players), n)
  end

  defp _split_teams(teams, players, 1 = n) do
    team =
      Team.new(%{players: players, name: "Team #{n}"})
      |> Team.assign_color_and_index(n - 1)

    [team | teams]
  end

  defp _split_teams(teams, players, n) do
    {team_players, remaining_players} = Enum.split(players, div(length(players), n))

    team =
      Team.new(%{players: team_players, name: "Team #{n}"})
      |> Team.assign_color_and_index(n - 1)

    _split_teams([team | teams], remaining_players, n - 1)
  end
end
