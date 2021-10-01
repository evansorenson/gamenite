defmodule Gamenite.SaladBowlServer do
  use GenServer

  alias Gamenite.Cards
  alias Gamenite.TeamGame
  alias Gamenite.Games.Charades

  # Server
  def init({game, room_uuid}) do
    {:ok, TeamGame.new(%{game: game, room_id: room_uuid})}
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

  defp via(room_uuid) do
    {:via,
    Registry,
    {Gamenite.Registry.Game, {room_uuid}}}
  end

  def start_child(game, room_uuid) do
    DynamicSupervisor.start_child(
      Gamenite.Supervisor.Game,
      child_spec({game, room_uuid})
    )
  end

  def handle_call({:add_player, player}, _from, game) do
    game = TeamGame.add_player(game, player)
    { {:ok, game}, game}
  end

  def handle_call(:start_turn, client, %{ turn_length: turn_length } = game) do
    now = DateTime.utc_now()
    end_at = DateTime.add(now, turn_length)
    timeout = DateTime.diff(now, end_at, :millisecond)
    Process.send_after(client, :end_turn, timeout)

    { :ok, TeamGame.draw_card(game)})
  end

  def handle_call(:stop_turn, _form, %{ turn_length: turn_length } = game) do
    now = DateTime.utc_now()
    end_at = DateTime.add(now, turn_length)
    timeout = DateTime.diff(now, end_at, :millisecond)
    Process.send_after(self(), :end_turn, timeout)

    { :ok, TeamGame.draw_card(game)})
  end

  def handle_call(:draw_card, _from, game) do
    case Charades.draw_card(game) do
      {:error, reason} ->
        {{:error, reason}, game}
      new_game ->
        {{:ok, new_game}, new_game}
    end
  end

  def handle_call(:shuffle, _from, game = %{ options: %{deck: deck }}) do
    { game | deck: Cards.shuffle(deck)}
    { shuffled_deck, % })
  end

  def handle_call(:next_player, _from, %{team_game: team_game} = game) do
    updated_game = %{game | team_game: TeamGame.end_turn(team_game) }
    { Map.get(updated_game, :current_team), updated_game })
  end

  def handle_call({ :correct_card, card }, _from, game) do
    { :ok, TeamGame.card_is_correct(game, card)})
  end

  def handle_call({ :skip_card }, _from, game) do
    case Charades.skip_card(game) do
      {:error, reason} ->
        { {:error, reason}, game})
      new_state ->
        { {:ok, new_state}, new_state })
    end
  end

  def handle_call(:reviewed_cards, _from, game) do

  end

  def handle_info({ :end_turn, turn }, game)
  when game.turn.player == turn.player
  do
    { :ok, TeamGame.end_turn(game)})
  end
  def handle_info({ :end_turn, _turn}, game), do: {:noreply, game}

  def handle_info(:timeout, game) do
    {:stop, :normal, "Game has been inactive for 30 minutes. Stopping Server.", game}
  end
end
