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
        "give_clue",
        %{"clue" => clue, "number_of_words" => number_of_words} = _params,
        socket
      ) do
    API.give_clue(socket.assigns.slug, clue, number_of_words)
    |> game_callback(socket)
  end

  def render(assigns) do
    ~F"""
    <div>
    {#if TeamGame.current_player?(@game.current_team, @user_id) or TeamGame.current_player?(Enum.at(@game.teams, Horsepaste.other_team_index(@game.current_team)), @user_id)}
      <Board board={@game.board} spymaster?={true} disabled?={true} flip={"select_card", target: @myself} />
    {#elseif TeamGame.on_team?(@game.current_team, @user_id)}
      <Board board={@game.board} spymaster?={false} disabled?={is_nil(@game.current_turn.clue)} flip={"select_card", target: @myself} />
    {#else}
      <Board board={@game.board} spymaster?={false} disabled?={true} flip={"select_card", target: @myself} />
    {/if}
    </div>
    """
  end
end
