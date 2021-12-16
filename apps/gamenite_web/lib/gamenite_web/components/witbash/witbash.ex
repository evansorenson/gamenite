defmodule GameniteWeb.Components.Witbash do
  use Surface.LiveComponent
  import GameniteWeb.Components.Game

  alias GameniteWeb.Components.{TeamsScoreboard, PlayerName, SubmittedUsers, Timer}
  alias GameniteWeb.Components.Witbash.{Answers}
  alias Surface.Components.Form
  alias Surface.Components.Form.{Submit, Label, TextInput, Field, ErrorTag}

  alias Gamenite.Witbash
  alias Gamenite.Witbash.Answer

  data game, :map
  data user_id, :any
  data slug, :string
  data roommates, :map
  data answer_changeset, :map

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign_data(assigns)
     |> assign(:answer_changeset, Witbash.change_answer(%Answer{}, %{}))}
  end

  @impl true
  def handle_event(
        "submit_answer",
        %{"answer" => answer},
        socket
      ) do
    {:ok, created_answer} = Witbash.create_answer(answer)

    Witbash.API.submit_answer(socket.assigns.slug, created_answer)
    |> game_callback(assign(socket, answer_changeset: Witbash.change_answer(%Answer{}, %{})))
  end

  @impl true
  def handle_event(
        "vote",
        %{"voting_user_id" => voting_user_id, "receiving_user_id" => receiving_user_id},
        socket
      ) do
    Witbash.API.vote(socket.assigns.slug, {voting_user_id, receiving_user_id})
    |> game_callback(socket)
  end

  @impl true
  def handle_event(
        "validate_answer",
        %{"answer" => attrs},
        socket
      ) do
    attrs = Map.put(attrs, "user_id", socket.assigns.user_id)

    answer_changeset =
      Witbash.change_answer(%Answer{}, attrs)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:answer_changeset, answer_changeset)}
  end

  @impl true
  def handle_event("start_round", _params, socket) do
    Witbash.API.start_round(socket.assigns.slug)
    |> game_callback(socket)
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    # <PlayerScoreboard game={@game} user_id={@user_id} roommates={@roommates} />

    ~F"""
    <div class="flex flex-col justify-center items-center space-y-8">
      {#if @game.answering?}
        <Timer time_remaining={@game.answering_timer.time_remaining} />
        {#case Enum.find(Enum.with_index(@game.prompts), fn {prompt, _i} -> @user_id in prompt.assigned_user_ids and @user_id not in Enum.map(prompt.answers, &(&1.user_id)) end)}
        {#match nil}
          <SubmittedUsers submitted_users={@game.submitted_user_ids} {=@roommates} />
        {#match {prompt, index}}
        {#if @game.final_round?}
        <h5>For the final round, the points are doubled!</h5>
        {/if}

        <div class="flex flex-wrap justify-center font-serif py-4 px-4">
          <h1 class="xs:text-4xl sm:text-5xl md:text-6xl text-gray-dark font-bold text-center">{prompt.prompt}</h1>
        </div>

        <div class="flex flex-col items-center w-1/2 bg-white rounded-xl shadow-xl">
          <Form for={@answer_changeset} class="w-full px-8" change="validate_answer" submit="submit_answer" opts={autocomplete: "off"}>
            <Field name={:answer} class="py-8">
              <Label>Answer</Label>
              <TextInput/>
              <ErrorTag/>
            </Field>
            <Field name={:user_id}>
              <TextInput value={@user_id} opts={type: "hidden"}/>
            </Field>
            <Field name={:prompt_index}>
              <TextInput value={index} opts={type: "hidden"}/>
            </Field>
            <Submit class="btn-blurple w-full">Submit Answer</Submit>
          </Form>
        </div>
        {/case}
      {#else}
      <Timer time_remaining={@game.voting_timer.time_remaining} />
        {#if @game.current_prompt.scored?}
          <Answers prompt={@game.current_prompt} {=@roommates} {=@user_id} show_votes?={true} on_click={"vote", target: @myself}/>
        {#elseif @user_id not in @game.submitted_user_ids and (@user_id not in @game.current_prompt.assigned_user_ids or @game.final_round?)}
          <h2 class="text-6xl font-bold text-center">Vote for your favorite answer!</h2>
          {#if @game.final_round?}
          <h5>For the final round, you get three votes. You can vote for an answer more than once.</h5>
          {/if}
          <Answers prompt={@game.current_prompt} {=@roommates} {=@user_id} on_click={"vote", target: @myself}/>
        {#else @game.current_prompt.scored?}
          <Answers prompt={@game.current_prompt} {=@roommates} {=@user_id}/>
          <SubmittedUsers submitted_users={@game.submitted_user_ids} excluded_users={@game.current_prompt.assigned_user_ids} {=@roommates} />
        {/if}
      {/if}
    </div>

    """
  end
end
