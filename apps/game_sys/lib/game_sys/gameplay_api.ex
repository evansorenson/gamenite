defmodule GameSys.GameplayAPI do
  @server GameSys.CharadesServer

  def start_link(game, uuid) do
    GenServer.start_link(@server, game, name: uuid)
  end

  def next_player(pid), do: GenServer.call(pid, :next_player)
  def draw_card(pid), do: GenServer.call(pid, :draw_card)

end
