defmodule GameniteWeb.Components.Horsepaste.Board do
  use Surface.Component

  alias GameniteWeb.Components.Horsepaste.Card

  prop(board, :map)
  prop(spymaster?, :boolean, required: true)
  prop(disabled?, :boolean, default: true)
  prop(flip, :event, required: true)

  def render(assigns) do
    ~F"""
    <div class="grid grid-cols-5">
      {#for x <- 0..4, y <- 0..4}
      <div class="px-8 py-8">
          <Card card={Map.get(@board, {x, y})} {=@spymaster?} {=@disabled?} {=@flip} />
      </div>
      {/for}
    </div>
    """
  end
end
