defmodule Gamenite.SinglePlayerGame do
  use Ecto.Schema
  import Ecto.Changeset

  alias Gamenite.Lists

  embedded_schema do
    field :players, :map
    field :current_player, :map
  end
  @fields [:players, :current_player]
  @required [:players, :current_player]

  def changeset(game, %{players: players} = params) when length(players) > 0 do
    do_changeset(game, Map.put(params, :current_player, hd(players)))
  end

  def changeset(game, params) do
    do_changeset(game, params)
  end

  defp do_changeset(team_game, params) do
    team_game
    |> cast(params, @fields)
    |> validate_required(@required)
    |> validate_length(:players, min: 2)
  end

  def new(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action(:update)
  end

  def end_turn(game) do
    game
    |> inc_player
  end

  defp inc_player(game) do
    game
    |> Lists.update_current_item_and_increment_list([:players], [:current_player])
  end

  def current_player?(%{current_player: current_player} = _game, id) do
    current_player.id == id
  end
end
