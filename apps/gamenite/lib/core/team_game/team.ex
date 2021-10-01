defmodule Gamenite.TeamGame.Team do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :name, :string
    field :score, :integer
    field :color, :string
    field :turns, {:array, :map}, default: []
    field :players, {:array, :map}
    field :current_player, :map
  end
  @fields [:id, :name, :score, :color, :turns, :players, :current_player]

  @team_colors ["C0392B", "2980B9", "27AE60", "884EA0", "D35400", "FF33B8", "F1C40F"]
  def changeset(team, fields) do
    team
    |> name_changeset(fields)
    |> cast(fields, @fields)
    |> validate_required([:players, :color])
    |> validate_number(:score, greater_than_or_equal_to: 0)
    |> validate_inclusion(:color, @team_colors)
    |> validate_length(:players, min: 2, max: 10)
  end

  def name_changeset(team, fields) do
    team
    |> cast(fields, [:name])
    |> validate_required(:name)
    |> validate_length(:name, min: 1, max: 15)
  end

  def new(players, index) do
    id = Ecto.UUID.generate()
    name = "Team #{Integer.to_string(index)}"
    color = Enum.at(@team_colors, index - 1)

    %__MODULE__{}
    |> changeset(%{color: color, name: name, id: id, current_player: hd(players), players: players})
    |> apply_action!(:update)
  end

  def update_name(team, name) do
    team
    |> name_changeset(%{ name: name})
    |> apply_action(:update)
  end


  @doc """
  Splits players into n number of teams.

  Returns [%Gameplay.Team{}]
  """

  def split_teams(players, n) when n * 2 > length(players) do
    {:error, "At least four players are required."}
  end
  def split_teams(_players, n) when n > 7 do
    {:error, "Too many teams. Must be 7 or under."}
  end
  def split_teams(players, n) do
    _split_teams([], Enum.shuffle(players), n)
  end
  defp _split_teams(teams, players, 1) do
  team = new(players, 0)
  [ team | teams ]
  end
  defp _split_teams(teams, players, n) do
    { team_players, remaining_players } = Enum.split(players, div(length(players), n))
    team = new( team_players, n - 1 )
    _split_teams([ team | teams ], remaining_players, n - 1)
  end

  def team_length(%__MODULE__{ players: players }) do
    length(players)
  end

  def add_player(team, player) do
    team
    |> Map.update(:players, [ player ], fn players -> [ player | players ] end)
  end

  def remove_player(team, player) do
    team
    |> Map.update(:players, [], fn players -> List.delete(players, player) end)
  end

  def add_turn(team, turn) do
    team
    |> Map.update(:turns, [ turn ], fn turns -> [ turn | turns ] end)
  end
end
