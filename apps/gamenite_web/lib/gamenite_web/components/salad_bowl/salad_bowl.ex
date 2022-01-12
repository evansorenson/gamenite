defmodule GameniteWeb.Components.SaladBowl do
  use Surface.LiveComponent
  import GameniteWeb.Components.Game

  alias GameniteWeb.Components.Charades.{Card}
  alias GameniteWeb.Components.{TeamsScoreboard, PlayerName, SubmittedUsers, Timer}

  alias Gamenite.SaladBowl.API

  data game, :map
  data user_id, :any
  data slug, :string
  data roommates, :map

  @impl true
  def handle_event("correct", _params, socket) do
    card_completed(socket, :correct)
  end

  @impl true
  def handle_event("incorrect", _params, socket) do
    card_completed(socket, :incorrect)
  end

  @impl true
  def handle_event("skip", _params, socket) do
    card_completed(socket, :skipped)
  end

  @impl true
  def handle_event("change_correct", %{"card_index" => card_index}, socket) do
    change_card_outcome(socket, card_index, :correct)
  end

  @impl true
  def handle_event("change_incorrect", %{"card_index" => card_index}, socket) do
    change_card_outcome(socket, card_index, :incorrect)
  end

  @impl true
  def handle_event("change_skip", %{"card_index" => card_index}, socket) do
    change_card_outcome(socket, card_index, :skipped)
  end

  @impl true
  def handle_event("start_turn", _params, socket) do
    API.start_turn(socket.assigns.slug)
    |> game_callback(socket)
  end

  @impl true
  def handle_event("end_turn", _params, socket) do
    API.end_turn(socket.assigns.slug)
    |> game_callback(socket)
  end

  def handle_event("submit_words", params, socket) do
    word_list = Enum.map(params, fn {_k, v} -> v end)

    API.submit_cards(socket.assigns.slug, word_list, socket.assigns.user_id)
    |> game_callback(socket)
  end

  defp card_completed(socket, outcome) do
    API.card_completed(socket.assigns.slug, outcome)
    |> game_callback(socket)
  end

  defp change_card_outcome(socket, card_index, outcome) do
    API.change_card_outcome(socket.assigns.slug, String.to_integer(card_index), outcome)
    |> game_callback(socket)
  end

  def render(assigns) do
    ~F"""
    <div>
    <p class="alert alert-info" role="alert">{live_flash(@flash, :info)}</p>
    <p class="alert alert-danger" role="alert">{live_flash(@flash, :error)}</p>
    {#if @game.finished?}
      <h1>Game Finished</h1>
      <TeamsScoreboard {=@game} {=@user_id} {=@roommates} bg={"gray-light"} shadow={"none"}/>
    {#elseif length(@game.submitted_users) < map_size(@roommates)}
      {#if @user_id not in @game.submitted_users}
        <div class="container items-center justify-center max-w-max py-10">
          <h1 class="py-8 text-4xl font-bold"> Enter your words to be added to the Salad Bowl!</h1>
            <form phx-target={@myself} phx-submit="submit_words">
              <div class="flex-wrap">
                {#for i <- 1..@game.cards_per_player}
                    <input class="mx-2 my-2 shadow-md h-48 text-center ring-blurple focus:ring-2 focus:ring-blurple " name={"word-#{i}"}/>
                {/for}
              </div>
              <button class="my-8 px-4 rounded-md bg-blurple text-white border-0">Submit</button>
            </form>
        </div>
      {#else}
        <SubmittedUsers submitted_users={@game.submitted_users} {=@roommates} />
      {/if}
    {#else}
    <h1 class="text-center font-bold text-5xl text-gray-darkest pb-2 border-b-2">{"Round #{Enum.find_index(@game.rounds, &(&1 == @game.current_round)) + 1} - #{@game.current_round}"}</h1>
    <GameniteWeb.Components.DrawingCanvas id="drawing_canvas" canvas={@game.canvas} {=@slug} {=@user_id} drawing_user_id={@game.current_team.current_player.id} phrase_to_draw={@game.current_turn.card}/>
    <div class="flex py-8 space-y-4 items-center justify-center flex-col">
      <div class="flex justify-evenly w-full">
        <PlayerName roommate={Map.fetch!(@roommates, @game.current_team.current_player.id)} {=@user_id} color={@game.current_team.color} font_size={"text-3xl"} />
        <div class="flex items-center justify-end">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
          </svg>
          <h1 class="text-center text-5xl">{"#{length(@game.deck)}"}</h1>
        </div>
        {#if @game.current_turn.started?}
        <Timer time_remaining={@game.timer.time_remaining} />
        {#else}
        <Timer time_remaining={@game.current_turn.turn_length} />
        {/if}
      </div>
      {#if Gamenite.TeamGame.current_player?(@game.current_team, @user_id)}
        {#case @game.current_turn}
        {#match %{started?: false}}
          <h1 class="text-4xl text-center py-2">{"It's your time to shine. Click the button to begin turn."}</h1>
          <div class="flex justify-center items-center">
            <button class="bg-black text-white  border-0 px-12" phx-click="start_turn" phx-target={@myself}>Start Turn</button>
          </div>
        {#match %{review?: true}}
          <h1 class="text-4xl text-center py-2">{"Review and change any contested cards. Click button to end turn."}</h1>
          <div class="flex justify-center items-center">
            <button class="bg-black text-white  border-0 px-12" phx-click="end_turn" phx-target={@myself}>End Turn</button>
          </div>
          {#for {{outcome, word}, i} <- Enum.with_index(@game.current_turn.completed_cards)}
            <Card word={word}/>
            {#case outcome}
              {#match :correct}
              <div class="flex justify-center items-center space-x-4">
                <button phx-value-card_index={i} phx-target={@myself} phx-click="change_incorrect" class="bg-red-600 px-4 opacity-40 hover:opacity-100">Incorrect</button>
                <button phx-value-card_index={i} phx-target={@myself} phx-click="change_skip" class="bg-yellow-600 px-4 opacity-40 hover:opacity-100">Skip</button>
                <button disabled="disabled" class="bg-green-600 px-4 disabled:opacity-100">Correct</button>
              </div>
              {#match :incorrect}
              <div class="flex justify-center items-center space-x-4">
                <button disabled="disabled" class="bg-red-600 px-4 disabled:opacity-100">Incorrect</button>
                <button phx-value-card_index={i} phx-target={@myself} phx-click="change_skip" class="bg-yellow-600 px-4 opacity-40 hover:opacity-100">Skip</button>
                <button phx-value-card_index={i} phx-target={@myself} phx-click="change_correct" class="bg-green-600 px-4 opacity-40 hover:opacity-100">Correct</button>
              </div>
              {#match :skipped}
              <div class="flex justify-center items-center space-x-4">
                <button phx-value-card_index={i} phx-target={@myself} phx-click="change_incorrect" class="bg-red-600 px-4 opacity-40 hover:opacity-100">Incorrect</button>
                <button disabled="disabled" class="bg-yellow-600 px-4 disabled:opacity-100">Skip</button>
                <button phx-value-card_index={i} phx-target={@myself} phx-click="change_correct" class="bg-green-600 px-4 opacity-40 hover:opacity-100">Correct</button>
              </div>
            {/case}
          {/for}
          {#match _}
          <Card word={@game.current_turn.card}/>
          <div class="flex justify-center items-center space-x-4">
            <button phx-target={@myself} phx-click="incorrect" class="bg-red-600 px-4">Incorrect</button>
            <button phx-target={@myself} phx-click="skip" class="bg-yellow-600 px-4">Skip</button>
            <button phx-target={@myself} phx-click="correct" class="bg-green-600 px-4">Correct</button>
          </div>
        {/case}
      {#elseif Gamenite.TeamGame.on_team?(@game.current_team, @user_id)}
        <h1 class="text-5xl py-10 text-center">{"Your team is up! You are guessing clues."}</h1>
      {#else}
        <h1 class="text-5xl py-10 text-center">{"Your team is chilling. Sit back and relax."}</h1>
      {/if}
      <div class="pt-8">
      <TeamsScoreboard {=@game} {=@user_id} {=@roommates} bg={"gray-light"} shadow={"none"}/>
      </div>
    </div>
    {/if}
    </div>
    """
  end
end
