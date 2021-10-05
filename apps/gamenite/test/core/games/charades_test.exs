defmodule CharadesCoreTest do
  use ExUnit.Case
  use GameBuilders

  alias Gamenite.Games.Charades
  alias Gamenite.Games.{CharadesGame, CharadesPlayer, CharadesTurn}

  defp working_game(context) do
    teams = GameBuilders.build_teams()

    {:ok, game} = CharadesGame.new(%{teams: teams, deck: 1..3})
    |> CharadesGame.create()

    {:ok , Map.put(context, :game, game)}
  end

  describe "drawing card puts card into current player", %{game: game} do
    game
    |> Charades.draw_card()
    |> assert_card_drawn(1)
    |> Charades.draw_card()
    |> assert_card_drawn(2)
    |> Charades.draw_card()
    |> assert_card_drawn(3)
    |> Charades.draw_card()
    |> assert_not_enough_in_deck()
  end

  defp assert_card_drawn(%{current_team: current_team} = game, card) do
    assert current_team.current_player.card == card
  end

  defp assert_card_drawn(error) do
    assert error == {:error, "Not enough cards in deck."}
  end

  describe "update fields" do
    setup [:working_game]

    test "update deck", %{game: game} do
      game_with_new_deck = TeamGame.update_deck(game, [1, 2, 3])
      assert game_with_new_deck.deck == [1, 2, 3]
    end

    test "update current hand", %{game: game} do
      updated_game = TeamGame.update_current_hand(game, [1, 2, 3])
      assert updated_game.current_team.current_player.hand == [1, 2, 3]
    end
  end
end


# test "current round is set to first in list", %{game: game} do
#   assert game.current_round == List.first(game.rounds)
# end
