defmodule GameniteWeb.Components.Witbash.Answers do
  use Surface.Component

  alias GameniteWeb.Components.PlayerName
  alias GameniteWeb.Components.Witbash.Answer

  prop prompt, :map, required: true
  prop roommates, :map, required: true
  prop user_id, :any, required: true
  prop on_click, :event, default: nil
  prop show_votes?, :boolean, default: false

  def render(assigns) do
    ~F"""
    <div class="flex flex-wrap items-start justify-center space-x-8">
    {#case @prompt.answers}
      {#match []}
        {#for user_id <- @prompt.assigned_user_ids}
          <PlayerName roommate={Map.fetch!(@roommates, user_id)} {=@user_id} font_size={"text-3xl"} />
        {/for}
        <h3>Did not submit any answers! No points for you :(</h3>}
      {#match [only_answer | []]}
        {#for user_id <- @prompt.assigned_user_ids}
          {#if only_answer.user_id == user_id }
            <Answer answer={only_answer} {=@roommates} {=@user_id} />
          {#else}

          <Answer answer={%Gamenite.Witbash.Answer{answer: "", user_id: @user_id}} {=@roommates} {=@user_id} />
            <PlayerName roommate={Map.fetch!(@roommates, user_id)} {=@user_id} font_size={"text-3xl"} />
          {/if}
        {/for}
      {#match answers}
        {#for answer <- answers }
          {#if @user_id in @prompt.assigned_user_ids}
            <Answer answer={answer} {=@roommates} {=@user_id} {=@show_votes?} />
          {#else}
            <Answer answer={answer} {=@roommates} {=@user_id} {=@show_votes?} {=@on_click} />
          {/if}
        {/for}
    {/case}
    </div>
    """
  end
end
