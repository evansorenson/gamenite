defmodule Gamenite.TeamGame.Player do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :name, :string
    field :color, :string, default: nil
    field :turns, {:array, :map}
  end

  @player_colors ["F2F3F4", "222222", "F3C300", "875692", "F38400", "A1CAF1", "BE0032", "C2B280", "848482", "008856", "E68FAC", "0067A5", "F99379", "604E97", "F6A600", "B3446C", "DCD300", "882D17", "8DB600", "654522", "E25822", "2B3D26"]

  def changeset(player, attrs) do
    player
    |> name_changeset(attrs)
    |> cast(attrs, [:id, :color, :turns])
    |> validate_required([:id, :name, :color])
    |> validate_length(:name, min: 2, max: 15)
  end

  def name_changeset(player, attrs) do
    player
    |> cast(attrs, [:name])
    |> validate_required(:name)
    |> validate_length(:name, min: 2, max: 15)
  end

  def update_name(player, name) do
    name_changeset(player, %{name: name})
    |> apply_action(:update)
  end


  def new(attrs) do
    id = Ecto.UUID.generate()

    %__MODULE__{}
    |> changeset(Map.put(attrs, :id, id))
    |> apply_action(:update)
  end

  def new_players_from_users(users) do
    users
    |> Enum.with_index
    |> Enum.map(fn {user, index} ->
      %{id: user.id, color: Enum.at(@player_colors, index), name: user.username} end)
  end
end
