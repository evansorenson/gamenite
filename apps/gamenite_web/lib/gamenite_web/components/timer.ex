defmodule GameniteWeb.Components.Timer do
  use Surface.Component

  prop time_remaining, :integer, required: true

  def render(assigns) do
    ~F"""
    <div class="flex items-center justify-end">
    <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
    <h1 class="text-5xl">{@time_remaining}</h1>
    </div>
    """
  end
end
