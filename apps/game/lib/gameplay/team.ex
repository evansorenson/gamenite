defmodule Gameplay.Team do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset

  alias Gameplay.{Player, Turn}

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field :name, :string
    field :score, :integer
    field :color, :string
    embeds_many :players, Player
    embeds_one :current_player, Player
    embeds_many :turns, Turn
  end

  @team_colors [:red, :blue, :green, :purple, :green, :orange, :pink ]
  def changeset(team, fields) do
    team
    |> name_changeset(fields)
    |> cast(fields, [:score, :color, :players, :current_player, :turns])
    |> validate_required([:players, :current_player])
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
    name = "Team #{Integer.to_string(index)}"
    color = Enum.at(@team_colors, index - 1)

    %__MODULE__{}
    |> changeset(%{players: players, color: color, name: name})
    |> apply_action(:update)
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
    {:error, "There must be at least two players per team."}
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
    IO.puts Kernel.floor(length(players) / n)
    { team_players, remaining_players } = Enum.split(players, div(length(players), n))
    team = new(team_players, n - 1 )
    _split_teams([ team | teams ], remaining_players, n - 1)
  end
end
