defmodule GameniteWeb.Components.TeamsScoreboard do
  use Surface.Component
  alias GameniteWeb.Components.TeamScoreboard

  prop game, :map, required: true
  prop user_id, :any, required: true
  prop roommates, :map, required: true
  prop bg, :string, default: "white"
  prop shadow, :string, default: "md"

  def render(assigns) do
    ~F"""
    <div class={"w-full flex flex-col py-4 space-y-8 bg-#{@bg} rounded-lg shadow-#{@shadow}"}>
      {#for team <- @game.teams}
        {#if team.id == @game.current_team.id}
          <TeamScoreboard team={@game.current_team} {=@roommates} {=@user_id} current_team?={true}/>
        {#else}
          <TeamScoreboard team={team} {=@roommates} {=@user_id}/>
        {/if}
      {/for}
    </div>
    """
  end
end
