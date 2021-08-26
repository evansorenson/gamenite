defmodule Game.GameSession do
  use GenServer

  alias Gamenite.Cards
  alias Gameplay.TeamGame

  # Server
  def init(game) do
    {:ok, game}
  end

  def child_spec({room_uuid, game}) do
    %{
      id: {__MODULE__, room_uuid},
      start: {__MODULE__, :start_link, [{room_uuid, game}]},
      restart: :temporary
    }
  end

  def start_link({room_uuid, game}) do
    GenServer.start_link(__MODULE__, game, name: room_uuid)
  end

  def start_game(room_uuid, game) do
    DynamicSupervisor.start_child(
      Game.Supervisor.GameSession,
      {__MODULE__, {room_uuid, game}}
    )
  end

  def handle_call(:state, _from, game) do
    { :reply, game, game }
  end

  def handle_call({:add_player, player}, _from, game) do
    { :reply, :ok, TeamGame.add_player(game, player)}
  end

  def handle_call(:start_turn, _form, %{ turn_length: turn_length } = game) do
    now = DateTime.utc_now()
    end_at = DateTime.add(now, turn_length)
    timeout = DateTime.diff(now, end_at, :millisecond)
    Process.send_after(self(), :end_turn, timeout)

    { :reply, :ok, TeamGame.draw_card(game)}
  end

  def handle_call(:draw_card, _from, game) do
    { :reply, :ok, TeamGame.draw_card(game)}
  end

  def handle_call(:shuffle, _from, game = %{ deck: deck }) do
    shuffled_deck = Cards.shuffle(deck)
    {:reply, shuffled_deck, %{ game | deck: shuffled_deck} }
  end

  def handle_call(:next_player, _from, game) do
    updated_game = TeamGame.next_player(game)
    { :reply, Map.get(updated_game, :current_team), updated_game }
  end

  def handle_call({ :correct_card, card }, _from, game) do
    { :reply, :ok, TeamGame.correct_card(game, card)}
  end

  def handle_call({ :skip_card, card }, _from, game) do
    case TeamGame.skip_card(game) do
      {:error, reason} ->
        {:reply, {:error, reason}, game}
      game ->
        {:reply, :ok, game}
    end
    { :reply, TeamGame.skip_card(game, card) }
  end

  def handle_call(:reviewed_cards, _from, game) do

  end

  def handle_info({ :end_turn, turn }, game)
  when game.turn.player == turn.player
  do
    {:reply, :ok, TeamGame.next_player(game)}
  end
  def handle_info({ :end_turn, _turn}, game), do: {:noreply, game}
end
