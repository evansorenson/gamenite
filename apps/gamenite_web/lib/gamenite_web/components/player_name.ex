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
      {#if @roommate.id == @user_id}
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd" />
        </svg>
      {/if}
        <h1 style={"color:#{@color}"} class={"#{@font_size} font-semibold pl-1"}>
            {@roommate.name}
        </h1>
      </div>
    </div>
    """
  end

  defp set_color(%{color: nil, roommate: roommate} = assigns) do
    assigns
    |> Map.put(:color, roommate.color)
  end

  defp set_color(assigns) do
    assigns
  end
end
