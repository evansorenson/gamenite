defmodule Gamenite.Witbash do
  use Ecto.Schema

  alias Gamenite.Witbash.{Prompt}
  alias Gamenite.TeamGame.Player
  alias Gamenite.Cards

  embedded_schema do
    field(:room_slug, :string)
    field(:players, {:array, :map})
    field(:current_player, :map)
    field(:deck_of_prompts, {:array, :string})
    field :prompts, :map
    field :final_prompt, :map
    field :submitted_user_ids, {:array, :string}
    field :current_prompt, :map
    field(:rounds, {:array, :string})
    field :current_round, :string
    field :phase, :string
  end

  @fields [:deck_of_prompts, :rounds, :current_round]
  @required [:deck_of_prompts]

  use Gamenite.SinglePlayerGame

  @impl Gamenite.Game
  def changeset(game, attrs) do
    game
    |> cast(attrs, @fields)
    |> validate_required(@required)
    |> validate_length(:deck_of_prompts, min: length(Map.get(attrs, :players, 0)) * 4 + 1)
    |> validate_length(:players, min: 3)
  end

  @impl Gamenite.Game
  def setup(game) do
    game
    |> shuffle_prompts
    |> setup_round()
  end

  defp shuffle_prompts(%{deck_of_prompts: deck_of_prompts} = game) do
    shuffled_deck =
      deck_of_prompts
      |> Enum.shuffle()

    %{game | deck_of_prompts: shuffled_deck}
  end

  def setup_round(%{current_round: current_round} = game) when current_round == 3 do
    game
    |> draw_final_prompt
  end

  def setup_round(game) do
    game
    |> draw_prompts
    |> assign_prompts
  end

  defp draw_final_prompt(%{deck_of_prompts: deck_of_prompts} = game) do
    {[final_prompt | []], remaining} = do_draw_prompts(deck_of_prompts, 1)

    %{game | deck_of_prompts: remaining, final_prompt: final_prompt}
  end

  def draw_prompts(%{deck_of_prompts: deck_of_prompts, players: players} = game) do
    {drawn_prompts, remaining} = do_draw_prompts(deck_of_prompts, players)

    prompts =
      drawn_prompts
      |> Enum.with_index()
      |> Enum.map(fn {prompt, i} -> {i, %Prompt{id: i, prompt: prompt}} end)
      |> Enum.into(%{})

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
      for {k, prompt} <- Map.to_list(prompts), into: %{} do
        assigned_ids = Enum.at(paired_id_list, k)
        {k, %{prompt | assigned_player_ids: assigned_ids}}
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

  def validate_answer(""), do: {:error, "Answer cannot be blank."}

  def validate_answer(answer) do
    if String.length(answer) > 80 do
      {:error, "Answer is over 80 characters."}
    else
      :ok
    end
  end

  def submit_answer(%{prompts: prompts} = game, prompt_id, answer, player_id) do
    with :ok <- validate_answer(answer),
         submitted_prompt <-
           Map.fetch!(prompts, prompt_id) |> put_player_answer_in_prompt(answer, player_id) do
      game
      |> put_in([:prompts, Access.key!(prompt_id)], submitted_prompt)
      |> maybe_user_fully_submitted(player_id)
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp put_player_answer_in_prompt(prompt, answer, player_id) do
    if player_id in prompt.assigned_player_ids do
      Map.update!(prompt, :answers, fn answers -> [{player_id, answer} | answers] end)
    else
      {:error, "Player not assigned to prompt."}
    end
  end

  def submit_final_answer(%{final_prompt: final_prompt} = game, answer, player_id) do
    with :ok <- validate_answer(answer),
         submitted_final <-
           put_player_answer_in_prompt(final_prompt, answer, player_id) do
      game
      |> Map.put(:final_prompt, submitted_final)
      |> append_user_to_submitted(player_id)
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_user_fully_submitted(%{prompts: prompts} = game, player_id) do
    if user_submission_count(prompts, player_id) == 2 do
      append_user_to_submitted(game, player_id)
    else
      game
    end
  end

  defp append_user_to_submitted(game, player_id) do
    game
    |> Map.update!(:submitted_user_ids, fn ids -> [player_id | ids] end)
  end

  defp user_submission_count(prompts, player_id) do
    prompts
    |> Map.to_list()
    |> Enum.count(fn {_id, prompt} ->
      Enum.any?(prompt.answers, fn {id, _answer} -> player_id == id end)
    end)
  end
end
