defmodule GameniteWeb.Components.TeamScoreboard do
  use Surface.Component

  prop team, :map, required: true
  prop roommate, :map, required: true
  prop roommates, :map, required: true

  def render(assigns) do
    ~F"""
    <div>
      <h1 style={"color:##{@team.color}"} class="font-bold text-center text-5xl">{ @team.name }</h1>
        <div class="flex flex-wrap pt-2 justify-center items-center">
          {#for player <- @team.players}
              <div class="flex px-1 py-1">
                <div style={"border-color:##{@team.color}"} class="flex items-center justify-center rounded-lg shadow-md border-2 px-2">
                  {#if Map.get(@roommates, player.id).connected?}
                  <div class="h-3 w-3 bg-green-600 rounded-full"/>
                  {#else}
                    <div class="h-3 w-3 bg-red-600 rounded-full"/>
                  {/if}
                  <h1 style={"color:##{@team.color}"} class="text-lg font-semibold pl-1">
                    {#if player.id == @roommate.user_id}
                      {player.name} (You)
                    {#else}
                      {player.name}
                    {/if}
                  </h1>
                </div>
              </div>
          {/for}
        </div>
      <h1 style={"color:##{@team.color}"} class="py-2 font-bold text-center text-4xl">{@team.score}</h1>
    </div>
    """
  end
end
