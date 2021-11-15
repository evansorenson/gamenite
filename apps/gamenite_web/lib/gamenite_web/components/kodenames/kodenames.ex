defmodule GameniteWeb.Components.Kodenames do
  use Surface.LiveComponent
  import GameniteWeb.Components.Game

  alias Gamenite.TeamGame
  alias GameniteWeb.Components.Kodenames.{Board}
  alias GameniteWeb.Components.{PlayerName, TeamsScoreboard}
  alias Gamenite.Kodenames.API
  alias Gamenite.Kodenames

  data(game, :map)
  data(user_id, :string)
  data(slug, :string)
  data(roommates, :map)
  data(flash, :map)

  @team_colors Application.get_env(:gamenite, :team_colors)

  def handle_event("select_card", %{"x" => x, "y" => y} = _params, socket) do
    API.select_card(socket.assigns.slug, {String.to_integer(x), String.to_integer(y)})
    |> game_callback(socket)
  end

  def handle_event(
        "submit_clue",
        %{"clue" => clue, "number_of_words" => number_of_words} = _params,
        socket
      ) do
    parsed_number_of_words = parse_number_of_words(number_of_words)

    API.give_clue(socket.assigns.slug, clue, parsed_number_of_words)
    |> game_callback(socket)
  end

  def handle_event("end_turn", _params, socket) do
    IO.puts("hi")

    API.end_turn(socket.assigns.slug)
    |> game_callback(socket)
  end

  defp parse_number_of_words("Unlimited" = number_of_words) do
    number_of_words
  end

  defp parse_number_of_words(number_of_words) do
    String.to_integer(number_of_words)
  end

  def render(assigns) do
    ~F"""
    <div>
      {#if @game.finished?}
      <h2> Game finished </h2>
      {/if}
    <div class="grid grid-cols-2 space-x-4 w-full h-20 items-center">
      <TeamsScoreboard game={@game} user_id={@user_id} roommates={@roommates} />

      <div class="justify-center items-center bg-white rounded-lg shadow-md h-full">
      {#if TeamGame.current_player?(@game.current_team, @user_id) and is_nil(@game.current_turn.clue)}
        <form phx-target={@myself} phx-submit="submit_clue" class="flex w-full h-full items-center justify-center space-x-4 px-0">
          <input class="text-center ring-1 ring-gray w-1/3 h-10 rounded-md" name="clue">
          <select name="number_of_words" class="h-12 w-1/4">
            <option value="1">1</option>
            <option value="2">2</option>
            <option value="3">3</option>
            <option value="4">4</option>
            <option value="5">5</option>
            <option value="6">6</option>
            <option value="7">7</option>
            <option value="8">8</option>
            <option value="9">9</option>
            <option value="Unlimited">Unlimited</option>
          </select>
          <button class="btn-blurple h-12 text-lg">Submit Clue</button>
        </form>
      {#elseif is_nil(@game.current_turn.clue) }
        <div class="flex w-full h-full items-center justify-center">
          <PlayerName player={@game.current_team.current_player} user_id={@user_id} color={@game.current_team.color} />
          <h2 class="text-3xl">{"is giving a clue"}</h2>
        </div>
      {#elseif TeamGame.on_team?(@game.current_team, @user_id) and not TeamGame.current_player?(@game.current_team, @user_id)}
        <div class="flex space-x-4 items-center justify-evenly bg-white rounded-lg h-full shadow-md">
          <h3 class="font-semibold">{"Clue: #{@game.current_turn.clue}"}</h3>
          <h3 class="font-semibold">
          {#if @game.current_turn.number_of_words == "Unlimited"}
            {"Unlimited"}
          {#elseif @game.current_turn.num_correct < @game.current_turn.number_of_words}
            {"Left: #{@game.current_turn.number_of_words - @game.current_turn.num_correct}"}
          {#else}
            {"Optional extra guess!"}
          {/if}
          </h3>
          <button phx-click="end_turn" phx-target={@myself} class="btn-blurple">End Turn</button>
        </div>
      {#else}
        <h2> J chillin </h2>
      {/if}
      </div>
    </div>

      <div class="pt-8">
      {#if TeamGame.current_player?(@game.current_team, @user_id) or TeamGame.current_player?(Enum.at(@game.teams, Kodenames.other_team_index(@game.current_team)), @user_id)}
        <Board board={@game.board} spymaster?={true} disabled?={true} flip={"select_card", target: @myself} />
      {#elseif TeamGame.on_team?(@game.current_team, @user_id)}
        <Board board={@game.board} spymaster?={false} disabled?={is_nil(@game.current_turn.clue)} flip={"select_card", target: @myself} />
      {#else}
        <Board board={@game.board} spymaster?={false} disabled?={true} flip={"select_card", target: @myself} />
      {/if}
      </div>
    </div>
    """
  end
end
