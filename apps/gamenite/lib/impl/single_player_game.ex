defmodule Gamenite.SinglePlayerGame do
  use Ecto.Schema
  import Ecto.Changeset
  alias Gamenite.Game
  alias Gamenite.Lists

  embedded_schema do
    field :players, :map
    field :current_player, :map
  end

  @fields [:players, :current_player]
  @required [:players, :current_player]

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

  def changeset(game, %{players: players} = params) when length(players) > 0 do
    do_changeset(game, Map.put(params, :current_player, hd(players)))
  end

  def changeset(game, params) do
    do_changeset(game, params)
  end

  defp do_changeset(team_game, attrs) do
    team_game
    |> Game.changeset(attrs)
    |> cast(attrs, @fields)
    |> validate_required(@required)
    |> validate_length(:players, min: 2)
  end

  def end_turn(game) do
    game
    |> append_turn_to_current_player
    |> next_player
  end

  defp next_player(game) do
    game
    |> Lists.update_current_item_and_increment_list([:players], [:current_player])
  end

  defp append_turn_to_current_player(
         %{current_player: current_player, current_turn: current_turn} = game
       ) do
    game
    |> replace_current_player(add_turn(current_player, current_turn))
  end

  def add_turn(player, turn) do
    player
    |> Map.update(:turns, [turn], fn turns -> [turn | turns] end)
  end

  def replace_current_player(game, player) do
    game
    |> Map.replace!(:current_player, player)
  end

  def current_player?(%{current_player: current_player} = _game, id) do
    current_player.id == id
  end

  def add_player(game, player) do
    if player_exists?(game, player.id) do
      {:error, "Player is already in game."}
    else
      do_add_player(game, player)
    end
  end

  def do_add_player(game, player) do
    game
    |> Map.update(:players, [player], fn players -> [player | players] end)
  end

  defp player_exists?(%{players: players} = _game, id) do
    Enum.any?(players, &(&1.id == id))
  end

  def add_score_to_player(game, player_id, score) do
    player_idx = Lists.find_element_index_by_id(game.players, player_id)

    game
    |> update_in([:players, Access.at(player_idx), :score], &(&1 + score))
  end
end
