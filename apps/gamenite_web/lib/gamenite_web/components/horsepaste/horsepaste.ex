defmodule GameniteWeb.Components.Horsepaste do
  use Surface.LiveComponent
  import GameniteWeb.Components.Game

  alias GameniteWeb.Components.Horsepaste.{Board}
  alias Gamenite.Horsepaste.API
  alias Gamenite.TeamGame

  data(game, :map)
  data(user, :map)
  data(slug, :string)
  data(flash, :map)

  def handle_event("select_card", %{"board_coords" => board_coords} = _params, socket) do
    API.select_card(socket.assigns.slug, board_coords)
    # |> game_callback
  end

  def handle_event(
        "give_clue",
        %{"clue" => clue, "number_of_words" => number_of_words} = _params,
        socket
      ) do
    API.give_clue(socket.assigns.slug, clue, number_of_words)
    # |> game_callback
  end

  def render(assigns) do
    ~F"""

    """
  end
end
