defmodule Gamenite.Games.Horsepaste do
  import Ecto.Changeset

  alias Gamenite.TeamGame
  alias Gamenite.Cards

  alias Gamenite.Games.Horsepaste.{Game, Turn}

  def change_game(%Game{} = game, attrs \\ %{}) do
    game
    |> Game.changeset(attrs)
  end

  def create_game(attrs) do
    %Game{}
    |> Game.changeset(attrs)
    |> apply_action(:update)
  end

  def setup_game(game, randomize_first_team? \\ true)

  def setup_game(game, true) do
    game
    |> randomize_team
    |> new_turn
    |> create_board
  end

  def setup_game(game, false) do
    game
    |> new_turn
    |> create_board
  end

  defp randomize_team(game) do
    first_team = Enum.random(game.teams)

    game
    |> TeamGame.replace_current_team(first_team)
  end

  defp new_turn(%{current_team: current_team} = game) do
    turn = Turn.new(%{})

    game
    |> Map.put(:current_turn, turn)
  end

  defp create_board(game) do
    cards = draw_cards(game)

    board =
      for n <- 0..4, m <- 0..4, into: %{} do
        {{n, m}, Enum.at(cards, n * 5 + m)}
      end

    game
    |> Map.put(:board, board)
  end

  defp draw_cards(%{deck: deck, current_team: current_team} = _game) do
    {cards, remaining_deck} =
      deck
      |> Enum.shuffle()
      |> Cards.draw(25)

    cards
    |> Enum.with_index()
    |> Enum.map(&assign_card_type(&1, current_team))
  end

  defp assign_card_type({card, index}, %{index: 0} = _current_team) do
    generate_cards({card, index}, :red, :blue)
  end

  defp assign_card_type({card, index}, %{index: 1} = _current_team) do
    generate_cards({card, index}, :blue, :red)
  end

  defp generate_cards({card, index}, first_team_color, second_team_color) do
    cond do
      index < 9 ->
        {first_team_color, card}

      index < 17 ->
        {second_team_color, card}

      index < 24 ->
        {:bystander, card}

      index < 25 ->
        {:assassin, card}
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
end
