defmodule GamenitePersistance.Cards.GameDeck do
  use Ecto.Schema
  import Ecto.Changeset

  alias GamenitePersistance.Gaming.Game
  alias GamenitePersistance.Cards.Deck

  schema "game_decks" do
    has_one :game, Game
    has_one :deck, Deck

    timestamps()
  end

  @doc false
  def changeset(deck, attrs) do
    deck
    |> cast(attrs, [:game, :deck])
    |> validate_required([:game, :deck])
  end
end
