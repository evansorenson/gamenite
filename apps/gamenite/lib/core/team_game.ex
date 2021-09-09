defmodule Gamenite.Core.TeamGame do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset

  alias Gamenite.Core.Cards
  alias Gamenite.Core.Cards.Card

  alias Gamenite.Core.{Turn, Team}

  embedded_schema do
    field :current_turn, :map
    field :is_finished, :boolean, default: false
    embeds_one :current_team, Team
    embeds_many :teams, Team
    embeds_many :deck, Card
  end
  @fields [:current_turn]

  @max_teams Application.get_env(:gamenite, :max_teams)
  @max_deck Application.get_env(:gamenite, :max_deck)
  @spec new_game_changeset(
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any},
          nonempty_maybe_improper_list,
          any
        ) :: Ecto.Changeset.t()
  def new_game_changeset(fields, teams, deck) do
    %__MODULE__{}
    |> cast(fields, @fields)
    |> put_embed(:teams, teams)
    |> put_embed(:current_team, hd(teams))
    |> put_embed(:deck, deck)
    |> validate_required([:teams, :current_team, :deck])
    |> validate_length(:teams, min: 2, max: @max_teams)
    |> validate_length(:deck, min: 10, max: @max_deck)
  end

  def new([], _deck), do: {:error, "teams is empty list."}
  def new(teams, deck) do
    %{}
    |> new_game_changeset(teams, deck)
    |> apply_action(:update)
  end

  defp end_turn(game) do
    game
    |> append_turn_to_team
    |> inc_player
    |> inc_team
    |> new_turn
  end


  defp append_turn_to_team(%__MODULE__{ current_turn: current_turn } = game) do
    game
    |> update_in([:current_team][:turns], fn turns -> [ current_turn | turns ] end)
  end

  defp inc_player(%__MODULE__{ teams: teams, current_team: current_team } = game) do
    game
    |> put_in(
      [:current_team][:players],
      current_team.current_player
    )
    |> update_in(
      [:current_team][:current_player],
      &next_list_element(teams, &1)
    )
  end

  defp inc_team(%__MODULE__{ teams: teams, current_team: current_team } = game) do
    { _, next_team } = next_list_element(teams, current_team)

    game
    |> update_team(teams, current_team)
    |> replace_current_team(next_team)
  end

  defp update_team(game, teams, team) do
    game
    |> put_in([:teams][Access.at(find_element_index(teams, team))], team)
  end

  defp replace_current_team(game, next_team) do
    game
    |> Map.replace!(:current_team, next_team)
  end

  def new_turn(%__MODULE__{ current_team: current_team } = game) do
    turn = Turn.new(current_team.current_player)

    game
    |> Map.replace!(:current_turn, turn)
  end


  def next_list_element(list, element) do
    curr_idx = find_element_index(list, element)
    next_idx = next_list_index(list, curr_idx)
    { next_idx, Enum.at(list, next_idx) }
  end

  defp find_element_index(list, element) do
    Enum.find_index(list, &(&1 == element))
  end

  defp next_list_index(list, index) when index >= 0 and index < Kernel.length(list), do: rem(index + 1, length(list))
  defp next_list_index(_, _), do: {:error, "Index must be between 0 (inclusive) and length of list "}

  @doc """
  Adds player to either team with lowest number of players or if no teams, to list of players.

  Returns %__MODULE__{}.
  """
  def add_player( %__MODULE__{ teams: teams } = game, player) do
    team_to_add = team_with_lowest_players(teams)
    IO.inspect(team_to_add)
    _add_player(game, team_to_add, player)
  end
  defp _add_player(%{ current_team: current_team } = game, team, player) when current_team.id == team.id do
    IO.puts team.id
    IO.puts current_team.id
    game
    |> update_in(
      [:current_team, :players],
      fn players -> [ player | players ] end)
  end
  defp _add_player(%{ teams: teams } = game, team, player) do
    game
    |> update_in(
      [:teams, Access.at(find_element_index(teams, team)), :players],
      fn players -> [ player | players ] end)
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
  def clear_current_player_hand(game) do
    game
    |> put_in([:current_team][:current_player][:hand], [])
  end

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
    |> put_in([:current_team][:current_player][:hand], hand)
  end

  def start_turn(%__MODULE__{ current_turn: current_turn } = game) do
    game
    |> put_in(current_turn.started_at, DateTime.utc_now())
  end
end
