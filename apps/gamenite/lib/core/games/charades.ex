defmodule Gamenite.Core.Charades do
  use Ecto.Schema
  import Ecto.Changeset

  alias Gamenite.Core.TeamGame

  @default_rounds ["Catchphrase", "Password", "Charades"]
  @rounds @default_rounds ++ ["Pictionary"]
  embedded_schema do
    field :turn_length, :integer, default: 60
    field :skip_limit, :integer, default: 1
    field :no_skip_limit, :boolean, default: false
    field :rounds, {:array, :string}, default: @default_rounds
    field :current_round, :string
    field :starting_deck, {:array, :map}
    embeds_one :team_game, TeamGame
  end
  @fields [:turn_length, :skip_limit, :team_game, :rounds, :current_round, :starting_deck]

  def changeset(charades, params) do
    charades
    |> cast(params, @fields)
    |> validate_required([:team_game])
    |> validate_number(:turn_length, less_than_or_equal_to: 120)
    |> validate_number(:turn_length, greater_than_or_equal_to: 30)
    |> validate_number(:skip_limit, greater_than_or_equal_to: 0)
    |> validate_number(:skip_limit, less_than_or_equal_to: 5)
  end


  def salad_bowl_changeset(changeset) do
    changeset
    |> validate_required([:current_round, :starting_deck])
    |> validate_subset(:rounds, @rounds)
    |> validate_length(:rounds, min: 1)
  end

  def new_salad_bowl(%{rounds: rounds} = fields) do
    fields
    |> Map.put(fields, :current_round, List.first(rounds))

    %__MODULE__{}
    |> changeset(fields)
    |> salad_bowl_changeset
  end

  def new(fields) do
    %__MODULE__{}
    |> changeset(fields)
  end

  @doc """
  Moves to next player's and team's turn.

  Returns %__MODULE__{}.
  """
  def end_turn(game) do
    game
    |> move_cards_after_review
    |> TeamGame.end_turn
  end

  def skip_card(%__MODULE__{ team_game: team_game, skip_limit: skip_limit, no_skip_limit: false } = _charades, _card)
  when team_game.current_turn.num_cards_skipped >= skip_limit
  do
    {:error, "You have reached skip limit of #{team_game.current_turn.skip_limit}"}
  end
  def skip_card(%__MODULE__{ team_game: team_game} = _charades, _card)
  when length(team_game.deck) == 0
  do
    {:error, "Cannot skip card. No cards left in deck."}
  end
  def skip_card(charades) do
    charades
    |> inc_skipped_card
    |> TeamGame.draw_card()
  end

  defp inc_skipped_card(charades) do
    charades
    |> update_in([:team_game][:current_turn][:num_cards_skipped], &(&1 + 1))
  end

  def card_is_correct(charades, card) do
    correct_card = Cards.correct_card(card)

    charades
    |> update_card_in_hand(correct_card)
    |> maybe_review_cards
  end

  defp update_card_in_hand(%__MODULE__{ team_game: team_game } = charades, card) do
    charades
    |> put_in(
      [:team_game][:current_player][:hand][Access.at(Enum.find_index(team_game.current_player.hand, &(&1.id == card.id)))], card)
  end

  defp maybe_review_cards(%__MODULE__{ team_game: team_game } = charades)
  when length(team_game.current_team.deck) == 0 do
    charades
    |> put_in([:team_game][:current_turn][:needs_review], true)
  end
  defp maybe_review_cards(game), do: game

  defp move_cards_after_review(%__MODULE__{ team_game: team_game} = charades) do
    correct_cards = Enum.filter(team_game.current_team.current_player.hand, &is_card_correct?(&1))
    incorrect_cards = Enum.reject(team_game.current_team.current_player.hand, &is_card_correct?(&1))

    charades
    |> add_correct_cards_to_turn(correct_cards)
    |> move_incorrect_back_to_deck(incorrect_cards)
    |> TeamGame.clear_current_player_hand
  end

  defp is_card_correct?(card) when card.is_correct, do: true
  defp is_card_correct?(_card), do: false

  defp add_correct_cards_to_turn(charades, cards_correct) do
    charades
    |> put_in([:team_game][:current_turn][:cards_correct], cards_correct)
  end

  defp move_incorrect_back_to_deck(%__MODULE__{ team_game: team_game } = charades, incorrect_cards) do
    new_deck = team_game.deck ++ incorrect_cards
    updated_game = TeamGame.update_deck(team_game, new_deck)

    charades
    |> update_game(updated_game)
  end

  defp update_game(charades, updated_game) do
    charades
    |> Map.replace!(:team_game, updated_game)
  end

  # Salad Bowl Logic
  def inc_round(%{ rounds: rounds, current_round: current_round} = game) do
    _inc_round(game, TeamGame.next_list_element(rounds, current_round))
  end
  defp _inc_round(game, { 0, _ }) do
    Map.replace!(game, :is_finished, true)
  end
  defp _inc_round(game, { _, next_round }) do
    game
    |> Map.replace!(:current_round, next_round)
  end

  def end_round(%{ starting_deck: starting_deck } = game) do
    game
    |> inc_round
    |> move_cards_after_review
    |> TeamGame.update_deck(starting_deck)
  end
end
