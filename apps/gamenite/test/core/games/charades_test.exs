defmodule CharadesCoreTest do
  use ExUnit.Case
  use GameBuilders

  alias Gamenite.Charades
  alias Gamenite.SaladBowl

  defp working_game(context) do
    teams = build_teams([2, 2], %Player{})
    deck = build_deck(3)

    game =
      Charades.create(%{teams: teams, deck: deck, skip_limit: 3})
      |> elem(1)
      |> Map.put(
        :current_turn,
        Charades.create_turn(%{card: 1, correct_cards: [4, 5], skipped_cards: [6, 7]})
      )

    new_context =
      context
      |> Map.put(:game, game)

    {:ok, new_context}
  end

  defp build_salad_bowl(context) do
    teams = build_teams([2, 2], %Player{})
    deck = build_deck(3)

    salad_bowl =
      SaladBowl.create(%{
        teams: teams,
        deck: deck,
        skip_limit: 1,
        rounds: ["Catchphrase", "Password", "Charades"]
      })
      |> elem(1)

    {:ok, Map.put(context, :salad_bowl, salad_bowl)}
  end

  describe "setup game" do
    setup [:working_game, :build_salad_bowl]

    test "current round is set to first in list", %{salad_bowl: salad_bowl} do
      assert salad_bowl.current_round == "Catchphrase"
    end
  end

  describe "end turn" do
    setup [:working_game]

    test "skipped or incorrect cards back to deck", %{game: game} do
      new_game = Charades.move_cards_after_review(game)

      assert length(new_game.deck) == 6
      assert Enum.member?(new_game.deck, 1)
      assert Enum.member?(new_game.deck, 6)
      assert Enum.member?(new_game.deck, 7)
      refute Enum.member?(new_game.deck, 4)
      refute Enum.member?(new_game.deck, 5)
    end

    test "new turn created", %{game: game} do
      turn = Charades.new_turn(game)
      assert turn.user_id == game.current_team.current_player.id
    end
  end

  describe "update fields" do
    setup [:working_game]

    test "update deck", %{game: game} do
      game_with_new_deck = Charades.update_deck(game, [1, 2, 3])
      assert game_with_new_deck.deck == [1, 2, 3]
    end
  end

  describe "card logic" do
    setup [:working_game]

    test "card is added to correct cards in turn when correct", %{game: game} do
      game
      |> Charades.correct_card()
      |> assert_card_moved(:correct_cards, 3)
      |> assert_card_nil
    end

    test "skips card successfully", %{game: game} do
      game
      |> Charades.skip_card()
      |> assert_card_moved(:skipped_cards, 3)
      |> assert_card_nil
    end

    test "skip cart but limit is reached", %{game: game} do
      %{game | skip_limit: 0}
      |> Charades.skip_card()
      |> assert_skip_limit_reached(0)
    end

    test "skip cart but deck is empty", %{game: game} do
      error =
        %{game | deck: []}
        |> Charades.skip_card()

      assert error = {:error, "Cannot skip card. No cards left in deck."}
    end

    defp assert_card_moved(game, pile, length_of_cards) do
      assert length(get_in(game, [:current_turn, pile])) == length_of_cards
      game
    end

    defp assert_review?({:review_cards, game}) do
      assert game.current_turn.review?
      game
    end

    defp assert_skip_limit_reached(error, skip_limit) do
      assert error == {:error, "You have reached skip limit of #{skip_limit}."}
    end

    defp assert_card_nil(%{current_turn: current_turn} = game) do
      assert is_nil(current_turn.card)
      game
    end
  end
end
