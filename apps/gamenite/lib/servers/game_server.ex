defmodule Gamenite.Game.Server do
  alias Phoenix.PubSub

  defmacro __using__([]) do
    quote do
      use GenServer
      require Logger

      import Gamenite.Game.Server, only: [game_response: 2, broadcast_game_update: 1]

      def start_link({game, room_uuid}) do
        GenServer.start_link(
          __MODULE__,
          {game, room_uuid},
          name: Gamenite.Game.API.via(room_uuid)
        )
      end

      def handle_call(:state, _from, game) do
        {:reply, {:ok, game}, game}
      end

      def handle_info(:timeout, game) do
        Logger.info("Game inactive. Shutting down.")
        {:stop, :normal, game}
      end
    end
  end

  def broadcast_game_update(game) do
    PubSub.broadcast(Gamenite.PubSub, "game:" <> game.room_slug, {:game_update, game})
  end

  @timeout Application.get_env(:gamenite, :game_timeout)
  def game_response({:error, reason}, old_state) do
    {:reply, {:error, reason}, old_state, @timeout}
  end

  def game_response(new_state, _old_state) do
    broadcast_game_update(new_state)
    {:reply, :ok, new_state, @timeout}
  end
end
