defmodule Gamenite.Horsepaste.API do
  import Gamenite.GameServer, only: [via: 1]

  def select_card(slug, board_coords) do
    GenServer.call(via(slug), {:select_card, board_coords})
  end

  def give_clue(slug, clue_word, number_of_words) do
    GenServer.call(via(slug), {:give_clue, clue_word, number_of_words})
  end
end
