defmodule GameniteWeb.Components.PlayerName do
  use Surface.Component

  prop roommate, :map, required: true
  prop user_id, :any, required: true
  prop color, :string, default: nil
  prop font_size, :string, default: "text-lg"

  def render(assigns) do
    assigns = set_color(assigns)

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

  defp set_color(%{color: nil, roommate: roommate} = assigns) do
    assigns
    |> Map.put(:color, roommate.color)
  end
end
