defmodule GameniteWeb.Components.Witbash.Answer do
  use Surface.Component

  alias GameniteWeb.Components.PlayerName

  prop answer, :map, required: true
  prop roommates, :map, required: true
  prop user_id, :any, required: true
  prop on_click, :event, default: nil
  prop show_votes?, :boolean, default: false
  prop cursor_allowed?, :boolean, default: true

  def render(assigns) do
    ~F"""
    <div class="grid grid-flow-row w-96">
      {#if @show_votes?}
        <div class="flex flex-col h-24 items-center justify-center w-full">
          <PlayerName roommate={Map.fetch!(@roommates, @answer.user_id)} {=@user_id} font_size={"text-3xl"} />
          <h3 class="font-bold">+{@answer.score}</h3>
        </div>
      {/if}

      <div :on-click={@on_click} phx-value-voting_user_id={@user_id} phx-value-receiving_user_id={@answer.user_id}
        class={"w-96 px-4 flex flex-col shadow-lg bg-white w-full h-full items-center justify-center"}>
        <div class="flex h-64 w-96 items-center">
          <h1 class="text-center text-5xl text-wrap font-sans:Indie-Flower">{@answer.answer}</h1>
        </div>
      </div>



      {#if @show_votes?}
      <div class="flex flex-wrap items-end justify-center pt-2">
        {#for voter_id <- @answer.votes}
          <div class="flex-none">
            <PlayerName roommate={Map.fetch!(@roommates, voter_id)} {=@user_id} font_size={"text-3xl"} />
          </div>
        {/for}
      </div>
      {/if}
    </div>
    """
  end
end
