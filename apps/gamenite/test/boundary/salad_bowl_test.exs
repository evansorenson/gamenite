defmodule SaladBowlTest do
  use ExUnit.Case
  use GameBuilders

  alias Gamenite.SaladBowlAPI

  alias Gamenite.Games.Charades
  alias Gamenite.Games.Charades.{Game, Player, Turn}

  defp build_salad_bowl(context) do
    teams = build_teams([2, 2], %Player{})

    salad_bowl =
      Charades.create_salad_bowl(%{
        room_slug: "123456",
        teams: teams,
        deck: ["1", "2", "3"],
        skip_limit: 1,
        rounds: ["Catchphrase", "Password", "Charades"],
        current_turn: Turn.new(%{card: "0", time_remaining_in_sec: 1})
      })
      |> elem(1)

    {:ok, Map.put(context, :salad_bowl, salad_bowl)}
  end

  defp finished_turn(context) do
    teams = build_teams([2, 2], %Player{})

    salad_bowl =
      Charades.create_salad_bowl(%{
        room_slug: "123456",
        teams: teams,
        starting_deck: ["1", "2", "3"],
        deck: [],
        skip_limit: 1,
        rounds: ["Catchphrase", "Password", "Charades"],
        current_turn:
          Turn.new(%{
            card: "0",
            time_remaining_in_sec: 0,
            completed_cards: [
              {:correct, "1"},
              {:correct, "2"},
              {:skipped, "3"},
              {:incorrect, "4"}
            ]
          })
      })
      |> elem(1)

    {:ok, Map.put(context, :finished_turn, salad_bowl)}
  end

  defp start_game(game) do
    room_slug = Gamenite.RoomAPI.generate_slug()
    SaladBowlAPI.start_game(game, room_slug)
    room_slug
  end

  describe "card logic testing" do
    setup [:build_salad_bowl]

    test "start turn, draws card", %{salad_bowl: salad_bowl} do
      slug = start_game(salad_bowl)
      {:ok, game} = SaladBowlAPI.start_turn(slug)
      assert game.current_turn.card == "1"
    end

    test "skip card when deck is out", %{salad_bowl: salad_bowl} do
      slug = start_game(%{salad_bowl | deck: []})
      {:error, reason} = SaladBowlAPI.card_completed(slug, :skipped)
      assert {:error, reason} == {:error, "Cannot skip card. No cards left in deck."}
    end

    test "skip card with cards left in deck and under skip limit", %{salad_bowl: salad_bowl} do
      slug = start_game(salad_bowl)
      {:ok, game} = SaladBowlAPI.card_completed(slug, :skipped)
      assert Charades.count_cards_with_outcome(game.current_turn.completed_cards, :skipped) == 1
      assert game.current_turn.card == "1"
      refute game.current_turn.needs_review
    end

    test "skip card when at skip limit", %{salad_bowl: salad_bowl} do
      slug = start_game(%{salad_bowl | skip_limit: 0})
      {:error, reason} = SaladBowlAPI.card_completed(slug, :skipped)
      assert {:error, reason} == {:error, "You have reached skip limit of 0."}
    end

    test "correct card with cards left in deck", %{salad_bowl: salad_bowl} do
      slug = start_game(salad_bowl)

      {:ok, game} = SaladBowlAPI.card_completed(slug, :correct)
      assert Charades.count_cards_with_outcome(game.current_turn.completed_cards, :correct) == 1
      assert game.current_turn.card == "1"
      refute game.current_turn.needs_review
    end

    test "correct card when deck is out and no skipped cards, prompts review", %{
      salad_bowl: salad_bowl
    } do
      slug = start_game(%{salad_bowl | deck: ["1"]})
      {:ok, game} = SaladBowlAPI.start_turn(slug)
      {:ok, game} = SaladBowlAPI.card_completed(slug, :correct)
      assert Charades.count_cards_with_outcome(game.current_turn.completed_cards, :correct) == 1
      assert game.current_turn.needs_review
    end

    test "correct card when deck is out and skipped cards, move first skipped card to current card",
         %{salad_bowl: salad_bowl} do
      slug =
        start_game(%{
          salad_bowl
          | deck: [],
            current_turn: Turn.new(%{card: "0", completed_cards: [{:skipped, "9"}]})
        })

      {:ok, game} = SaladBowlAPI.card_completed(slug, :correct)
      assert Charades.count_cards_with_outcome(game.current_turn.completed_cards, :correct) == 1
      assert Charades.count_cards_with_outcome(game.current_turn.completed_cards, :skipped) == 0
      assert game.current_turn.card == "9"
      refute game.current_turn.needs_review
    end
  end

  describe "turn timer testing" do
    setup [:build_salad_bowl]

    test "timer runs out during turn", %{salad_bowl: salad_bowl} do
      slug = start_game(salad_bowl)
      {:ok, game} = SaladBowlAPI.start_turn(slug)
      :timer.sleep(1100)
      {:ok, game} = SaladBowlAPI.state(slug)
      assert game.current_turn.time_remaining_in_sec == 0
      assert game.current_turn.needs_review
    end
  end

  describe "scoring" do
    # test "score correct cards and add to team score", %{salad_bowl: salad_bowl} do
    #   new_game = Charades.end_turn(salad_bowl)
    #   assert hd(new_game.teams).score == 2
    # end
  end

  describe "submitting cards to bowl" do
    setup [:build_salad_bowl]

    test "submitting duplicate cards returns errors", %{salad_bowl: salad_bowl} do
      slug = start_game(salad_bowl)

      assert {:error, "Duplicate cards sumbitted. Must all be unique."} ==
               SaladBowlAPI.submit_cards(slug, ["apple", "pear", "apple"], 1)
    end

    test "submitting cards already in bowl returns errors", %{salad_bowl: salad_bowl} do
      slug = start_game(%{salad_bowl | deck: ["banana"]})

      assert {:error, ["banana was submitted by another player.\n" | []]} ==
               SaladBowlAPI.submit_cards(slug, ["banana", "apple"], 1)
    end

    test "user already submitted cards", %{salad_bowl: salad_bowl} do
      slug = start_game(%{salad_bowl | submitted_users: [0]})
      SaladBowlAPI.submit_cards(slug, ["apple", "pear"], 0)
    end

    test "successfully submission when cards in deck already", %{salad_bowl: salad_bowl} do
      slug = start_game(salad_bowl)

      {:ok, game} = SaladBowlAPI.submit_cards(slug, ["apple", "pear"], 1)
      assert length(game.deck) == 5
    end

    test "successfully submission when no cards in deck", %{salad_bowl: salad_bowl} do
      slug = start_game(%{salad_bowl | deck: []})

      {:ok, game} = SaladBowlAPI.submit_cards(slug, ["apple", "pear"], 1)
      assert length(game.deck) == 2
    end
  end

  describe "end turn" do
    setup [:finished_turn]

    test "score correct cards and add to team", %{finished_turn: salad_bowl} do
      slug = start_game(salad_bowl)
      {:ok, game} = SaladBowlAPI.end_turn(slug)
      assert hd(game.teams).score == 2
    end

    test "move incorrect cards + current card back to deck and keep correct out", %{
      finished_turn: salad_bowl
    } do
      slug = start_game(salad_bowl)
      {:ok, game} = SaladBowlAPI.end_turn(slug)

      assert "0" in game.deck
      assert "3" in game.deck
      assert "4" in game.deck
      assert "1" not in game.deck
      assert "2" not in game.deck
    end

    test "next team is going", %{finished_turn: salad_bowl} do
      slug = start_game(salad_bowl)
      {:ok, game} = SaladBowlAPI.end_turn(slug)

      assert game.current_team.id != salad_bowl.current_team.id
    end

    test "new turn is created", %{finished_turn: salad_bowl} do
      slug = start_game(salad_bowl)
      {:ok, game} = SaladBowlAPI.end_turn(slug)

      assert game.current_turn != salad_bowl.current_turn
      assert game.current_turn.time_remaining_in_sec == salad_bowl.turn_length
    end

    test "finished round", %{finished_turn: salad_bowl} do
      finished_round_turn =
        Turn.new(%{
          card: nil,
          time_remaining_in_sec: 15,
          completed_cards: [{:correct, "1"}, {:correct, "2"}]
        })

      slug =
        %{salad_bowl | current_turn: finished_round_turn}
        |> start_game()

      {:ok, game} = SaladBowlAPI.end_turn(slug)
      assert game.current_round == "Password"
      assert game.deck == ["1", "2", "3"]
      assert game.current_turn.time_remaining_in_sec == 15
      refute game.finished?
    end

    test "finished game", %{finished_turn: salad_bowl} do
      finished_round_turn =
        Turn.new(%{
          card: nil,
          time_remaining_in_sec: 15,
          completed_cards: [{:correct, "1"}, {:correct, "2"}]
        })

      slug =
        %{salad_bowl | current_turn: finished_round_turn, current_round: "Charades"}
        |> start_game()

      {:ok, game} = SaladBowlAPI.end_turn(slug)
      assert game.finished?
    end
  end
end
