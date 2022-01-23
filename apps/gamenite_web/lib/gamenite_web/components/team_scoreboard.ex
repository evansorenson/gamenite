defmodule GameniteWeb.Components.TeamScoreboard do
  use Surface.Component

  alias GameniteWeb.Components.PlayerNameConnected

  prop team, :map, required: true
  prop user_id, :any, required: true
  prop roommates, :map, required: true
  prop current_team?, :boolean, default: false

  def render(assigns) do
    ~F"""
    <div class="grid grid-cols-8 w-full rounded-lg items-center space-x-2 px-16">
      <div class="col-span-7">
        <h1 style={"color:#{@team.color}"} class="font-bold text-left text-7xl">{ @team.name }</h1>
        <div class="flex flex-wrap items-center">
          {#for player <- @team.players}
            <PlayerNameConnected roommate={Map.get(@roommates, player.id)} font_size={"text-2xl"} {=@user_id} color={@team.color} />
          {/for}
        </div>
      </div>
      <h1 style={"color:#{@team.color}"} class="font-bold text-7xl text-right">{@team.score}</h1>
    </div>
    """
  end
end
