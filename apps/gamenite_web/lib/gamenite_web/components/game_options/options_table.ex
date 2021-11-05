defmodule GameniteWeb.Components.ChangesetTable do
  use Surface.Component

  slot rows

  def render(assigns) do
    ~F"""
      <table class="table shadow-md">
        <tbody>
          {#for row <- @rows}
            <#slot name="rows" />
          {/for}
        </tbody>
      </table>
    """
  end
end
