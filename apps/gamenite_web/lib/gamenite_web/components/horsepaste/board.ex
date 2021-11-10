defmodule GameniteWeb.Components.Horsepaste.Board do
  use Surface.Component

  alias GameniteWeb.Components.Horsepaste.Card

  prop(board, :map)
  prop(spymaster?, :boolean, required: true)
  prop(disabled?, :boolean, default: true)
  prop(flip, :event, required: true)

  def render(assigns) do
    ~F"""
    <div class="grid grid-cols-5 grid-rows-5 h-full gap-6 md:w-5/6 lg:w-3/4">
      {#for x <- 0..4, y <- 0..4}
          <Card card={Map.get(@board, {x, y})} coords={{x, y}} {=@spymaster?} {=@disabled?} {=@flip} />
      {/for}
    </div>
    """
  end
end
