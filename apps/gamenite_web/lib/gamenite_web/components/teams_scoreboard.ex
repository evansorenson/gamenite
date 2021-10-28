defmodule GameniteWeb.Components.TeamsScoreboard do
  use Surface.Component
  alias GameniteWeb.Components.TeamScoreboard

  prop game, :map, required: true
  prop roommate, :map, required: true
  prop roommates, :map, required: true

  def render(assigns) do
    ~F"""

    <div class="space-y-4 pt-16">
    <div class={"grid grid-cols-#{length(@game.teams)}"}>
      {#for team <- @game.teams}
        {#if team.id == @game.current_team.id}
          <TeamScoreboard team={@game.current_team} roommate={@roommate} roommates={@roommates}/>
        {#else}
          <TeamScoreboard team={team} roommate={@roommate} roommates={@roommates}/>
        {/if}
      {/for}
    </div>
    </div>
    """
  end
end
