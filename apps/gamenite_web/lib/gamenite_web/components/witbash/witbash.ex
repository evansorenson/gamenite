defmodule GameniteWeb.Components.Witbash do
  use Surface.LiveComponent
  import GameniteWeb.Components.Game

  alias GameniteWeb.Components.Charades.{Card}
  alias GameniteWeb.Components.{TeamsScoreboard, PlayerName}

  alias Gamenite.Witbash.API
  alias Gamenite.TeamGame

  data game, :map
  data user_id, :any
  data slug, :string
  data roommates, :map

  @impl true
  def handle_event(
        "submit_answer",
        %{"answer" => answer, "player_index" => player_index, "prompt_index" => prompt_index},
        socket
      ) do
    API.submit_answer(socket.assigns.slug, answer, player_index, prompt_index)
    |> game_callback(socket)
  end

  @impl true
  def handle_event("submit_answer", %{"answer" => answer, "player_index" => player_index}, socket) do
    API.submit_answer(socket.assigns.slug, answer, player_index)
    |> game_callback(socket)
  end

  @impl true
  def handle_event(
        "vote",
        %{"voting_player_id" => voting_player_id, "receiving_player_id" => receiving_player_id},
        socket
      ) do
    API.vote(socket.assigns.slug, {voting_player_id, receiving_player_id})
    |> game_callback(socket)
  end

  @impl true
  def handle_event("start_round", _params, socket) do
    API.start_round(socket.assigns.slug)
    |> game_callback(socket)
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    # <PlayerScoreboard game={@game} user_id={@user_id} roommates={@roommates} />

    ~F"""
    <div>
      {#if @game.answering?}
        {#case Enum.find(@game.prompts, fn prompt -> @user_id in prompt.assigned_user_ids end)}
        {#match nil}
        <div></div>
        {#match prompt}
        <div class="flex flex-wrap justify-center bg-white rounded-lg shadow-md py-4">
          <h1 class="xs:text-5xl sm:text-6xl md:text-7xl font-mono font-bold text-center">{prompt.prompt}</h1>
        </div>
        {/case}
      {#else}
        {#for answer <- @game.current_prompt.answers }
          {roommate = Map.fetch!(@roommates, answer.user_id)}
          <PlayerName roommate={roommate} user_id={answer.user_id} color={roommate.color} />
          <h1>{answer.answer}</h1>
        {/for}
      {/if}
    </div>

    """
  end
end
