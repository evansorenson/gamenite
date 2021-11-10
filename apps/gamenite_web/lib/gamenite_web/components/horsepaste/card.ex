defmodule GameniteWeb.Components.Horsepaste.Card do
  use Surface.Component

  prop(card, :map, required: true)
  prop(coords, :tuple, required: true)
  prop(disabled?, :boolean, default: true)
  prop(spymaster?, :boolean, required: true)
  prop(flip, :event, required: true)

  def render(assigns) do
    class = card_class(assigns)

    ~F"""
    <h1>{IO.inspect(List.to_string(Tuple.to_list(@coords)))}</h1>
    <span>
    <button class={class} phx-value="1" disabled={@disabled?} :on-click={@flip}>{@card.word}</button>
    </span>
    """
  end

  defp card_class(assigns) do
    base =
      "w-full xs:text-lg sm:text-xl md:text-2xl sm:h-32 md:h-36 lg:h-42 text-center rounded-none border-0 disabled:opacity-100 "

    color = card_color(assigns.card)

    cond do
      assigns.card.flipped? ->
        base <> "hover:text-white hover:cursor-not-allowed bg-#{color} text-#{color}"

      assigns.spymaster? ->
        if assigns.card.type == :assassin do
          base <> " bg-white cursor-not-allowed text-#{color} border-4 border-black"
        else
          base <> " bg-white cursor-not-allowed text-#{color}"
        end

      assigns.disabled? ->
        base <> " bg-white text-black cursor-not-allowed hover:bg-white"

      true ->
        base <>
          "bg-white text-black hover:shadow-xl hover:bg-gray-light"
    end
  end

  defp card_color(card) do
    case card.type do
      :assassin ->
        "gray-darkest"

      :bystander ->
        "yellow-600"

      :red ->
        "red-600"

      :blue ->
        "blue-600"
    end
  end
end
