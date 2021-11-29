defmodule Gamenite.Witbash.Answer do
  use Accessible
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :user_id, :binary_id
    field :answer, :string
    field :votes, {:array, :binary_id}, default: []
    field :score, :integer, default: 0
    field :prompt_index, :integer
  end

  @fields [:user_id, :answer, :prompt_index]
  @required [:user_id, :answer, :prompt_index]

  def changeset(answer, attrs) do
    answer
    |> cast(attrs, @fields)
    |> validate_required(@required)
    |> validate_length(:answer, min: 1, max: 80)
  end
end
