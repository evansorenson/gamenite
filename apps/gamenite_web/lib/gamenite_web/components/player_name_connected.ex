defmodule GameniteWeb.Components.PlayerNameConnected do
  use Surface.Component

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
          {#if @roommate.id == @user_id}
            {@roommate.name} (You)
          {#else}
            {@roommate.name}
          {/if}
        </h1>
      </div>
    </div>
    """
  end
end
