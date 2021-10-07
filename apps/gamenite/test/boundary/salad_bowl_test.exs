defmodule SaladBowlTest do
  use ExUnit.Case
  use GameBuilders

  alias Gamenite.SaladBowlAPI

  alias Gamenite.Games.Charades
  alias Gamenite.Games.Charades.{Game, Player}

  defp build_salad_bowl(context) do
    teams = build_teams([2,2], %Player{})
    deck = build_deck(3)

    salad_bowl = Charades.create_salad_bowl(%{teams: teams, deck: deck, skip_limit: 1, rounds: ["Catchphrase", "Password", "Charades"]})
    |> elem(1)

    {:ok, Map.put(context, :salad_bowl, salad_bowl)}
  end

  defp start_game(game) do
    room_slug = Gamenite.RoomAPI.generate_slug
    SaladBowlAPI.start_game(game, room_slug)
    room_slug
  end

  describe "integration testing" do
    setup [:build_salad_bowl]

    # test "score correct cards and add to team score", %{salad_bowl: salad_bowl} do
    #   new_game = Charades.end_turn(salad_bowl)
    #   assert hd(new_game.teams).score == 2
    # end

    test "start turn, get cards correct and skip, run out of deck prompting review", %{salad_bowl: salad_bowl} do
      slug = start_game(salad_bowl)
      {:ok, game } = SaladBowlAPI.start_turn(slug)
      assert game.current_turn.card.face == "1"

      {:ok, game } = SaladBowlAPI.card_completed(slug, :correct)
      assert Charades.count_cards_with_outcome(game.current_turn.completed_cards, :correct) == 1
      assert game.current_turn.card.face == "2"

      {:ok, game } = SaladBowlAPI.card_completed(slug, :skipped)
      assert Charades.count_cards_with_outcome(game.current_turn.completed_cards, :skipped) == 1
      assert game.current_turn.card.face == "3"

      {:error, reason } = SaladBowlAPI.card_completed(slug, :skipped)
      assert {:error, reason } == {:error, "You have reached skip limit of #{game.skip_limit}."}

      {:ok, game} = SaladBowlAPI.card_completed(slug, :correct)
      assert Charades.count_cards_with_outcome(game.current_turn.completed_cards, :correct) == 2
      assert game.current_turn.needs_review
    end

    test "timer runs out during turn", %{salad_bowl: salad_bowl} do
      slug = start_game(%{salad_bowl | turn_length: 1})
      {:ok, game} = SaladBowlAPI.start_turn(slug)
      :timer.sleep(1100)
      {:ok, game} = SaladBowlAPI.state(slug)
      assert game.current_turn.time_remaining_in_sec == 0
      assert game.current_turn.needs_review
    end
  end
end
