defmodule GameniteWeb.Components.Kodenames.Board do
  use Surface.Component

  alias GameniteWeb.Components.Kodenames.Card

  prop(board, :map, required: true)
  prop(finished?, :boolean, default: false)
  prop(spymaster?, :boolean, default: false)
  prop(disabled?, :boolean, default: false)
  prop(flip, :event, required: true)

  def render(assigns) do
    ~F"""
    <div class="grid grid-cols-5 grid-rows-5 h-full gap-6">
      {#for x <- 0..4, y <- 0..4}
          <Card card={Map.get(@board, {x, y})} coords={{x, y}} {=@spymaster?} {=@disabled?} {=@flip} />
      {/for}
    </div>
    """
  end
end
