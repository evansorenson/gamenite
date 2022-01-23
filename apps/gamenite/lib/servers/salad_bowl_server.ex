defmodule Gamenite.SaladBowl.Server do
  use Gamenite.Game.Server

  alias Gamenite.TeamGame
  alias Gamenite.Charades
  alias Phoenix.PubSub

  use Gamenite.Timing

  def init({game, _room_uuid}) do
    setup_game =
      game
      |> Charades.new_turn(game.turn_length)

    broadcast_game_update(setup_game)
    {:ok, setup_game}
  end

  def handle_call({:add_player, player}, _from, game) do
    game_response(TeamGame.add_player(game, player), game)
  end

  def handle_call(:start_turn, _from, game) do
    game
    |> Charades.start_turn()
    |> Timing.start_timer(:timer, &turn_timer_ends/1, game.current_turn.turn_length)
    |> game_response(game)
  end

  def handle_call(:end_turn, _from, game) do
    game
    |> clear_canvas()
    |> Charades.end_turn()
    |> game_response(game)
  end

  def handle_call({:completed_card, outcome}, _from, game) do
    case Charades.add_card_to_completed(game, outcome) do
      {:review, new_game} ->
        new_game
        |> Timing.stop_timer(:timer)
        |> Charades.needs_review()
        |> clear_canvas()
        |> game_response(game)

      new_game ->
        new_game
        |> clear_canvas()
        |> game_response(game)
    end
  end

  def handle_call({:submit_cards, word_list, user_id}, _from, game) do
    game
    |> Charades.add_cards_to_deck(word_list, user_id)
    |> game_response(game)
  end

  def handle_call({:change_card_outcome, card_index, outcome}, _from, game) do
    game
    |> Charades.change_card_outcome(card_index, outcome)
    |> game_response(game)
  end

  def handle_call({:update_canvas, canvas_data, user_id}, _from, game) do
    game
    |> update_canvas(canvas_data, user_id)
    |> game_response(game)
  end

  def turn_timer_ends(game) do
    game
    |> Charades.needs_review()
  end

  defp clear_canvas({:error, reason}), do: {:error, reason}

  defp clear_canvas(game) when game.current_round == "Pictionary" do
    game
    |> update_canvas("", nil)
  end

  defp clear_canvas(game), do: game

  defp update_canvas(game, canvas_data, user_id) do
    PubSub.broadcast(
      Gamenite.PubSub,
      "canvas_updated:" <> game.room_slug,
      {:canvas_updated, canvas_data, user_id}
    )

    %{game | canvas: canvas_data}
  end
end
