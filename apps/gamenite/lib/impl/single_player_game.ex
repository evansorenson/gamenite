defmodule Gamenite.SinglePlayerGame do
  defmacro __using__(_opts) do
    quote do
      import Ecto.Changeset
      alias Gamenite.Game
      @behaviour Gamenite.Game
      alias Gamenite.SinglePlayerGame
      use Accessible

      def change(%__MODULE__{} = game, attrs \\ %{}) do
        game
        |> Game.base_changeset(attrs)
        |> SinglePlayerGame.changeset(attrs)
        |> __MODULE__.changeset(attrs)
      end

      def new() do
        %__MODULE__{}
      end

      def create(attrs) do
        %__MODULE__{}
        |> Game.base_changeset(attrs)
        |> SinglePlayerGame.changeset(attrs)
        |> __MODULE__.changeset(attrs)
        |> apply_action(:update)
      end
    end
  end

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
end
