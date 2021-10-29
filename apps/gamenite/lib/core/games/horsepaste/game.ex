defmodule Gamenite.Games.Horsepaste.Game do
  use Ecto.Schema
  use Accessible
  import Ecto.Changeset
  alias Gamenite.TeamGame
  alias Gamenite.TeamGame.Team

  embedded_schema do
    embeds_one(:current_team, Team)
    embeds_many(:teams, Team)
    field(:room_slug, :string)
    field(:current_turn, :map)
    field(:deck, {:array, :string})
    field(:board, :map)
    field(:finished?, :boolean, default: false)
    field(:timer_length, :integer, default: 60)
    field(:timer_enabled?, :boolean, default: false)
  end

  @fields [:room_slug, :current_turn, :cards, :timer_length, :timer_enabled?]
  def changeset(game, attrs) do
    game
    |> TeamGame.changeset(attrs)
    |> cast(attrs, @fields)
    |> validate_required(:room_slug)
    |> validate_length(:teams, is: 2)
  end
end
