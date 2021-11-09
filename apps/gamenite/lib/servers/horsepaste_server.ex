defmodule Gamenite.Horsepaste.Server do
  use GenServer

  import Gamenite.GameServer
  alias Gamenite.{Horsepaste, TeamGame}

  def init({game, _room_uuid}) do
    IO.puts("setting up")
    setup_game = Horsepaste.setup_game(game)
    broadcast_game_update(setup_game)
    {:ok, setup_game}
  end

  def start_link({game, room_uuid}) do
    GenServer.start_link(
      __MODULE__,
      {game, room_uuid},
      name: via(room_uuid)
    )
  end

  def handle_call({:give_clue, clue_word, number_of_words}, _from, game) do
    game
    |> Horsepaste.give_clue(clue_word, number_of_words)
    |> game_response(game)
  end

  def handle_call({:select_card, board_coords}, _from, game) do
    game
    |> Horsepaste.select_card(board_coords)
    |> game_response(game)
  end

  def handle_call(:state, _from, game) do
    {:reply, {:ok, game}, game}
  end

  def handle_call(:play_again_same_teams, _from, game) do
    game
    |> TeamGame.end_turn()
    |> TeamGame.end_turn()
    |> Horsepaste.setup_game()
    |> game_response(game)
  end

  def handle_call(:play_again_new_teams, _from, game) do
    game
    |> TeamGame.mix_up_teams()
    |> Horsepaste.setup_game()
    |> game_response(game)
  end
end
