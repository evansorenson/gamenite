defmodule Gamenite.TeamGame do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset

  alias Gamenite.Cards
  alias Gamenite.Cards.Card
  alias Gamenite.Lists

  alias Gamenite.TeamGame.{Turn, Team}

  embedded_schema do
    field :name, :string
    field :room_id, :string
    field :current_turn, :map
    field :is_finished, :boolean, default: false
    embeds_one :current_team, Team
    embeds_many :teams, Team
    embeds_many :deck, Card
  end
  @fields [:current_turn, :name]

  @max_teams Application.get_env(:gamenite, :max_teams)
  @max_deck Application.get_env(:gamenite, :max_deck)
  def finalize_game_changeset(team_game, %{teams: teams, deck: deck} = fields) do
    team_game
    |> cast(fields, @fields)
    |> put_embed(:teams, teams)
    |> put_embed(:current_team, hd(teams))
    |> put_embed(:deck, deck)
    |> put(:current_turn, Turn.new(hd(teams).current_player))
    |> validate_required([:teams, :current_team, :deck, :current_turn])
    |> validate_length(:teams, min: 2, max: @max_teams)
    |> validate_length(:deck, min: 5, max: @max_deck)
  end

  def teams_changeset(team_game, fields) do
    team_game
    |> cast(fields, @fields)
    |> cast_embed(:teams)
    |> validate_required([:teams])
    |> validate_length(:teams, min: 2, max: @max_teams)
  end
  def new(fields) do
    struct!(__MODULE__, fields)
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

  defp replace_current_player(game, next_player) do
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

  # def clear_all_players_hands(%__MODULE__{ teams: teams, current_team: current_team } = game) do
  #   cleared_teams = teams
  #   |> Enum.map(&clear_team_hand(&1))

  #   cleared_current_team =  clear_team_hand(current_team)

  #   game
  #   |> Map.replace!(:teams, cleared_teams)
  #   |> replace_current_team(cleared_current_team)
  # end

  # defp clear_team_hand(team) do
  #   Enum.map(team.players, &clear_player_hand(&1))
  # end

  def draw_card(%__MODULE__{ deck: deck, current_team: current_team } = game, num \\ 1) do
    case Cards.draw_into_hand(deck, current_team.current_player.hand, num) do
      { :error, reason } ->
        { :error, reason }

      { new_hand,  new_deck } ->
        game
        |> update_current_hand(new_hand)
        |> update_deck(new_deck)
    end
  end

  def update_deck(game, new_deck) do
    game
    |> Map.replace!(:deck, new_deck)
  end

  def update_current_hand(game, hand) do
    game
    |> put_in([:current_team, :current_player, :hand], hand)
  end

  def start_turn(%__MODULE__{ current_turn: current_turn } = game) do
    game
    |> put_in(current_turn.started_at, DateTime.utc_now())
  end
end
