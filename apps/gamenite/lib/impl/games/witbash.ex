defmodule Gamenite.Witbash do
  @behaviour Gamenite.Game
  use Accessible

  use Ecto.Schema
  import Ecto.Changeset

  alias Gamenite.Witbash.{Prompt, Answer}
  alias Gamenite.TeamGame.Player
  alias Gamenite.Cards
  alias Gamenite.SinglePlayerGame

  embedded_schema do
    field(:room_slug, :string)
    field(:players, {:array, :map})
    field(:current_player, :map)
    field(:deck, {:array, :string})
    field(:prompts, {:array, :map})
    field(:submitted_user_ids, {:array, :string}, default: [])
    field(:current_prompt, :map)
    field(:num_rounds, :integer, default: 3)
    field(:current_round, :integer, default: 1)
    field(:answer_length_in_sec, :integer, default: 120)
    field(:vote_length_in_sec, :integer, default: 60)
    field(:time_remaining_in_sec, :integer)
    field(:answering?, :boolean)
    field :final_round?, :boolean, default: false
    field(:finished?, :boolean, default: false)
  end

  @fields [:deck, :num_rounds, :vote_length_in_sec, :answer_length_in_sec]
  @required [:deck]

  @impl Gamenite.Game
  def changeset(game, attrs) do
    game
    |> cast(attrs, @fields)
    |> validate_required(@required)
    |> validate_number(:num_rounds, greater_than_or_equal_to: 2, less_than_or_equal_to: 10)
    |> validate_number(:answer_length_in_sec,
      greater_than_or_equal_to: 30,
      less_than_or_equal_to: 240
    )
    |> validate_number(:vote_length_in_sec,
      greater_than_or_equal_to: 15,
      less_than_or_equal_to: 120
    )
    |> validate_length(:deck, min: length(Map.get(attrs, :players, 0)) * 4 + 1)
    |> validate_length(:players, min: 3, message: "Need at least three players to start.")
  end

  @impl Gamenite.Game
  def new() do
    %__MODULE__{}
  end

  @impl Gamenite.Game
  def change(game, attrs), do: SinglePlayerGame.change(__MODULE__, game, attrs)

  @impl Gamenite.Game
  def create(attrs), do: SinglePlayerGame.create(__MODULE__, new(), attrs)

  @impl Gamenite.Game
  def setup(game) do
    game
    |> shuffle_prompts
    |> setup_round()
  end

  @impl Gamenite.Game
  def create_player(attr) do
    Player.create(attr)
  end

  defp shuffle_prompts(%{deck: deck} = game) do
    shuffled_deck =
      deck
      |> Enum.shuffle()

    %{game | deck: shuffled_deck}
  end

  def setup_round(game) do
    game
    |> answering_phase
    |> draw_prompts
    |> assign_prompts
  end

  defp answering_phase(game) do
    game
    |> clear_submitted_user_ids
    |> put_answering(true)
  end

  def start_voting_phase(game) do
    game
    |> clear_submitted_user_ids
    |> next_prompt
    |> put_answering(false)
  end

  defp clear_submitted_user_ids(game) do
    %{game | submitted_user_ids: []}
  end

  defp put_answering(game, bool) do
    %{game | answering?: bool}
  end

  defp draw_prompts(game) when game.final_round? do
    do_draw_prompts(game, 1)
  end

  defp draw_prompts(%{players: players} = game) do
    do_draw_prompts(game, length(players))
  end

  defp do_draw_prompts(%{deck: deck} = game, num_prompts) do
    {drawn_prompts, remaining} = Cards.draw(deck, num_prompts)

    prompts =
      drawn_prompts
      |> Enum.map(fn prompt -> %Prompt{prompt: prompt} end)

    %{game | deck: remaining, prompts: prompts}
  end

  defp assign_prompts(%{prompts: [final_prompt | []]} = game) when game.final_round? do
    assigned_prompt = %{final_prompt | assigned_user_ids: Enum.map(game.players, & &1.id)}

    %{game | prompts: [assigned_prompt | []]}
  end

  defp assign_prompts(%{players: players, prompts: prompts} = game) do
    paired_id_list = create_random_player_id_list(players)

    assigned_prompts =
      for {prompt, i} <- Enum.with_index(prompts) do
        assigned_ids = Enum.at(paired_id_list, i)
        %{prompt | assigned_user_ids: assigned_ids}
      end

    %{game | prompts: assigned_prompts}
  end

  defp create_random_player_id_list(players) do
    paired_id_list =
      (random_player_id_list(players) ++ random_player_id_list(players))
      |> Enum.chunk_every(2)

    if Enum.any?(paired_id_list, fn [id1, id2] -> id1 == id2 end) do
      create_random_player_id_list(players)
    else
      paired_id_list
    end
  end

  defp random_player_id_list(players) do
    players
    |> Enum.map(fn player -> player.id end)
    |> Enum.shuffle()
  end

  def validate_answer(_prompt, %{answer: ""} = _answer),
    do: {:error, "Answer cannot be blank."}

  def validate_answer(prompt, answer) do
    cond do
      String.length(answer.answer) > 80 ->
        {:error, "Answer is over 80 characters."}

      answer.user_id not in prompt.assigned_user_ids ->
        {:error, "Player not assigned to prompt."}

      true ->
        :ok
    end
  end

  def submit_answer(%{prompts: prompts} = game, answer) do
    with prompt <- Enum.at(prompts, answer.prompt_index),
         :ok <- validate_answer(prompt, answer),
         submitted_prompt <- put_player_answer_in_prompt(prompt, answer) do
      game
      |> update_prompt_in_game(submitted_prompt, answer.prompt_index)
      |> maybe_user_fully_answered(answer.user_id)
      |> maybe_start_voting
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp put_player_answer_in_prompt(prompt, answer) do
    Map.update!(prompt, :answers, fn answers ->
      [answer | answers]
    end)
  end

  defp update_prompt_in_game(game, prompt, index) do
    game
    |> put_in([:prompts, Access.at!(index)], prompt)
  end

  defp append_user_to_submitted(game, user_id) do
    game
    |> Map.update!(:submitted_user_ids, fn ids -> [user_id | ids] end)
  end

  defp maybe_start_voting(game)
       when length(game.submitted_user_ids) == length(game.players) do
    game
    |> start_voting_phase()
  end

  defp maybe_start_voting(game), do: game

  defp maybe_user_fully_answered(game, user_id) when game.final_round? do
    append_user_to_submitted(game, user_id)
  end

  defp maybe_user_fully_answered(%{prompts: prompts} = game, user_id) do
    if user_submission_count(prompts, user_id) == 2 do
      append_user_to_submitted(game, user_id)
    else
      game
    end
  end

  defp user_submission_count(prompts, user_id) do
    prompts
    |> Enum.count(fn prompt ->
      Enum.any?(prompt.answers, fn answer -> user_id == answer.user_id end)
    end)
  end

  defp user_vote_count(prompt, user_id) do
    prompt.answers
    |> Enum.reduce(0, fn
      %{votes: []}, answer_acc ->
        answer_acc

      answer, answer_acc ->
        Enum.reduce(answer.votes, answer_acc, fn vote, vote_acc ->
          if user_id == vote do
            vote_acc + 1
          else
            vote_acc
          end
        end)
    end)
  end

  def vote(_game, {voting_player_id, receiving_vote_id})
      when voting_player_id == receiving_vote_id do
    {:error, "Cannot vote for yourself."}
  end

  def vote(game, {voting_player_id, receiving_vote_id}) do
    if voting_player_id in game.current_prompt.assigned_user_ids and not game.final_round? do
      {:error, "Cannot vote when your answer is up."}
    else
      do_vote(game, {voting_player_id, receiving_vote_id})
    end
  end

  def do_vote(game, {voting_player_id, receiving_vote_id}) do
    game
    |> append_vote({voting_player_id, receiving_vote_id})
    |> maybe_user_fully_voted(voting_player_id)
    |> maybe_score_votes
  end

  defp append_vote(
         %{current_prompt: current_prompt} = game,
         {voting_player_id, receiving_vote_id}
       ) do
    answer_idx =
      Enum.find_index(current_prompt.answers, fn %Answer{} = %{user_id: user_id} ->
        user_id == receiving_vote_id
      end)

    game
    |> update_in(
      [:current_prompt, :answers, Access.at!(answer_idx), :votes],
      fn votes -> [voting_player_id | votes] end
    )
  end

  defp maybe_user_fully_voted(game, user_id) when game.final_round? do
    if user_vote_count(game.current_prompt, user_id) >= 3 do
      append_user_to_submitted(game, user_id)
    else
      game
    end
  end

  defp maybe_user_fully_voted(game, user_id), do: append_user_to_submitted(game, user_id)

  defp maybe_score_votes(game)
       when game.final_round? and length(game.submitted_user_ids) == length(game.players) do
    score_votes(game)
  end

  defp maybe_score_votes(game)
       when length(game.submitted_user_ids) == length(game.players) - 2 do
    score_votes(game)
  end

  defp maybe_score_votes(game), do: game

  def score_votes(game)
      when game.final_round? do
    do_score_votes(game, 100 * length(game.players) * 2)
  end

  def score_votes(game), do: do_score_votes(game, 100)

  def do_score_votes(%{current_prompt: current_prompt} = game, _total_points)
      when current_prompt.answers == [] do
    game
    |> put_in([:current_prompt, :scored?], true)
  end

  def do_score_votes(%{current_prompt: current_prompt} = game, total_points) do
    total_votes = length(Enum.flat_map(current_prompt.answers, fn answer -> answer.votes end))

    _new_game =
      Enum.reduce(game.players, game, fn player, acc_game ->
        case find_player_answer(current_prompt.answers, player.id) do
          nil ->
            acc_game

          answer_idx ->
            num_votes = length(Enum.fetch!(current_prompt.answers, answer_idx).votes)
            score = score_player_votes(num_votes, total_points, total_votes)

            _acc_game =
              acc_game
              |> add_score_to_answer(score, answer_idx)
              |> update_player_score(score, player.id)
        end
      end)
      |> put_in([:current_prompt, :scored?], true)
  end

  defp find_player_answer(answers, user_id) do
    Enum.find_index(answers, fn answer ->
      answer.user_id == user_id
    end)
  end

  defp score_player_votes(_votes, _total_points, _total_votes = 0), do: 0

  defp score_player_votes(num_votes, total_points, total_votes) do
    fraction_of_points = num_votes / total_votes
    round(total_points * fraction_of_points)
  end

  defp update_player_score(game, score, player_id) do
    game
    |> SinglePlayerGame.add_score_to_player(player_id, score)
  end

  defp add_score_to_answer(game, score, answer_idx) do
    game
    |> put_in([:current_prompt, :answers, Access.at!(answer_idx), :score], score)
  end

  def next_prompt(%{prompts: prompts} = game)
      when prompts == [] do
    game
    |> next_round
  end

  def next_prompt(%{prompts: [current_prompt | remaining]} = game) do
    %{game | current_prompt: current_prompt, prompts: remaining}
    |> clear_submitted_user_ids()
  end

  defp next_round(game)
       when game.final_round? do
    %{game | finished?: true}
  end

  defp next_round(%{current_round: current_round, num_rounds: num_rounds} = game)
       when current_round == num_rounds - 1 do
    %{game | final_round?: true}
    |> do_next_round
  end

  defp next_round(game), do: do_next_round(game)

  defp do_next_round(game) do
    game
    |> increment_round()
    |> setup_round()
  end

  defp increment_round(game) do
    game
    |> Map.update!(:current_round, &(&1 + 1))
  end

  def create_answer(attrs) do
    %Answer{}
    |> Answer.changeset(attrs)
    |> apply_action(:update)
  end

  def change_answer(answer, attrs) do
    answer
    |> Answer.changeset(attrs)
  end
end
