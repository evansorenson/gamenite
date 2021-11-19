defmodule GameniteWeb.Components.TeamScoreboard do
  use Surface.Component

  alias GameniteWeb.Components.PlayerNameConnected

  prop team, :map, required: true
  prop user_id, :any, required: true
  prop roommates, :map, required: true
  prop current_team?, :boolean, default: false

  def render(assigns) do
    ~F"""
    <div class="flex rounded-lg items-center space-x-2">
      <div class="">
        <!-- <h1 style={"color:#{@team.color}"} class="font-bold text-center text-4xl">{ @team.name }</h1> -->
        <div class="flex flex-wrap justify-center items-center">
          {#for player <- @team.players}
            <PlayerNameConnected roommate={Map.get(@roommates, player.id)} {=@user_id} color={@team.color} />
          {/for}
        </div>
      </div>
      <h1 style={"color:#{@team.color}"} class="font-bold text-center text-5xl">{@team.score}</h1>
    </div>
    """
  end
end
