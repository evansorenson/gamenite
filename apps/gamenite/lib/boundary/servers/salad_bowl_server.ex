defmodule Gamenite.SaladBowlServer do
  use GenServer

  alias Gamenite.Cards
  alias Gamenite.TeamGame
  alias Gamenite.Games.Charades
  alias Gamenite.Games.CharadesTurn

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

  def handle_call(:start_turn, client, %{ turn_length: turn_length } = game) do
    now = DateTime.utc_now()
    end_at = DateTime.add(now, turn_length)
    timeout = DateTime.diff(now, end_at, :millisecond)
    Process.send_after(client, :end_turn, timeout)

    game
    |> Charades.draw_card
    |> game_response(game)
  end

  def handle_call(:stop_turn, _form, %{ turn_length: turn_length } = game) do
    ## fix todo

    game
    |> game_response(game)
  end

  def handle_call(:draw_card, _from, game) do
    game_response(Charades.draw_card(game), game)
  end

  def handle_call(:shuffle, _from, %{ options: %{ deck: deck } = options} = game) do
    %{ game | options: %{ options | deck: Cards.shuffle(deck)}}
    |> game_response(game)
  end

  def handle_call(:next_player, _from, %{team_game: team_game} = game) do
    %{game | team_game: TeamGame.end_turn(team_game, &CharadesTurn.new/1) }
    |> game_response(game)
  end

  def handle_call(:correct_card, _from, game) do
    game_response(Charades.card_is_correct(game), game)
  end

  def handle_call(:skip_card, _from, game) do
    game_response(Charades.skip_card(game), game)
  end

  def handle_call(:reviewed_cards, _from, game) do

  end

  # def handle_info({ :end_turn, turn }, game)
  # when game.turn.player == turn.player
  # do
  #   { :ok, TeamGame.end_turn(game)})
  # end
  # def handle_info({ :end_turn, _turn}, game), do: {:noreply, game}
end
