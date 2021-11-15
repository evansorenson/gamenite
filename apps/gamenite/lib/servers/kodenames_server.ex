defmodule Gamenite.Kodenames.Server do
  use Gamenite.Game.Server
  alias Gamenite.{Kodenames, TeamGame}

  def handle_call({:give_clue, clue_word, number_of_words}, _from, game) do
    game
    |> Kodenames.give_clue(clue_word, number_of_words)
    |> game_response(game)
  end

  def handle_call({:select_card, board_coords}, _from, game) do
    game
    |> Kodenames.select_card(board_coords)
    |> game_response(game)
  end

  def handle_call(:end_turn, _from, game) do
    game
    |> Kodenames.next_turn()
    |> game_response(game)
  end

  def handle_call(:play_again_same_teams, _from, game) do
    game
    |> TeamGame.end_turn()
    |> TeamGame.end_turn()
    |> Kodenames.setup()
    |> game_response(game)
  end

  def handle_call(:play_again_new_teams, _from, game) do
    game
    |> TeamGame.mix_up_teams()
    |> Kodenames.setup()
    |> game_response(game)
  end
end
