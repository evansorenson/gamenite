defmodule Game do
  @moduledoc """
  Documentation for `GameSys`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> GameSys.hello()
      :world

  """

  def start_link(id, game) do
    GenServer.start_link(Game.Server, game, name: id)
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

  def discard(room_uuid, card, hand, discard_pile) do
    GenServer.cast(room_uuid, {:discard, card, hand, discard_pile})
  end

  def add_player(room_uuid, player) do
    GenServer.cast(room_uuid, {:add_player, player})
  end

  def state(room_uuid) do
    GenServer.call(room_uuid, :state)
  end
end
