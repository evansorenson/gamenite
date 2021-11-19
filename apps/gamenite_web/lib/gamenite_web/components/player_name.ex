defmodule GameniteWeb.Components.PlayerName do
  use Surface.Component

  prop roommate, :map, required: true
  prop user_id, :any, required: true
  prop color, :string, required: true
  prop font_size, :string, default: "text-lg"

  def render(assigns) do
    ~F"""
    <div class="flex px-1 py-1">
      <div style={"border-color:#{@color}"} class="flex items-center justify-center rounded-lg shadow-md border-2 px-2">
        <h1 style={"color:#{@color}"} class={"#{@font_size} font-semibold pl-1"}>
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
