defmodule Gamenite.Witbash do
  @behaviour Gamenite.Game
  use Accessible

  use Ecto.Schema
  import Ecto.Changeset

  alias Gamenite.Witbash.{Prompt}
  alias Gamenite.TeamGame.Player
  alias Gamenite.Cards
  alias Gamenite.SinglePlayerGame

  embedded_schema do
    field(:room_slug, :string)
    field(:players, {:array, :map})
    field(:current_player, :map)
    field(:deck_of_prompts, {:array, :string})
    field :prompts, {:array, :map}
    field :submitted_user_ids, {:array, :string}
    field :current_prompt, :map
    field :num_rounds, :integer, default: 3
    field :current_round, :integer, default: 1
    field :answer_length_in_sec, :integer, default: 120
    field :vote_length_in_sec, :integer, default: 60
    field :time_remaining_in_sec, :integer
    field :answering?, :boolean
    field :finished?, :boolean, default: false
  end

  @fields [:deck_of_prompts, :num_rounds]
  @required [:deck_of_prompts]

  @impl Gamenite.Game
  def changeset(game, attrs) do
    game
    |> cast(attrs, @fields)
    |> validate_required(@required)
    |> validate_length(:deck_of_prompts, min: length(Map.get(attrs, :players, 0)) * 4 + 1)
    |> validate_length(:players, min: 3)
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

  defp shuffle_prompts(%{deck_of_prompts: deck_of_prompts} = game) do
    shuffled_deck =
      deck_of_prompts
      |> Enum.shuffle()

    %{game | deck_of_prompts: shuffled_deck}
  end

  def setup_round(%{current_round: current_round} = game) when current_round == 3 do
    game
    |> answering_phase
    |> draw_final_prompt
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

  defp draw_final_prompt(%{deck_of_prompts: deck_of_prompts} = game) do
    {[final_prompt | []], remaining} = do_draw_prompts(deck_of_prompts, 1)

    %{game | deck_of_prompts: remaining, current_prompt: final_prompt}
  end

  def draw_prompts(%{deck_of_prompts: deck_of_prompts, players: players} = game) do
    {drawn_prompts, remaining} = do_draw_prompts(deck_of_prompts, players)

    prompts =
      drawn_prompts
      |> Enum.map(fn prompt -> %Prompt{prompt: prompt} end)

    %{game | deck_of_prompts: remaining, prompts: prompts}
  end

  defp do_draw_prompts(prompts, players) do
    num_prompts = length(players)

    prompts
    |> Cards.draw(num_prompts)
  end

  defp assign_prompts(%{players: players, prompts: prompts} = game) do
    paired_id_list = create_random_player_id_list(players)

    assigned_prompts =
      for {prompt, i} <- Enum.with_index(prompts) do
        assigned_ids = Enum.at(paired_id_list, i)
        %{prompt | assigned_player_ids: assigned_ids}
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

  def validate_answer(_prompt, "", _player_id), do: {:error, "Answer cannot be blank."}

  def validate_answer(prompt, answer, player_id) do
    cond do
      String.length(answer) > 80 ->
        {:error, "Answer is over 80 characters."}

      not prompt.is_final? and player_id not in prompt.assigned_player_ids ->
        {:error, "Player not assigned to prompt."}

      true ->
        :ok
    end
  end

  def submit_answer(game, answer, player_id, prompt_index \\ nil)

  def submit_answer(%{current_prompt: final_prompt} = game, answer, player_id, nil) do
    with :ok <- validate_answer(final_prompt, answer, player_id),
         submitted_final <-
           put_player_answer_in_prompt(final_prompt, answer, player_id) do
      game
      |> Map.put(:current_prompt, submitted_final)
      |> append_user_to_submitted(player_id)
      |> maybe_start_voting
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def submit_answer(%{prompts: prompts} = game, answer, player_id, prompt_index) do
    with prompt <- Enum.at(prompts, prompt_index),
         :ok <- validate_answer(prompt, answer, player_id),
         submitted_prompt <- put_player_answer_in_prompt(prompt, answer, player_id) do
      game
      |> update_prompt_in_game(submitted_prompt, prompt_index)
      |> maybe_user_fully_submitted(player_id)
      |> maybe_start_voting
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp put_player_answer_in_prompt(prompt, answer, player_id) do
    Map.update!(prompt, :answers, fn answers -> [{player_id, answer} | answers] end)
  end

  defp update_prompt_in_game(game, prompt, index) do
    game
    |> put_in([:prompts, Access.at!(index)], prompt)
  end

  defp append_user_to_submitted(game, player_id) do
    game
    |> Map.update!(:submitted_user_ids, fn ids -> [player_id | ids] end)
  end

  defp maybe_start_voting(game)
       when length(game.submitted_user_ids) == length(game.players) do
    game
    |> start_voting_phase()
  end

  defp maybe_start_voting(game), do: game

  defp maybe_user_fully_submitted(%{prompts: prompts} = game, player_id) do
    if user_submission_count(prompts, player_id) == 2 do
      append_user_to_submitted(game, player_id)
    else
      game
    end
  end

  defp user_submission_count(prompts, player_id) do
    prompts
    |> Enum.count(fn prompt ->
      Enum.any?(prompt.answers, fn {id, _answer} -> player_id == id end)
    end)
  end

  def vote(_game, {voting_player_id, receiving_vote_id})
      when voting_player_id == receiving_vote_id do
    {:error, "Cannot vote for yourself."}
  end

  def vote(game, {voting_player_id, receiving_vote_id}) do
    if voting_player_id in game.current_prompt.assigned_player_ids do
      {:error, "Cannot vote when your answer is up."}
    else
      do_vote(game, {voting_player_id, receiving_vote_id})
    end
  end

  def do_vote(game, {voting_player_id, receiving_vote_id}) do
    game
    |> append_vote({voting_player_id, receiving_vote_id})
    |> append_user_to_submitted(voting_player_id)
    |> maybe_score_votes
  end

  defp append_vote(
         %{current_prompt: current_prompt} = game,
         {voting_player_id, receiving_vote_id}
       ) do
    prompt_with_vote =
      current_prompt
      |> Map.update!(:votes, fn votes -> [{voting_player_id, receiving_vote_id} | votes] end)

    %{game | current_prompt: prompt_with_vote}
  end

  defp maybe_score_votes(game)
       when game.current_round == game.num_rounds and
              length(game.submitted_user_ids) == length(game.players) do
    score_votes(game)
  end

  defp maybe_score_votes(game)
       when length(game.submitted_user_ids) == length(game.players) - 2 do
    game
    |> score_votes
  end

  defp maybe_score_votes(game), do: game

  def score_votes(game)
      when game.current_round == game.num_rounds do
    do_score_votes(game, 100 * length(game.players))
  end

  def score_votes(game), do: do_score_votes(game, 100)

  def do_score_votes(%{current_prompt: current_prompt} = game, total_points) do
    player_votes =
      current_prompt.votes
      |> Enum.sort_by(fn {_voting_player_id, receiving_player_id} -> receiving_player_id end)
      |> Enum.chunk_by(fn {_voting_player_id, receiving_player_id} -> receiving_player_id end)

    _new_game =
      Enum.reduce(game.players, game, fn player, acc_game ->
        case find_player_votes(player_votes, player.id) do
          nil ->
            acc_game

          votes_for_player ->
            _acc_game =
              votes_for_player
              |> score_player_votes(total_points, current_prompt.votes)
              |> update_player_score(player.id, acc_game)
        end
      end)
  end

  defp find_player_votes(player_votes, player_id) do
    Enum.find(player_votes, fn [{_voting_player_id, receiving_player_id} | _tail] ->
      player_id == receiving_player_id
    end)
  end

  defp score_player_votes(votes_for_player, total_points, all_votes) do
    fraction_of_points = length(votes_for_player) / length(List.flatten(all_votes))
    round(total_points * fraction_of_points)
  end

  defp update_player_score(score, player_id, game) do
    game
    |> SinglePlayerGame.add_score_to_player(player_id, score)
  end

  def next_prompt(%{prompts: prompts} = game)
      when prompts == [] or game.current_round == game.num_rounds do
    game
    |> next_round
  end

  def next_prompt(%{prompts: [current_prompt | remaining]} = game) do
    %{game | current_prompt: current_prompt, prompts: remaining}
    |> clear_submitted_user_ids()
  end

  defp next_round(%{current_round: current_round, num_rounds: num_rounds} = game)
       when current_round == num_rounds do
    %{game | finished?: true}
  end

  defp next_round(game) do
    game
    |> increment_round()
    |> setup_round()
  end

  defp increment_round(game) do
    game
    |> Map.update!(:current_round, &(&1 + 1))
  end
end
