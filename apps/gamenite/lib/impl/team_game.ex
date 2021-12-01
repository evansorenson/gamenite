defmodule Gamenite.TeamGame do
  use Ecto.Schema
  import Ecto.Changeset

  alias Gamenite.Game
  alias Gamenite.Lists
  alias Gamenite.TeamGame.Team

  embedded_schema do
    field(:current_turn, :map)
    embeds_one(:current_team, Team)
    embeds_many(:teams, Team)
  end

  @max_teams Application.get_env(:gamenite, :max_teams)
  def changeset(team_game, %{teams: teams} = params) when teams != [] do
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
    |> validate_change(:teams, &validate_teams/2)
  end

  defp validate_teams(field, teams, opts \\ [min_players: 4, max_players: 8])

  defp validate_teams(field, [%Ecto.Changeset{} = _head | _tail] = teams_changeset, opts) do
    teams = Enum.map(teams_changeset, fn team_changeset -> team_changeset.changes end)
    do_validate_teams(field, teams, opts)
  end

  defp validate_teams(field, teams, opts) do
    IO.inspect(teams)
    do_validate_teams(field, teams, opts)
  end

  defp do_validate_teams(field, teams, opts) do
    cond do
      num_players(teams) < opts[:min_players] ->
        [{field, "At least #{opts[:min_players]} players required to start."}]

      num_players(teams) > opts[:max_players] ->
        [{field, "Need fewer than #{opts[:max_players]} players to start."}]

      true ->
        []
    end
  end

  defp num_players(teams) do
    Enum.reduce(teams, 0, fn team, acc -> acc + length(team.players) end)
  end

  def change(module, game, attrs \\ %{}) do
    game
    |> Game.changeset(attrs)
    |> changeset(attrs)
    |> module.changeset(attrs)
  end

  def create(module, game, attrs) do
    change(module, game, attrs)
    |> apply_action(:update)
  end

  def end_turn(game) do
    game
    |> append_turn_to_team
    |> inc_player
    |> next_team
  end

  def end_turn_same_player(game) do
    game
    |> append_turn_to_team
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

  defp next_team(game) do
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

  def on_team?(team, id) do
    Enum.any?(team.players, fn player -> player.id == id end)
  end

  def fetch_team_or_current_team(%{current_team: current_team} = _game, index)
      when current_team.index == index do
    current_team
  end

  def fetch_team_or_current_team(%{teams: teams} = _game, index) do
    Enum.at(teams, index)
  end

  def current_player?(team, id) do
    team.current_player.id == id
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
