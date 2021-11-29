defmodule GameniteWeb.Components.Witbash.AnswerComp do
  use Surface.Component

  alias GameniteWeb.Components.PlayerName

  prop answer, :map, required: true
  prop roommates, :map, required: true
  prop user_id, :any, required: true
  prop on_click, :event, default: nil
  prop show_votes?, :boolean, default: false

  def render(assigns) do
    class = set_class(assigns)

    ~F"""
    <div :on-click={@on_click} phx-value-voting_user_id={@user_id} phx-value-receiving_user_id={@answer.user_id} class={class <> "flex flex-col shadow-lg bg-white w-full h-full items-center justify-center"}>
      {#if @show_votes?}
        <div class="flex flex-wrap justify-center py-2">
          {#for voter_id <- @answer.votes}
            <PlayerName roommate={Map.fetch!(@roommates, voter_id)} {=@user_id} font_size={"text-3xl"} />
          {/for}
        </div>
      {/if}
      <div class="flex h-64 items-center">
        <h1 class="text-center text-6xl font-sans:Indie-Flower">{@answer.answer}</h1>
      </div>
      {#if @show_votes?}
        <div class="pb-4">
          <PlayerName roommate={Map.fetch!(@roommates, @answer.user_id)} {=@user_id} font_size={"text-3xl"} />
        </div>
      {/if}
    </div>
    """
  end

  defp set_class(assigns) do
    unless assigns.on_click do
      "cursor-not-allowed "
    else
      "cursor-pointer "
    end
  end
end
