defmodule Gamenite.SaladBowlServer do
  use GenServer

  alias Gamenite.Cards
  alias Gamenite.TeamGame
  alias Gamenite.Games.Charades

  def init({game, room_uuid}) do
    {:ok, Charades.new_turn(game)}
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

  defp ok_new_game_response(new_state) do
    {:reply, {:ok, new_state}, new_state}
  end

  defp error_old_game_response(old_game, reason) do
    {:reply, {:error, reason}, old_game}
  end


  def handle_call(:state, _from, game) do
    ok_new_game_response(game)
  end

  def handle_call({:add_player, player}, _from, game) do
    case TeamGame.add_player(game) do
      {:error, reason} ->
        error_old_game_response(game, reason)
      new_game ->
        ok_new_game_response(new_game)
    end
  end

  def handle_call(:start_turn, {pid, _alias} = _client, game) do
    {:ok, timer} = :timer.send_interval(1000, self(), {:tick, pid})

    game
    |> Charades.draw_card
    |> ok_new_game_response
  end


  def handle_call(:time, _from, game) do
    {:reply, {:ok, Charades.time_left(game)}, game}
  end

  def handle_call(:draw_card, _from, game) do
    case Charades.draw_card(game) do
      {:error, reason} ->
        error_old_game_response(game, reason)
      new_game ->
        ok_new_game_response(new_game)
    end
  end

  def handle_call(:shuffle, _from, %{ options: %{ deck: deck } = options} = game) do
    %{ game | options: %{ options | deck: Cards.shuffle(deck)}}
    |> ok_new_game_response
  end

  def handle_call(:next_player, _from, %{team_game: team_game} = game) do
    %{game | team_game: TeamGame.end_turn(team_game) }
    |> ok_new_game_response()
  end

  def handle_call(:correct_card, _from, game) do
    game
    |> Charades.card_is_correct
    |> ok_new_game_response
  end

  def handle_call(:skip_card, _from, game) do
    case Charades.skip_card(game) do
      {:error, reason} ->
        error_old_game_response(game, reason)
      new_game ->
        ok_new_game_response(new_game)
    end
  end

  def handle_call(:reviewed_cards, _from, game) do

  end

  def handle_info({:tick, pid}, %{current_turn: %{time_remaining_in_sec: 1}} = game) do
    Process.send(pid, :turn_ended)
    new_game = put_in(game, [:current_turn, :time_remaining_in_sec], 0)
    {:noreply, game}
  end
  def handle_info({:tick, pid}, game) do
    Process.send(pid, :tick)
    new_game = update_in(game, [:current_turn, :time_remaining_in_sec], &(&1 - 1))
  end
end
