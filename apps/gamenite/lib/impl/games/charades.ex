defmodule Gamenite.Charades do
  @behaviour Gamenite.Game
  use Accessible

  use Ecto.Schema
  import Ecto.Changeset

  alias Gamenite.Charades.{Turn}
  alias Gamenite.TeamGame
  alias Gamenite.TeamGame.Team
  alias Gamenite.Lists
  alias Gamenite.Cards

  embedded_schema do
    embeds_one(:current_team, Team)
    embeds_many(:teams, Team)
    field(:room_slug, :string)
    field(:current_turn, :map)
    field(:turn_length, :integer, default: 60)
    field(:skip_limit, :integer, default: 1)
    field(:deck, {:array, :string}, default: [])
    field(:finished?, :boolean, default: false)
    field(:timer)
  end

  @fields [:room_slug, :turn_length, :skip_limit, :deck, :current_turn]

  @impl Gamenite.Game
  def changeset(charades_game, attrs) do
    charades_game
    |> cast(attrs, @fields)
    |> validate_required(:room_slug)
    |> validate_number(:turn_length, less_than_or_equal_to: 120)
    |> validate_number(:turn_length, greater_than_or_equal_to: 30)
    |> validate_number(:skip_limit, greater_than_or_equal_to: 0)
    |> validate_number(:skip_limit, less_than_or_equal_to: 5)
  end

  @impl Gamenite.Game
  def create(attrs), do: TeamGame.create(__MODULE__, %__MODULE__{}, attrs)

  @impl Gamenite.Game
  def change(game, attrs), do: TeamGame.change(__MODULE__, game, attrs)

  @impl Gamenite.Game
  def new(), do: %__MODULE__{}

  @impl Gamenite.Game
  def create_player(attrs) do
    TeamGame.Player.create(attrs)
  end

  @impl Gamenite.Game
  def setup(game, _opts \\ []) do
    new_turn(game, game.turn_length)
  end

  def create_turn(attrs \\ %{}) do
    Turn.new(attrs)
  end

  def new_turn(game, turn_length) do
    new_turn =
      Turn.new(%{
        time_remaining_in_sec: turn_length
      })

    %{game | current_turn: new_turn}
  end

  def draw_card(%{deck: deck} = game) do
    case Cards.draw(deck) do
      {:error, reason} ->
        {:error, reason}

      {drawn_cards, remaining_deck} ->
        game
        |> put_in([:current_turn, :card], hd(drawn_cards))
        |> Map.put(:deck, remaining_deck)
    end
  end

  def add_card_to_completed(%{current_turn: current_turn} = _game, _card_outcome)
      when is_nil(current_turn.card) do
    {:error, "Card is nil."}
  end

  def add_card_to_completed(
        %{deck: deck, current_turn: current_turn, skip_limit: skip_limit} = game,
        :skipped = _card_outcome
      ) do
    skipped_card_count = count_cards_with_outcome(current_turn.completed_cards, :skipped)

    cond do
      skipped_card_count >= skip_limit ->
        {:error, "You have reached skip limit of #{skip_limit}."}

      deck == [] ->
        {:error, "Cannot skip card. No cards left in deck."}

      true ->
        do_add_card_to_completed(game, :skipped)
        |> draw_card
    end
  end

  def add_card_to_completed(%{deck: deck, current_turn: current_turn} = game, card_outcome) do
    skipped_card_count = count_cards_with_outcome(current_turn.completed_cards, :skipped)

    new_game =
      game
      |> increment_score_if_correct(card_outcome)
      |> do_add_card_to_completed(card_outcome)

    cond do
      deck == [] and skipped_card_count > 0 ->
        new_game
        |> move_skipped_to_card

      deck == [] and skipped_card_count == 0 ->
        {:review, new_game}

      true ->
        new_game
        |> draw_card
    end
  end

  defp do_add_card_to_completed(%{current_turn: current_turn} = game, card_outcome) do
    game
    |> update_in([:current_turn, :completed_cards], fn cards ->
      [{card_outcome, current_turn.card} | cards]
    end)
    |> put_in([:current_turn, :card], nil)
  end

  def count_cards_with_outcome(completed_cards, target_outcome) do
    Enum.count(completed_cards, fn {outcome, _card} -> outcome == target_outcome end)
  end

  defp move_skipped_to_card(%{current_turn: current_turn} = game) do
    first_skipped =
      {:skipped, card} =
      Enum.find(current_turn.completed_cards, fn {outcome, _card} -> outcome == :skipped end)

    game
    |> put_in([:current_turn, :card], card)
    |> update_in([:current_turn, :completed_cards], &List.delete(&1, first_skipped))
  end

  def change_card_outcome(%{current_turn: current_turn} = game, index, new_outcome) do
    {old_outcome, _old_card} = Enum.at(current_turn.completed_cards, index)
    new_game = do_change_card_outcome(game, index, new_outcome)

    cond do
      old_outcome == :correct ->
        new_game
        |> add_to_team_score(-1)

      new_outcome == :correct ->
        new_game
        |> add_to_team_score(1)

      true ->
        new_game
    end
  end

  def do_change_card_outcome(%{current_turn: current_turn} = game, index, new_outcome) do
    completed_cards =
      List.update_at(current_turn.completed_cards, index, fn {_outcome, card} ->
        {new_outcome, card}
      end)

    game
    |> put_in([:current_turn, :completed_cards], completed_cards)
  end

  def move_incorrect_back_to_deck(%{current_turn: current_turn} = game)
      when not is_nil(current_turn.card) do
    game
    |> do_add_card_to_completed(:incorrect)
    |> do_move_incorrect_back_to_deck
  end

  def move_incorrect_back_to_deck(game), do: do_move_incorrect_back_to_deck(game)

  defp do_move_incorrect_back_to_deck(%{deck: deck, current_turn: current_turn} = game) do
    incorrect_cards =
      current_turn.completed_cards
      |> Enum.reduce(
        [],
        fn
          {:correct, _card}, acc ->
            acc

          {_outcome, card}, acc ->
            [card | acc]
        end
      )

    new_deck = deck ++ incorrect_cards

    game
    |> update_deck(new_deck)
  end

  defp check_words_unique_in_list(word_list) do
    if Enum.uniq(word_list) != word_list do
      {:error, "Duplicate cards sumbitted. Must all be unique."}
    else
      :ok
    end
  end

  defp check_words_unique_in_deck([] = _deck, _word_list), do: :ok

  defp check_words_unique_in_deck(deck, word_list) do
    errors =
      Enum.reduce(word_list, [], fn word, acc ->
        if word in deck do
          ["#{word} was submitted by another player.\n" | acc]
        else
          acc
        end
      end)

    if Enum.any?(errors) do
      {:error, errors}
    else
      :ok
    end
  end

  def add_cards_to_deck(%{deck: deck} = game, word_list, user_id) do
    with :ok <- check_words_unique_in_list(word_list),
         :ok <- check_words_unique_in_deck(deck, word_list) do
      do_add_cards_to_deck(game, word_list, user_id)
    else
      {:error, errors} ->
        {:error, errors}
    end
  end

  defp do_add_cards_to_deck(%{deck: deck} = game, cards, user_id) do
    game
    |> Map.update(:submitted_users, [user_id], fn users -> [user_id | users] end)
    |> Map.put(:starting_deck, cards ++ deck)
    |> update_deck(cards ++ deck)
  end

  def start_turn(game) do
    game
    |> draw_card
    |> set_turn_started?(true)
  end

  defp set_turn_started?(game, bool) do
    game
    |> put_in([:current_turn, :started?], bool)
  end

  def end_turn(game) do
    game
    |> move_incorrect_back_to_deck
    |> do_end_turn
  end

  defp do_end_turn(%{current_turn: current_turn, deck: []} = game)
       when current_turn.time_remaining_in_sec != 0 do
    game
    |> maybe_end_round
    |> new_turn(current_turn.time_remaining_in_sec)
  end

  defp do_end_turn(%{turn_length: turn_length} = game) do
    game
    |> TeamGame.end_turn()
    |> new_turn(turn_length)
  end

  defp increment_score_if_correct(game, :correct) do
    game
    |> add_to_team_score(1)
  end

  defp increment_score_if_correct(game, _card_outcome), do: game

  defp add_to_team_score(game, score) do
    game
    |> TeamGame.add_score(score)
  end

  # Salad Bowl Logic
  def inc_round(%{rounds: rounds, current_round: current_round} = game) do
    case Lists.next_list_index(rounds, current_round) do
      0 ->
        Map.replace!(game, :finished?, true)

      index ->
        next_round = Enum.at(rounds, index)

        game
        |> Map.put(:current_round, next_round)
    end
  end

  def maybe_end_round(%{rounds: _rounds, deck: []} = game), do: end_round(game)
  def maybe_end_round(game), do: game

  defp end_round(%{starting_deck: starting_deck} = game) do
    game
    |> inc_round
    |> update_deck(starting_deck)
    |> set_turn_started?(false)
    |> put_in([:current_turn, :review?], false)
  end

  def update_deck(game, new_deck) do
    %{game | deck: new_deck}
  end
end
