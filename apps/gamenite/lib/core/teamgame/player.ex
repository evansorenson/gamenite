defmodule Gamenite.Core.TeamGame.Player do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :user_id, :id
    field :name, :string
    field :color, :string, default: nil
    field :turns, {:array, :map}
    embeds_many :hand, Card
  end

  def changeset(player, attrs) do
    player
    |> name_changeset(attrs)
    |> cast(attrs, [:id, :user_id, :color, :turns])
    |> cast_embed(:hand)
    |> validate_required([:user_id, :name])
    |> validate_length(:name, min: 2, max: 10)
  end

  def name_changeset(player, attrs) do
    player
    |> cast(attrs, [:name])
    |> validate_required(:name)
    |> validate_length(:name, min: 2, max: 10)
  end

  def new(attrs) do
    id = Ecto.UUID.generate()

    %__MODULE__{}
    |> changeset(Map.put(attrs, :id, id))
    |> apply_action(:update)
  end

  def update_name(player, name) do
    name_changeset(player, %{name: name})
    |> apply_action(:update)
  end

end
