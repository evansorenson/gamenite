defmodule Gamenite.Games.Horsepaste do
  import Ecto.Changeset

  alias Gamenite.TeamGame
  alias Gamenite.Cards

  alias Gamenite.Games.Horsepaste.{Game}

  def change_game(%Game{} = game, attrs \\ %{}) do
    game
    |> Game.changeset(attrs)
  end

  def create_game(attrs) do
    %Game{}
    |> Game.changeset(attrs)
    |> apply_action(:update)
  end

  def setup_game(game) do
    game
    |> randomize_team
    |> create_board
  end

  defp randomize_team(game) do
    first_team = Enum.random(game.teams)

    game
    |> TeamGame.replace_current_team(first_team)
  end

  defp create_board(%{deck: deck} = game) do
    cards = draw_cards(deck)

    board = for n <-  0..4, m <- 0..4, into: %{} do
      {{ n, m }, Enum.at(cards, n * 5 + m)}
    end

    game
    |> Map.put(:board, board)
  end

  defp draw_cards(deck) do
    deck
    |> Enum.shuffle
    |> Cards.draw(25)
    |> Enum.with_index
    |> Enum.map(&assign_card_type/1)
  end

  defp assign_card_type({card, index}) do
    cond do
      index < 9 ->
        {card, :red}
      index < 17 ->
        {card, :blue}
      index < 18 ->
        {card, :assassin}
    end
  end
end
