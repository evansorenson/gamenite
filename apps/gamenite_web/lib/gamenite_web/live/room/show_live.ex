defmodule GameniteWeb.Room.ShowLive do
  @moduledoc """
  A LiveView for creating and joining chat rooms
  """

  use GameniteWeb, :live_view
  alias GameSys.Gameplay

  @impl true
  def mount(_params, session, socket) do
    Gameplay.start_game_gen("charades", %{})
    {:ok, socket}
  end
end
