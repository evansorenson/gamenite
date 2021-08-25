defmodule Game.Server do
  use GenServer

  alias Gamenite.Cards
  alias Gameplay.TeamGame

  # Server
  def init(game) do
    {:ok, game}
  end

  def handle_call(:state, _from, game) do
    { :reply, game, game }
  end

  def handle_call({:add_player, player}, _from, game) do
    { :reply, :ok, TeamGame.add_player(game, player)}
  end

  # def handle_call(:start_turn, _form, game) do
  #   { :reply, :ok, }
  # end

  def handle_call({:draw_card, num_cards}, _from, game) do
    { :reply, :ok, TeamGame.draw_card(game, num_cards)}
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
    case TeamGame.skip_card(game, card) do
      {:error, reason} ->
        {:reply, {:error, reason}, game}
      game ->
        {:reply, :ok, game}
    end
    { :reply, TeamGame.skip_card(game, card) }
  end

  # API

  def start_link(room_uuid, game) do
    GenServer.start_link(Game.Server, game, name: room_uuid)
  end

  def draw(room_uuid, num_cards) do
    GenServer.cast(room_uuid, {:draw, num_cards})
  end

  def draw_with_reshuffle(room_uuid, num_cards) do
    GenServer.cast(room_uuid, {:draw_with_reshuffle, num_cards})
  end

  def shuffle_deck(room_uuid) do
    GenServer.call(room_uuid, :shuffle)
  end

  def skip_card(room_uuid, card) do
    GenServer.call(room_uuid, {:skip_card, card})
  end

  def add_player(room_uuid, player) do
    GenServer.call(room_uuid, {:add_player, player})
  end

  def state(room_uuid) do
    GenServer.call(room_uuid, :state)
  end
end
