defmodule GameniteWeb.Components.PlayerNameConnected do
  use Surface.Component

  prop user_id, :any, required: true
  prop roommate, :map, required: true
  prop color, :string, required: true
  prop font_size, :string, default: "text-lg"

  def render(assigns) do
    ~F"""
    <div class="flex px-0.5 py-0.5">
      <div style={"border-color:#{@color}"} class="flex items-center justify-center rounded-lg shadow-md border-2 px-2">

        {#if @roommate.id == @user_id}
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd" />
        </svg>
        {#elseif @roommate.connected?}
        <div class="h-3 w-3 bg-green-600 rounded-full"/>
        {#else}
          <div class="h-3 w-3 bg-red-600 rounded-full"/>
        {/if}
        <h1 style={"color:#{@color}"} class={"#{@font_size} font-semibold pl-1"}>
            {@roommate.name}
        </h1>
      </div>
    </div>
    """
  end
end
