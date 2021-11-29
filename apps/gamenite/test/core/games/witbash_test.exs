defmodule WitbashTest do
  use ExUnit.Case
  use GameBuilders

  alias Gamenite.Witbash
  alias Gamenite.Witbash.{Prompt, Answer}
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

    Witbash.create(%{room_slug: "ABCDEF", players: players, deck: @prompts})
  end

  defp working_game(context) do
    game =
      create_game()
      |> elem(1)
      |> Map.put(:prompts, [%Prompt{assigned_user_ids: [1, 2]}])

    {:ok, Map.put(context, :game, game)}
  end

  defp answers(context) do
    {:ok, game} = create_game()

    new_context =
      context
      |> Map.put(
        :player1_answer,
        %Answer{user_id: 1, answer: "player 1 answer", prompt_index: 0}
      )
      |> Map.put(
        :player2_answer,
        %Answer{user_id: 2, answer: "player 2 answer", prompt_index: 0}
      )
      |> Map.put(
        :blank_answer,
        %Answer{user_id: 1, answer: "", prompt_index: 0}
      )
      |> Map.put(
        :too_long_answer,
        %Answer{user_id: 1, answer: String.duplicate("d", 81), prompt_index: 0}
      )
      |> Map.put(
        :unassigned_user_answer,
        %Answer{user_id: 3, answer: "player 3 answer", prompt_index: 0}
      )

    {:ok, new_context}
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
         final_round?: true,
         current_prompt: %Prompt{
           assigned_user_ids: [1, 2, 3, 4],
           answers: [
             %Answer{user_id: 1, prompt_index: 0},
             %Answer{user_id: 2, prompt_index: 0},
             %Answer{user_id: 3, prompt_index: 0},
             %Answer{user_id: 4, prompt_index: 0}
           ]
         }
     })}
  end

  describe "creating game" do
    test "not enough prompts" do
      players = build_players(11)

      assert match?(
               {:error, _},
               Witbash.create(%{room_slug: "ABCDEF", players: players, deck: @prompts})
             )
    end

    test "required to have at least (num players * 4 + 1) prompts" do
      players = build_players(3)

      assert match?(
               {:ok, _},
               Witbash.create(%{
                 room_slug: "ABCDEF",
                 players: players,
                 deck: @prompts
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
                 deck: @prompts
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
                if player.id in prompt.assigned_user_ids do
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
        assert length(Enum.uniq(prompt.assigned_user_ids)) == 2
      end
    end

    test "in answering phase after setup", %{setup_game: game} do
      assert game.answering?
    end
  end

  describe "submitting answers" do
    setup [:working_game, :answers]

    test "submit blank answer", %{game: game, blank_answer: blank_answer} do
      assert {:error, "Answer cannot be blank."} ==
               Witbash.submit_answer(game, blank_answer)
    end

    test "submit answer over max characters", %{
      game: game,
      too_long_answer: too_long_answer
    } do
      assert {:error, "Answer is over 80 characters."} ==
               Witbash.submit_answer(game, too_long_answer)
    end

    test "player1 submits valid answer", %{game: game, player1_answer: player1_answer} do
      new_game = Witbash.submit_answer(game, player1_answer)

      assert hd(Enum.at(new_game.prompts, 0).answers) == player1_answer
      assert length(Enum.at(new_game.prompts, 0).answers) == 1
    end

    test "player2 submits valid answer", %{game: game, player2_answer: player2_answer} do
      new_game = Witbash.submit_answer(game, player2_answer)

      assert hd(Enum.at(new_game.prompts, 0).answers) == player2_answer
      assert length(Enum.at(new_game.prompts, 0).answers) == 1
    end

    test "player not assigned to prompt", %{
      game: game,
      unassigned_user_answer: unassigned_answer
    } do
      assert {:error, "Player not assigned to prompt."} ==
               Witbash.submit_answer(game, unassigned_answer)
    end

    test "player submits both answers (not final round), add to submitted users" do
    end

    test "player submits answer (final round), add to submitted users" do
    end
  end

  describe "voting on answers (not final round):" do
    setup [:game_already_setup]

    test "voting for self", %{setup_game: game} do
      assert Witbash.vote(game, {1, 1}) == {:error, "Cannot vote for yourself."}
    end

    test "voting when your answered prompt is up", %{setup_game: game} do
      assert {:error, "Cannot vote when your answer is up."} ==
               %{game | current_prompt: %Prompt{assigned_user_ids: [1]}}
               |> Witbash.vote({1, 2})
    end

    test "valid vote", %{setup_game: game} do
      new_game =
        %{game | current_prompt: %Prompt{answers: [%Answer{user_id: 2, votes: []}]}}
        |> Witbash.vote({1, 2})

      answer = hd(new_game.current_prompt.answers)
      assert length(answer.votes) == 1
      assert hd(answer.votes) == 1
    end
  end

  describe "voting on answers final round:" do
    setup [:final_round]

    test "voting for self", %{final_round: game} do
      assert Witbash.vote(game, {1, 1}) == {:error, "Cannot vote for yourself."}
    end

    test "valid vote", %{final_round: game} do
      new_game =
        game
        |> Witbash.vote({2, 1})

      answer = hd(new_game.current_prompt.answers)
      assert length(answer.votes) == 1
      assert hd(answer.votes) == 2
    end

    test "player votes 2 times -> user is not submitted", %{final_round: game} do
      new_game =
        game
        |> Witbash.vote({2, 1})
        |> Witbash.vote({2, 3})

      assert length(new_game.submitted_user_ids) == 0
    end

    test "player votes 3 times -> user is fully submitted", %{final_round: game} do
      new_game =
        game
        |> Witbash.vote({2, 1})
        |> Witbash.vote({2, 3})
        |> Witbash.vote({2, 1})

      assert length(new_game.submitted_user_ids) == 1
      assert hd(new_game.submitted_user_ids) == 2
    end
  end

  describe "scoring votes:" do
    setup [:game_already_setup]

    test "one player gets all votes", %{setup_game: game} do
      new_game =
        %{
          game
          | current_prompt: %Prompt{
              answers: [%Answer{user_id: 1, votes: [2, 3, 4, 5]}, %Answer{user_id: 2, votes: []}]
            }
        }
        |> Witbash.score_votes()

      assert Enum.at(new_game.players, 0).score == 100
      assert Enum.at(new_game.players, 1).score == 0
    end

    test "votes 3/4 and 1/4", %{setup_game: game} do
      new_game =
        %{
          game
          | current_prompt: %Prompt{
              answers: [%Answer{user_id: 1, votes: [2, 3, 4]}, %Answer{user_id: 2, votes: [5]}]
            }
        }
        |> Witbash.score_votes()

      assert Enum.at(new_game.players, 0).score == 75
      assert Enum.at(new_game.players, 1).score == 25
    end

    test "votes half and half", %{setup_game: game} do
      new_game =
        %{
          game
          | current_prompt: %Prompt{
              answers: [%Answer{user_id: 1, votes: [3, 4]}, %Answer{user_id: 2, votes: [2, 5]}]
            }
        }
        |> Witbash.score_votes()

      assert Enum.at(new_game.players, 0).score == 50
      assert Enum.at(new_game.players, 1).score == 50
    end

    test "final round - one player gets all votes", %{setup_game: game} do
      new_game =
        %{
          game
          | final_round?: true,
            current_prompt: %Prompt{
              answers: [%Answer{user_id: 1, votes: [2, 3, 4, 5]}, %Answer{votes: []}]
            }
        }
        |> Witbash.score_votes()

      assert Enum.at(new_game.players, 0).score == 400
      assert Enum.at(new_game.players, 1).score == 0
    end

    test "final round -votes 1/2 and 1/4 and 1/4", %{setup_game: game} do
      new_game =
        %{
          game
          | final_round?: true,
            current_prompt: %Prompt{
              answers: [
                %Answer{user_id: 1, votes: [2, 3]},
                %Answer{user_id: 2, votes: [4]},
                %Answer{user_id: 3, votes: [5]}
              ]
            }
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
          | final_round?: true,
            current_prompt: %Prompt{
              answers: [
                %Answer{user_id: 1, votes: [3]},
                %Answer{user_id: 2, votes: [2]},
                %Answer{user_id: 3, votes: [4]},
                %Answer{user_id: 4, votes: [5]}
              ]
            }
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
              %Prompt{assigned_user_ids: [1, 4]},
              %Prompt{assigned_user_ids: [1, 4]}
            ]
        }
        |> Witbash.submit_answer(%Answer{answer: "answer", user_id: 4, prompt_index: 0})
        |> Witbash.submit_answer(%Answer{answer: "answer", user_id: 4, prompt_index: 1})

      refute new_game.answering?
    end

    test "all users voted and more prompts -> score votes", %{setup_game: game} do
      new_game =
        %{
          game
          | prompts: [%Prompt{}],
            submitted_user_ids: [3],
            current_prompt: %Prompt{
              answers: [%Answer{user_id: 1}],
              assigned_user_ids: [2]
            }
        }
        |> Witbash.vote({3, 1})

      assert Enum.at(new_game.players, 0).score == 100
    end

    test "next prompt", %{setup_game: game} do
      new_game =
        %{
          game
          | prompts: [%Prompt{}],
            submitted_user_ids: [1, 3, 4],
            current_prompt: %Prompt{assigned_user_ids: [1, 2]}
        }
        |> Witbash.next_prompt()

      assert new_game.current_prompt == %Prompt{}
      assert length(new_game.submitted_user_ids) == 0
    end

    test "move onto final round -> check setup", %{setup_game: game} do
      new_game =
        %{
          game
          | current_round: 2,
            deck: ["Some prompt."],
            prompts: [],
            current_prompt: %Prompt{assigned_user_ids: [1, 2]}
        }
        |> Witbash.next_prompt()

      assert new_game.final_round?
      assert length(new_game.prompts) == 1
      assert hd(new_game.prompts).prompt == "Some prompt."
      assert hd(new_game.prompts).assigned_user_ids == Enum.map(game.players, & &1.id)
    end

    test "no prompts left-> next round and answering phase", %{setup_game: game} do
      new_game =
        %{
          game
          | prompts: [],
            current_prompt: %Prompt{assigned_user_ids: [1, 2]}
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
          | final_round?: true,
            prompts: []
        }
        |> Witbash.next_prompt()

      assert new_game.finished?
    end
  end
end
