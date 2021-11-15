defmodule GameniteWeb.Components.PlayerNameConnected do
  use Surface.Component

  prop player, :map, required: true
  prop user_id, :any, required: true
  prop roommate, :map, required: true
  prop color, :string, required: true

  def render(assigns) do
    ~F"""
    <div class="flex px-0.5 py-0.5">
      <div style={"border-color:#{@color}"} class="flex items-center justify-center rounded-lg shadow-md border-2 px-2">
        {#if @roommate.connected?}
        <div class="h-3 w-3 bg-green-600 rounded-full"/>
        {#else}
          <div class="h-3 w-3 bg-red-600 rounded-full"/>
        {/if}
        <h1 style={"color:#{@color}"} class="text-lg font-semibold pl-1">
          {#if @player.id == @user_id}
            {@player.name} (You)
          {#else}
            {@player.name}
          {/if}
        </h1>
      </div>
    </div>
    """
  end
end
