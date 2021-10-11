defmodule Gamenite.SaladBowlServer do
  use GenServer

  alias Gamenite.Cards
  alias Gamenite.TeamGame
  alias Gamenite.Games.Charades

  def init({game, _room_uuid}) do
    {:ok, game}
  end

  def child_spec({game, room_uuid}) do
    %{
      id: {__MODULE__, room_uuid},
      start: {__MODULE__, :start_link, [{game, room_uuid}]},
      restart: :temporary
    }
  end

  def start_link({game, room_uuid}) do
    GenServer.start_link(
      __MODULE__,
      {game, room_uuid},
      name: via(room_uuid))
  end

  def via(room_uuid) do
    {:via,
    Registry,
    {Gamenite.Registry.Game, room_uuid}}
  end

  def start_child(game, room_uuid) do
    DynamicSupervisor.start_child(
      Gamenite.Supervisor.Game,
      child_spec({game, room_uuid}))
  end

  def game_exists?(room_slug) do
    case Registry.lookup(Gamenite.Registry.Game, room_slug) do
      [{_pid, _val}] -> true
      [] -> false
    end
  end

  defp game_response({:error, reason}, old_state) do
    {:reply, {:error, reason}, old_state}
  end

  defp game_response(new_state, _old_state) do
    {:reply, {:ok, new_state}, new_state}
  end


  def handle_call(:state, _from, game) do
    game_response(game, game)
  end

  def handle_call({:add_player, player}, _from, game) do
    game_response(TeamGame.add_player(game, player), game)
  end

  def handle_call(:start_turn, {pid, _alias} = _client, game) do
    game
    |> draw_card
    |> start_timer(pid)
    |> game_response(game)
  end

  def handle_call(:end_turn, _from, game) do
    game
    |> Charades.move_incorrect_back_to_deck
    |> score_correct_cards
    |> TeamGame.end_turn
    |> Charades.new_turn
    |> game_response(game)
  end

  def handle_call({:completed_card, outcome}, _from, game) do
    case Charades.card_completed(game, outcome) do
      {:review, new_game} ->
        new_game
        |> stop_timer
        |> game_response(game)
      {:error, reason} ->
          game_response({:error, reason}, game)
      {:use_skipped, new_game} ->
          new_game
          |> game_response(game)
      new_game ->
        new_game
        |> draw_card
        |> game_response(game)
    end
  end

  def handle_call({:submit_cards, word_list, user_id}, _from, game) do
    game
    |> Charades.add_cards_to_deck(word_list, user_id)
    |> game_response(game)
  end

  defp draw_or_review_cards(%{ deck: deck } = game)
  when length(deck) == 0 do
    {:error, "Review Cards"}
  end
  defp draw_or_review_cards(game), do: draw_card(game)


  def handle_info({:tick, pid}, %{current_turn: %{time_remaining_in_sec: time}} = game)
  when time <= 1 do
    Process.send(pid, :turn_ended, [])
    new_game = game
    |> put_in([:current_turn, :time_remaining_in_sec], 0)
    |> stop_timer
    {:noreply, new_game}
  end

  def handle_info({:tick, pid}, game) do
    new_game = update_in(game.current_turn.time_remaining_in_sec, &(&1 - 1))
    Process.send(pid, {:tick, game}, [])
    {:noreply, new_game}
  end

  defp start_timer(game, client) do
    {:ok, {:interval, timer}} = :timer.send_interval(1000, self(), {:tick, client})
    put_in(game, [:current_turn, :timer], timer)
  end

  defp stop_timer(%{current_turn: current_turn} = game) do
    Process.cancel_timer(current_turn.timer)
    game
    |> put_in([:current_turn, :needs_review], true)
  end

  defp draw_card(%{ deck: deck } = game) do
    case Cards.draw(deck) do
      {:error, reason} ->
        {:error, reason}
      { drawn_cards, remaining_deck } ->
        game
        |> put_in([:current_turn, :card], hd(drawn_cards))
        |> Map.put(:deck, remaining_deck)
    end
  end

  defp score_correct_cards(%{current_turn: current_turn} = game) do
    turn_score = Charades.count_cards_with_outcome(current_turn.completed_cards, :correct)

    game
    |> TeamGame.add_score(turn_score)
  end
end
