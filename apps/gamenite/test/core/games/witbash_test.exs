defmodule WitbashTest do
  use ExUnit.Case
  use GameBuilders

  alias Gamenite.Witbash
  alias Gamenite.Witbash.Prompt
  alias Gamenite.TeamGame.Player

  @prompts [
    "What would you do with a klondike bar?",
    "The best lubricant is ______.",
    "Evan Sorenson's hairline reminds you of _______.",
    "____ : the best thing since sliced bread.",
    "Some promp this is.",
    "Some promp this is.",
    "Some promp this is.",
    "Some promp this is.",
    "Some promp this is.",
    "Some promp this is.",
    "Some promp this is.",
    "Some promp this is.",
    "Some promp this is.",
    "Some promp this is.",
    "Some promp this is.",
    "Some promp this is.",
    "Some promp this is.",
    "Some promp this is.",
    "Some promp this is.",
    "Some promp this is.",
    "Some promp this is.",
    "Some promp this is.",
    "Some promp this is.",
    "Some promp this is."
  ]

  defp create_game() do
    players = build_players(4, Player.create(%{}))

    Witbash.create(%{room_slug: "ABCDEF", players: players, deck_of_prompts: @prompts})
  end

  defp working_game(context) do
    {:ok, game} = create_game()

    {:ok, Map.put(context, :game, game)}
  end

  def game_already_setup(context) do
    {:ok, game} = create_game()
    {:ok, Map.put(context, :setup_game, Witbash.setup(game))}
  end

  defp final_round(context) do
    {:ok, game} = create_game()

    {:ok,
     Map.put(context, :final_round, %{
       game
       | current_round: 3,
         final_prompt: %Prompt{is_final?: true}
     })}
  end

  describe "creating game" do
    test "not enough prompts" do
      players = build_players(11)

      assert match?(
               {:error, _},
               Witbash.create(%{room_slug: "ABCDEF", players: players, deck_of_prompts: @prompts})
             )
    end

    test "required to have at least (num players * 4 + 1) prompts" do
      players = build_players(3)

      assert match?(
               {:ok, _},
               Witbash.create(%{
                 room_slug: "ABCDEF",
                 players: players,
                 deck_of_prompts: @prompts
               })
             )
    end

    test "need at least 3 players" do
      players = build_players(2)

      assert match?(
               {:error, _},
               Witbash.create(%{
                 room_slug: "ABCDEF",
                 players: players,
                 deck_of_prompts: @prompts
               })
             )
    end
  end

  describe "setup game" do
    setup [:game_already_setup]

    test "number of prompts equals number of players", %{setup_game: game} do
      assert length(game.prompts) == length(game.players)
    end

    test "each players is assigned two prompts", %{setup_game: game} do
      for player <- game.players do
        num_prompts =
          Enum.reduce(
            game.prompts,
            0,
            fn
              prompt, acc ->
                if player.id in prompt.assigned_player_ids do
                  acc + 1
                else
                  acc
                end
            end
          )

        assert num_prompts == 2
      end
    end

    test "each prompt has two unique players assigned", %{setup_game: game} do
      for prompt <- game.prompts do
        assert length(Enum.uniq(prompt.assigned_player_ids)) == 2
      end
    end
  end

  describe "submitting prompts" do
    setup [:game_already_setup, :working_game]

    test "submit blank answer", %{setup_game: game} do
      assert {:error, "Answer cannot be blank."} == Witbash.submit_answer(game, 0, "", 0)
    end

    test "submit answer over max characters", %{setup_game: game} do
      assert {:error, "Answer is over 80 characters."} ==
               Witbash.submit_answer(game, 0, String.duplicate("d", 81), 0)
    end

    test "player1 submits valid answer", %{game: game} do
      new_game =
        %{game | prompts: [%Prompt{id: 0, assigned_player_ids: [1, 2]}]}
        |> Witbash.submit_answer(0, "My booty.", 1)

      assert hd(Enum.at(new_game.prompts, 0).answers) == {1, "My booty."}
      assert length(Enum.at(new_game.prompts, 0).answers) == 1
    end

    test "player2 submits valid answer", %{game: game} do
      new_game =
        %{game | prompts: [%Prompt{id: 0, assigned_player_ids: [1, 2]}]}
        |> Witbash.submit_answer(0, "Your booty.", 2)

      assert hd(Enum.at(new_game.prompts, 0).answers) == {2, "Your booty."}
      assert length(Enum.at(new_game.prompts, 0).answers) == 1
    end

    test "player not assigned to prompt", %{game: game} do
      new_game = %{game | prompts: [%Prompt{id: 0, assigned_player_ids: [1, 2]}]}

      assert {:error, "Player not assigned to prompt."} ==
               Witbash.submit_answer(new_game, 0, "My booty.", 3)
    end

    test "player submits both prompts" do
    end
  end

  describe "final round" do
    setup [:final_round]

    test "submit blank answer", %{final_round: game} do
      assert {:error, "Answer cannot be blank."} == Witbash.submit_final_answer(game, "", 1)
    end

    test "submit answer over max characters", %{final_round: game} do
      assert {:error, "Answer is over 80 characters."} ==
               Witbash.submit_final_answer(game, String.duplicate("d", 81), 1)
    end

    test "player submits valid answer", %{final_round: game} do
      new_game = Witbash.submit_final_answer(game, "valid answer", 1)
      assert hd(new_game.final_prompt.answers) == {1, "valid answer"}
      assert length(new_game.final_prompt.answers) == 1
    end
  end

  describe "voting on answers:" do
    setup [:game_already_setup]

    test "voting for self", %{setup_game: game} do
      assert Witbash.vote(game, {1, 1}) == {:error, "Cannot vote for yourself."}
    end

    test "valid vote", %{setup_game: game} do
      new_game =
        %{game | current_prompt: %Prompt{}}
        |> Witbash.vote({1, 2})

      assert length(new_game.current_prompt.votes) == 1
      assert hd(new_game.current_prompt.votes) == {1, 2}
    end

    # test "next prompt", %{game_with_prompts: game_with_prompts} do
    #   Witbash.next_prompt(game_with_prompts)
    #   # pop prompt from prompts map -> move to current_prompt
    # end
  end

  describe "scoring votes:" do
    setup [:game_already_setup]

    test "one player gets all votes", %{setup_game: game} do
      new_game =
        %{game | current_prompt: %Prompt{votes: [{2, 1}, {3, 1}, {4, 1}, {5, 1}]}}
        |> Witbash.score_votes()

      assert Enum.at(new_game.players, 0).score == 100
      assert Enum.at(new_game.players, 1).score == 0
    end

    test "votes 3/4 and 1/4", %{setup_game: game} do
      new_game =
        %{game | current_prompt: %Prompt{votes: [{2, 1}, {3, 1}, {4, 1}, {5, 2}]}}
        |> Witbash.score_votes()

      assert Enum.at(new_game.players, 0).score == 75
      assert Enum.at(new_game.players, 1).score == 25
    end

    test "votes half and half", %{setup_game: game} do
      new_game =
        %{game | current_prompt: %Prompt{votes: [{2, 2}, {3, 1}, {4, 1}, {5, 2}]}}
        |> Witbash.score_votes()

      assert Enum.at(new_game.players, 0).score == 50
      assert Enum.at(new_game.players, 1).score == 50
    end

    test "final round - one player gets all votes", %{setup_game: game} do
      new_game =
        %{
          game
          | current_round: 3,
            current_prompt: %Prompt{votes: [{2, 1}, {3, 1}, {4, 1}, {5, 1}]}
        }
        |> Witbash.score_votes()

      assert Enum.at(new_game.players, 0).score == 400
      assert Enum.at(new_game.players, 1).score == 0
    end

    test "final round -votes 1/2 and 1/4 and 1/4", %{setup_game: game} do
      new_game =
        %{
          game
          | current_round: 3,
            current_prompt: %Prompt{votes: [{2, 1}, {3, 2}, {4, 1}, {5, 3}]}
        }
        |> Witbash.score_votes()

      assert Enum.at(new_game.players, 0).score == 200
      assert Enum.at(new_game.players, 1).score == 100
      assert Enum.at(new_game.players, 2).score == 100
    end

    test " final round - votes 1/4 all arou d", %{setup_game: game} do
      new_game =
        %{
          game
          | current_round: 3,
            current_prompt: %Prompt{votes: [{2, 4}, {3, 3}, {4, 2}, {5, 1}]}
        }
        |> Witbash.score_votes()

      assert Enum.at(new_game.players, 0).score == 100
      assert Enum.at(new_game.players, 1).score == 100
      assert Enum.at(new_game.players, 2).score == 100
      assert Enum.at(new_game.players, 3).score == 100
    end
  end

  describe "changing phases (answering, voting, repeat)" do
    test "all users submitted two answers" do
    end

    test "all users voted" do
    end

    test "change phase answering -> voting" do
    end

    test "change phase voting -> answering" do
    end
  end
end
