defmodule GameniteWeb.Components.Charades.Card do
  use Surface.Component

  prop word, :string, required: true

  def render(assigns) do
    ~F"""
      <div class="flex shadow-lg top bg-white w-120 h-96 items-center justify-center">
        <h1 class="text-center text-6xl">{@word}</h1>
      </div>
    """
  end
end
