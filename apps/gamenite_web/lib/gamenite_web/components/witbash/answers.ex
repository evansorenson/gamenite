defmodule GameniteWeb.Components.Witbash.Answers do
  use Surface.Component

  alias GameniteWeb.Components.PlayerName

  prop prompt, :map, required: true
  prop roommates, :map, required: true
  prop user_id, :any, required: true
  prop on_click, :event, default: nil
  prop show_votes?, :boolean, default: false

  def render(assigns) do
    ~F"""
    {#case @prompt.answers}
      {#match []}
        <div class="flex flex-wrap justify-center">
        {#for user_id <- @prompt.assigned_user_ids}
          <PlayerName roommate={Map.fetch!(@roommates, user_id)} {=@user_id} font_size={"text-3xl"} />
        {/for}
        </div>
        <h3>Did not submit any answers! No points for you :(</h3>}
      {#match [only_answer | []]}
        {#for user_id <- @prompt.assigned_user_ids}
            <PlayerName roommate={Map.fetch!(@roommates, user_id)} {=@user_id} font_size={"text-3xl"} />
        {/for}
      {#match answers}
        <div class="flex flex-wrap justify-center">
        {#for answer <- answers }
          <div class="pb-8 w-96 px-4">
            <div :on-click={if answer.user_id == @user_id do nil else @on_click end} phx-value-voting_user_id={@user_id} phx-value-receiving_user_id={answer.user_id}
                class={"flex flex-col shadow-lg bg-white w-full h-full items-center justify-center"}>

            {#if @show_votes?}
              <div class="flex flex-wrap justify-center py-2">
                {#for voter_id <- answer.votes}
                  <PlayerName roommate={Map.fetch!(@roommates, voter_id)} {=@user_id} font_size={"text-3xl"} />
                {/for}
              </div>
            {/if}
              <div class="flex h-64 items-center">
                <h1 class="text-center text-6xl text-wrap font-sans:Indie-Flower">{answer.answer}</h1>
              </div>
            {#if @show_votes?}
              <div class="pb-4">
                <PlayerName roommate={Map.fetch!(@roommates, answer.user_id)} {=@user_id} font_size={"text-3xl"} />
              </div>
            {/if}
            </div>
          </div>
        {/for}
        </div>
    {/case}
    """
  end
end
