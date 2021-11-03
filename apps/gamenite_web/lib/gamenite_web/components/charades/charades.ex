defmodule GameniteWeb.Components.Charades do
  use Surface.LiveComponent

  alias GameniteWeb.Components.{TeamsScoreboard}
  alias GameniteWeb.Components.Charades.{Card, ChangesetTable}

  alias Gamenite.SaladBowl.API

  data(game, :map, default: nil)
  data(game_info, :map, default: nil)
  data(user, :map)
  data(slug, :string)
  data(roommates, :map)
  data(roommate, :map)
  data(flash, :map)

  def update(
        %{slug: slug, game_id: game_id, roommates: roommates, user: user} = _assigns,
        socket
      ) do
    game_info = GamenitePersistance.Gaming.get_game(game_id)
    roommate = Map.get(roommates, user.id)

    {:ok,
     socket
     |> initialize_game(slug)
     |> assign(user: user)
     |> assign(game_info: game_info)
     |> assign(slug: slug)
     |> assign(roommates: roommates)
     |> assign(roommate: roommate)}
  end

  @impl true
  def update(%{game: game} = _assigns, socket) do
    {:ok,
     socket
     |> assign(game: game)}
  end

  @impl true
  def update(%{game_changeset: game_changeset} = _assigns, socket) do
    {:ok,
     socket
     |> assign(game_changeset: game_changeset)}
  end

  defp initialize_game(socket, slug) do
    cond do
      API.exists?(slug) ->
        {:ok, game} = API.state(slug)
        assign(socket, game: game)

      true ->
        assign(socket, game: nil)
    end
  end

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

    API.submit_cards(socket.assigns.slug, word_list, socket.assigns.user.id)
    |> game_callback(socket)
  end

  defp game_callback(:ok, socket) do
    {:noreply, socket}
  end

  defp game_callback({:error, reason}, socket) do
    {:noreply, put_flash(socket, :error, reason)}
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
    {#if is_nil(@game)}
      <ChangesetTable id={@game_info.id} slug={@slug} roommates={@roommates} />
    {#elseif @game.finished?}
    <h1>Game is finished!</h1>
    <div class="space-y-4 pt-0">
      <TeamsScoreboard game={@game} roommate={@roommate} roommates={@roommates}/>
      <button>Return to lobby</button>
    </div>
    {#elseif length(@game.submitted_users) < map_size(@roommates)}
    {#if @user.id not in @game.submitted_users}
      <div class="container items-center justify-center max-w-max py-10">
        <h1 class="py-8 text-4xl font-bold"> Enter your words to be added to the Salad Bowl!</h1>
        <form phx-target={@myself} phx-submit="submit_words">
                <div class="flex-wrap">
                {#for i <- 1..@game.cards_per_player}
                    <input class="mx-2 my-2 shadow-md h-48 text-center" name={"word-#{i}"}/>
    {/for}
    </div>
    <button class="my-8 px-4 rounded-md bg-blurple text-white border-0">Submit</button>
    </form>
    </div>
    {#else}
      <h1 class="py-8 text-4xl font-bold text-center">Waiting for others to submit their words...</h1>
      <div class="flex flex-wrap items-center justify-evenly">
        {#for {user_id, user} <- Map.to_list(@roommates)}
          {#if user_id in @game.submitted_users}
            <div class="px-4 py-4">
              <h1 class="px-4 bg-green-400 rounded-lg shadow-md"> {user.display_name} </h1>
            </div>
          {#else}
            <div class="px-4 py-4">
              <h1 class="px-4 bg-red-400 rounded-lg shadow-md"> {user.display_name} </h1>
            </div>
          {/if}
        {/for}
      </div>
      <TeamsScoreboard game={@game} roommate={@roommate} roommates={@roommates}/>
    {/if}
    {#else}
    <h1 class="text-center font-bold text-7xl text-gray-darkest pb-2 border-b-2">{"Round #{Enum.find_index(@game.rounds, &(&1 == @game.current_round)) + 1} - #{@game.current_round}"}</h1>
    <div class="container py-8 space-y-4">
      <div class="flex items-center justify-evenly">
        <div class="flex justify-start">
          <h1 style="color:#{@game.current_team.color}" class="px-4 text-4xl rounded-lg shadow-md font-semibold border-2">{@game.current_team.current_player.name}</h1>
        </div>
        <div class="flex items-center justify-end">
          <svg xmlns="http://www.w3.org/2000/svg" class="options-svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
          </svg>
          <h1 class="text-center text-5xl">{"#{length(@game.deck)}"}</h1>
        </div>
        <div class="flex items-center justify-end">
          <svg xmlns="http://www.w3.org/2000/svg" class="options-svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <h1 class="text-5xl">{@game.current_turn.time_remaining_in_sec}</h1>
        </div>
      </div>
      {#if Gamenite.TeamGame.current_player?(@game, @user.id)}
        {#case @game.current_turn}
        {#match %{started?: false}}
          <div class="flex justify-center items-center">
            <button class="bg-black text-white  border-0 px-12" phx-click="start_turn" phx-target={@myself}>Start Turn</button>
          </div>
          <h1 class="text-5xl text-center py-2">{"It's your time to shine. Click the button to begin turn."}</h1>
        {#match %{review?: true}}
          <div class="flex justify-center items-center">
            <button class="bg-black text-white  border-0 px-12" phx-click="end_turn" phx-target={@myself}>End Turn</button>
          </div>
          <h1 class="text-5xl text-center py-2">{"Review and change any contested cards. Click button to end turn."}</h1>
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
      {#elseif Gamenite.TeamGame.on_current_team?(@game, @user.id)}
        <h1 class="text-5xl py-10 text-center">{"Your team is up! You are guessing clues."}</h1>
      {#else}
        <h1 class="text-5xl py-10 text-center">{"Your team is chilling. Sit back and relax."}</h1>
      {/if}
      <TeamsScoreboard game={@game} roommate={@roommate} roommates={@roommates} />
    </div>
    {/if}
    </div>
    """
  end
end