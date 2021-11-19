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
         current_prompt: %Prompt{is_final?: true}
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

    test "in answering phase after setup", %{setup_game: game} do
      assert game.answering?
    end
  end

  describe "submitting prompts" do
    setup [:game_already_setup, :working_game]

    test "submit blank answer", %{setup_game: game} do
      assert {:error, "Answer cannot be blank."} == Witbash.submit_answer(game, "", 0, 0)
    end

    test "submit answer over max characters", %{setup_game: game} do
      assert {:error, "Answer is over 80 characters."} ==
               Witbash.submit_answer(game, String.duplicate("d", 81), 0, 0)
    end

    test "player1 submits valid answer", %{game: game} do
      new_game =
        %{game | prompts: [%Prompt{id: 0, assigned_player_ids: [1, 2]}]}
        |> Witbash.submit_answer("My booty.", 1, 0)

      assert hd(Enum.at(new_game.prompts, 0).answers) == {1, "My booty."}
      assert length(Enum.at(new_game.prompts, 0).answers) == 1
    end

    test "player2 submits valid answer", %{game: game} do
      new_game =
        %{game | prompts: [%Prompt{id: 0, assigned_player_ids: [1, 2]}]}
        |> Witbash.submit_answer("Your booty.", 2, 0)

      assert hd(Enum.at(new_game.prompts, 0).answers) == {2, "Your booty."}
      assert length(Enum.at(new_game.prompts, 0).answers) == 1
    end

    test "player not assigned to prompt", %{game: game} do
      new_game = %{game | prompts: [%Prompt{id: 0, assigned_player_ids: [1, 2]}]}

      assert {:error, "Player not assigned to prompt."} ==
               Witbash.submit_answer(new_game, "My booty.", 3, 0)
    end

    test "player submits both prompts, add to submitted users" do
    end
  end

  describe "final round" do
    setup [:final_round]

    test "submit blank answer", %{final_round: game} do
      assert {:error, "Answer cannot be blank."} == Witbash.submit_answer(game, "", 1)
    end

    test "submit answer over max characters", %{final_round: game} do
      assert {:error, "Answer is over 80 characters."} ==
               Witbash.submit_answer(game, String.duplicate("d", 81), 1)
    end

    test "player submits valid answer", %{final_round: game} do
      new_game = Witbash.submit_answer(game, "valid answer", 1)
      assert hd(new_game.current_prompt.answers) == {1, "valid answer"}
      assert length(new_game.current_prompt.answers) == 1
    end
  end

  describe "voting on answers:" do
    setup [:game_already_setup]

    test "voting for self", %{setup_game: game} do
      assert Witbash.vote(game, {1, 1}) == {:error, "Cannot vote for yourself."}
    end

    test "voting when your answered prompt is up", %{setup_game: game} do
      assert {:error, "Cannot vote when your answer is up."} ==
               %{game | current_prompt: %Prompt{assigned_player_ids: [1]}}
               |> Witbash.vote({1, 2})
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

    test " final round - votes 1/4 all aroud", %{setup_game: game} do
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
    setup [:game_already_setup, :final_round]

    test "all users submitted two answers -> voting phase", %{setup_game: game} do
      new_game =
        %{
          game
          | current_round: 1,
            submitted_user_ids: [1, 2, 3],
            prompts: [
              %Prompt{assigned_player_ids: [1, 4]},
              %Prompt{assigned_player_ids: [1, 4]}
            ]
        }
        |> Witbash.submit_answer("answer", 4, 0)
        |> Witbash.submit_answer("answer", 4, 1)

      refute new_game.answering?
    end

    test "all users voted and more prompts -> score votes", %{setup_game: game} do
      new_game =
        %{
          game
          | prompts: [%Prompt{}],
            submitted_user_ids: [3],
            current_prompt: %Prompt{assigned_player_ids: [1, 2], votes: [{3, 1}]}
        }
        |> Witbash.vote({4, 2})

      assert Enum.at(new_game.players, 0).score == 50
      assert Enum.at(new_game.players, 1).score == 50
    end

    test "next prompt", %{setup_game: game} do
      new_game =
        %{
          game
          | prompts: [%Prompt{}],
            submitted_user_ids: [1, 3, 4],
            current_prompt: %Prompt{assigned_player_ids: [1, 2], votes: [{3, 1}]}
        }
        |> Witbash.next_prompt()

      assert new_game.current_prompt == %Prompt{}
      assert length(new_game.submitted_user_ids) == 0
    end

    test "no prompts left-> next round and answering phase", %{setup_game: game} do
      new_game =
        %{
          game
          | prompts: [],
            current_prompt: %Prompt{assigned_player_ids: [1, 2], votes: [{3, 1}]}
        }
        |> Witbash.next_prompt()

      assert new_game.answering?
      assert length(new_game.submitted_user_ids) == 0
      assert new_game.current_round == 2
      assert length(new_game.prompts) == 4
    end

    test "next prompt in last round -> game finished", %{setup_game: game} do
      new_game =
        %{
          game
          | current_round: 3,
            prompts: [1, 3],
            current_prompt: %Prompt{assigned_player_ids: [1, 2], votes: [{3, 1}]}
        }
        |> Witbash.next_prompt()

      assert new_game.finished?
    end
  end
end
