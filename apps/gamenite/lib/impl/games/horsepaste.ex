defmodule Gamenite.Games.Horsepaste do
  use Ecto.Schema
  use Accessible
  import Ecto.Changeset

  alias Gamenite.TeamGame
  alias Gamenite.TeamGame.Team
  alias Gamenite.Cards

  alias Gamenite.Horsepaste.{Turn, Card}

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

  @fields [:room_slug, :current_turn, :deck, :timer_length, :timer_enabled?]
  def changeset(game, attrs) do
    game
    |> TeamGame.changeset(attrs)
    |> cast(attrs, @fields)
    |> validate_required(:room_slug)
    |> validate_length(:teams, is: 2)
    |> validate_length(:deck, min: 25)
  end

  def change_game(%__MODULE__{} = game, attrs \\ %{}) do
    game
    |> changeset(attrs)
  end

  def create_game(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:update)
  end

  def setup_game(game, randomize_first_team? \\ true)

  def setup_game(game, true) do
    game
    |> randomize_team
    |> set_starting_score
    |> new_turn
    |> create_board
  end

  def setup_game(game, false) do
    game
    |> set_starting_score
    |> new_turn
    |> create_board
  end

  defp randomize_team(game) do
    first_team = Enum.random(game.teams)

    game
    |> TeamGame.replace_current_team(first_team)
  end

  defp set_starting_score(%{current_team: current_team, teams: teams} = game) do
    next_team =
      Enum.at(teams, other_team_index(current_team))
      |> Map.put(:score, 8)

    game
    |> TeamGame.replace_current_team(%{current_team | score: 9})
    |> TeamGame.update_team(next_team)
  end

  defp new_turn(%{current_team: current_team} = game) do
    turn = Turn.new(%{extra_guess?: extra_guess?(current_team.turns)})

    game
    |> Map.put(:current_turn, turn)
  end

  defp extra_guess?([] = _turns), do: false

  defp extra_guess?(turns) do
    remaining_guesses =
      turns
      |> Enum.reduce(0, fn turn, acc -> acc + (turn.number_of_words - turn.num_correct) end)

    remaining_guesses > 0
  end

  defp create_board(game) do
    {cards, remaining_deck} = draw_cards(game)

    board =
      for n <- 0..4, m <- 0..4, into: %{} do
        {{n, m}, Enum.at(cards, n * 5 + m)}
      end

    game
    |> Map.put(:board, board)
    |> Map.put(:deck, remaining_deck)
  end

  defp draw_cards(%{deck: deck, current_team: current_team} = _game) do
    {cards, remaining_deck} =
      deck
      |> Enum.shuffle()
      |> Cards.draw(25)

    assigned_cards =
      cards
      |> Enum.with_index()
      |> Enum.map(&assign_card_type(&1, current_team))

    {assigned_cards, remaining_deck}
  end

  defp assign_card_type({word, index}, %{index: 0} = _current_team) do
    generate_cards({word, index}, :red, :blue)
  end

  defp assign_card_type({word, index}, %{index: 1} = _current_team) do
    generate_cards({word, index}, :blue, :red)
  end

  defp generate_cards({word, index}, first_team_color, second_team_color) do
    cond do
      index < 9 ->
        Card.new(%{word: word, type: first_team_color})

      index < 17 ->
        Card.new(%{word: word, type: second_team_color})

      index < 24 ->
        Card.new(%{word: word, type: :bystander})

      index < 25 ->
        Card.new(%{word: word, type: :assassin})
    end
  end

  def give_clue(game, clue_word, number_of_words) do
    with :ok <- validate_clue(clue_word),
         :ok <- validate_number_of_words(number_of_words) do
      game
      |> put_in([:current_turn, :clue], clue_word)
      |> put_in([:current_turn, :number_of_words], number_of_words)
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_number_of_words(number_of_words)
       when is_integer(number_of_words) and (number_of_words < 1 or number_of_words > 9) do
    {:error, "Number of words must be between 1 and 9 or 'Unlimited'"}
  end

  defp validate_number_of_words(number_of_words)
       when is_bitstring(number_of_words) and number_of_words != "Unlimited" do
    {:error, "Number of words must be between 1 and 9 or 'Unlimited'"}
  end

  defp validate_number_of_words(_number_of_words), do: :ok

  defp validate_clue(""), do: {:error, "Clue must not be empty."}

  defp validate_clue(clue_word) do
    if String.contains?(clue_word, " ") do
      {:error, "Clue must be one word (no spaces)."}
    else
      :ok
    end
  end

  def select_card(%{board: board} = game, board_coordinates) do
    card = get_card(board, board_coordinates)

    case do_select_card(card, game) do
      {:error, reason} ->
        {:error, reason}

      new_game ->
        new_game
        |> flip_card(board_coordinates)
    end
  end

  def get_card(board, board_coordinates) do
    Map.get(board, board_coordinates)
  end

  def flip_card(game, board_coordinates) do
    game
    |> put_in([:board, Access.key!(board_coordinates), :flipped?], true)
  end

  def do_select_card(%{flipped?: true} = _card, _game) do
    {:error, "Card already flipped."}
  end

  def do_select_card(%{type: :bystander} = _card, game) do
    game
    |> TeamGame.next_team()
  end

  def do_select_card(%{type: :assassin} = _card, %{current_team: current_team} = game) do
    game
    |> game_over(other_team_index(current_team))
  end

  def do_select_card(%{type: type} = _card, %{current_team: current_team} = game)
      when (current_team.index == 0 and type == :red) or
             (current_team.index == 1 and type == :blue) do
    game
    |> decrement_team_score(other_team_index(current_team))
    |> game_maybe_over
    |> TeamGame.next_team()
  end

  def do_select_card(_card, %{current_team: current_team} = game) do
    game
    |> decrement_team_score(current_team.index)
    |> game_maybe_over
    |> turn_maybe_over
  end

  defp decrement_team_score(%{current_team: current_team} = game, team_idx)
       when current_team.index == team_idx do
    game
    |> update_in([:current_team, :score], &(&1 - 1))
  end

  defp decrement_team_score(game, team_idx) do
    game
    |> update_in([:teams, Access.at!(team_idx), :score], &(&1 - 1))
  end

  defp other_team_index(current_team) do
    rem(current_team.index + 1, 2)
  end

  defp game_maybe_over(%{current_team: current_team, teams: teams} = game) do
    cond do
      current_team.score == 0 ->
        game
        |> game_over(current_team.index)

      Enum.at(teams, other_team_index(current_team)).score == 0 ->
        game
        |> game_over(other_team_index(current_team))

      true ->
        game
    end
  end

  defp game_over(game, winning_team_idx) do
    game
    |> Map.put(:winning_team_idx, winning_team_idx)
    |> Map.put(:finished?, true)
  end

  defp turn_maybe_over(%{current_turn: current_turn} = game)
       when current_turn.number_of_words == "Unlimited" do
    game
  end

  defp turn_maybe_over(%{current_turn: current_turn} = game)
       when current_turn.extra_guess? and
              current_turn.num_correct >= current_turn.number_of_words + 1 do
    game
    |> TeamGame.next_team()
  end

  defp turn_maybe_over(%{current_turn: current_turn} = game)
       when current_turn.num_correct >= current_turn.number_of_words do
    game
    |> TeamGame.next_team()
  end

  defp turn_maybe_over(game), do: game
end
