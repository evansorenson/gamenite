defmodule GameniteWeb.Components.Horsepaste do
  use Surface.LiveComponent
  import GameniteWeb.Components.Game

  alias Gamenite.TeamGame
  alias GameniteWeb.Components.Horsepaste.{Board}
  alias Gamenite.Horsepaste.API
  alias Gamenite.Horsepaste

  data(game, :map)
  data(user_id, :string)
  data(slug, :string)
  data(flash, :map)

  def handle_event("select_card", %{"board_coords" => board_coords} = _params, socket) do
    API.select_card(socket.assigns.slug, board_coords)
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

  defp parse_number_of_words("Unlimited" = number_of_words) do
    number_of_words
  end

  defp parse_number_of_words(number_of_words) do
    String.to_integer(number_of_words)
  end

  def render(assigns) do
    ~F"""
    <div>
    <div class="pb-8">
    {#if TeamGame.current_player?(@game.current_team, @user_id) and is_nil(@game.current_turn.clue)}
      <h2 class="block text-center text-bold text-4xl">Give a clue</h2>
      <form phx-target={@myself} phx-submit="submit_clue" class="flex justify-center items-center py-4 space-x-4 bg-white rounded-lg shadow-md">
      <input class="text-center ring-1 ring-gray ml-2 w-1/4 rounded-md" name="clue">
      <select name="number_of_words">
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
      <button class="btn-blurple">Submit Clue</button>
      </form>
    {/if}
    </div>

    <div>
    {#if TeamGame.current_player?(@game.current_team, @user_id) or TeamGame.current_player?(Enum.at(@game.teams, Horsepaste.other_team_index(@game.current_team)), @user_id)}
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
