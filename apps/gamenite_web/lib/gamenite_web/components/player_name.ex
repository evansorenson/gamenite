defmodule GameniteWeb.Components.PlayerName do
  use Surface.Component

  prop player, :map, required: true
  prop user_id, :any, required: true
  prop color, :string, required: true
  prop font_size, :string, default: "text-lg"

  def render(assigns) do
    ~F"""
    <div class="flex px-1 py-1">
      <div style={"border-color:#{@color}"} class="flex items-center justify-center rounded-lg shadow-md border-2 px-2">
        <h1 style={"color:#{@color}"} class={"#{@font_size} font-semibold pl-1"}>
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
