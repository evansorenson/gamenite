defmodule Gamenite.Poophead do
  use Ecto.Schema
  import Ecto.Changeset

  alias Gamenite.Poophead.{Player}
  alias Gamenite.PlayingCards

  embedded_schema do
    field :players, {:array, :map}
    field :deck, {:array, :map}
    field :submitted_machines, {:array, :string}
    field :votes, {:array, :integer}
    field :winning_machine, :string
    field :flush_threshold, :integer
    field :phase, :string
  end

  @fields [:players, :deck]

  def changeset(game, attrs) do
    game
    |> cast(@fields, attrs)
    |> validate_required([:players])
    |> validate_length(:players, min: 2)
  end

  def setup_game(game) do
    game
    |> add_decks_and_set_flush_threshold
    |> setup_round
  end

  def setup_round(game) do
    game
    # |>
    # |> deal_cards
  end

  defp add_decks_and_set_flush_threshold(%__MODULE__{players: players} = game) do
    num_decks = ceil(rem(players, 4))
    deck = Enum.reduce(1..num_decks, fn _i, acc -> acc ++ PlayingCards.create_deck() end)

    game
    |> set_threhsold_limit(num_decks)
    |> Map.put(:deck, deck)
  end

  defp set_threhsold_limit(game, num_decks) do
    case num_decks do
      1 ->
        %{game | threshold_limit: 4}

      _ ->
        %{game | threshold_limit: num_decks * 4 - 2}
    end
  end
end
