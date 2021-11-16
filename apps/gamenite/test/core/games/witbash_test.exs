defmodule WitbashTest do
  use ExUnit.Case
  use GameBuilders

  alias Gamenite.Witbash
  alias Gamenite.Witbash.Prompt

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
    players = build_players(4)

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

    {:ok, Map.put(context, :final_round, %{prompts: %Prompt{}})}
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
      assert map_size(game.prompts) == length(game.players)
    end

    test "each players is assigned two prompts", %{setup_game: game} do
      for player <- game.players do
        num_prompts =
          Enum.reduce(
            Map.to_list(game.prompts),
            0,
            fn
              {k, prompt}, acc ->
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
      assert length(Enum.uniq(game.prompts)) == map_size(game.prompts)
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
        %{game | prompts: %{0 => %Prompt{id: 0, assigned_player_ids: [1, 2]}}}
        |> Witbash.submit_answer(0, "My booty.", 1)

      assert hd(Map.get(new_game.prompts, 0).answers) == {1, "My booty."}
      assert length(Map.get(new_game.prompts, 0).answers) == 1
    end

    test "player2 submits valid answer", %{game: game} do
      new_game =
        %{game | prompts: %{0 => %Prompt{id: 0, assigned_player_ids: [1, 2]}}}
        |> Witbash.submit_answer(0, "Your booty.", 2)

      assert hd(Map.get(new_game.prompts, 0).answers) == {2, "Your booty."}
      assert length(Map.get(new_game.prompts, 0).answers) == 1
    end

    test "player not assigned to prompt submits prompt", %{game: game} do
      new_game = %{game | prompts: %{0 => %Prompt{id: 0, assigned_player_ids: [1, 2]}}}

      assert {:error, "Player not assigned to prompt"} ==
               Witbash.submit_answer(new_game, 0, "My booty.", 3)
    end

    test "player submits both prompts" do
    end
  end

  describe "final round" do
    setup [:final_round]

    test "submit blank answer", %{final_round: game} do
      assert {:error, "Answer cannot be blank."} == Witbash.submit_final_answer(game, "", 0)
    end

    test "submit answer over max characters", %{final_round: game} do
      assert {:error, "Answer is over 80 characters."} ==
               Witbash.submit_final_answer(game, String.duplicate("d", 81), 0)
    end

    test "player submits valid answer" do
    end
  end

  describe "voting on answers" do
  end
end
