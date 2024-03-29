defmodule Gamenite.TeamGame.Team do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:name, :string)
    field(:score, :integer, default: 0)
    field(:color, :string)
    field(:index, :integer)
    field(:turns, {:array, :map}, default: [])
    field(:players, {:array, :map})
    field(:current_player, :map)
  end

  @fields [:id, :name, :score, :color, :index, :turns, :players, :current_player]
  @team_colors Application.get_env(:gamenite, :team_colors)
  def changeset(team, fields) do
    team
    |> cast(fields, @fields)
    |> validate_required([:players, :color, :current_player])
    |> validate_inclusion(:color, @team_colors)
    |> validate_length(:players, min: 2, message: "Not enough players to start game.")
  end

  def name_changeset(team, fields) do
    team
    |> cast(fields, [:name])
    |> validate_required(:name)
    |> validate_length(:name, min: 1, max: 15)
  end

  def new(%{players: players} = params) when length(players) > 0 do
    id = Ecto.UUID.generate()

    params
    |> Map.merge(%{current_player: hd(players), id: id})
  end

  def new(params) do
    id = Ecto.UUID.generate()

    params
    |> Map.merge(%{id: id})
  end

  def update_name(team, name) do
    team
    |> name_changeset(%{name: name})
    |> apply_action(:update)
  end

  @doc """
  Splits players into n number of teams.

  Returns [%Gameplay.Team{}]
  """

  def team_length(%__MODULE__{players: players}) do
    length(players)
  end

  def add_player(team, player) do
    team
    |> Map.update(:players, [player], fn players -> [player | players] end)
  end

  def remove_player(team, player) do
    team
    |> Map.update(:players, [], fn players -> List.delete(players, player) end)
  end

  def add_turn(team, turn) do
    team
    |> Map.update(:turns, [turn], fn turns -> [turn | turns] end)
  end

  def assign_color_and_index(team, index) do
    team
    |> Map.put(:color, Enum.at(@team_colors, index))
    |> Map.put(:index, index)
  end
end
