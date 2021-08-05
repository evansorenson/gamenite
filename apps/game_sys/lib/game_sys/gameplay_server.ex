defmodule GameSys.GameplayServer do
  use GenServer

  alias GameSys.Gameplay

  @impl true
  def init(game_map) do
    {:ok, game_map}
  end

  @impl true
  def handle_call(:next_player, _from, {teams, current_player}) do
    { next_player, updated_game } = Gameplay.next_player(teams, current_team)

    {:reply,
    next_player,
    updated_game
    }
  end

  def handle_cast({:add_player, player}, {teams, current_team}) do
    {:noreply,
    {teams
    |> Gameplay.add_player(player),
    current_team
    }
    }
  end

  def start_link(game_map) do
    IO.inspect game_map

    game_map = Map.put_new(game_map, :name, name())
    GenServer.start_link(__MODULE__, game_map)
  end

end
