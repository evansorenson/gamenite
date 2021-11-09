defmodule GameniteWeb.Components.Horsepaste.Card do
  use Surface.Component

  prop(card, :map, required: true)
  prop(disabled?, :boolean, default: true)
  prop(spymaster?, :boolean, required: true)
  prop(flip, :event, required: true)

  def render(assigns) do
    class = card_class(assigns)

    ~F"""
    <button class={class} disa :on-click={@flip}>@card.word</button>
    """
  end

  defp card_class(assigns) do
    base = "w-72 h-48 text-center text-4xl "
    color = card_color(assigns.card)

    cond do
      assigns.flipped? ->
        base <> "hover:text-white disabled bg-#{color} text-#{color}"

      assigns.spymaster? ->
        base <> " bg-white disabled text-#{color}"

      assigns.disabled? ->
        base <> " bg-white text-black disabled"

      true ->
        base <> "bg-white text-black"
    end
  end

  defp card_color(card) do
    case card.type do
      :assassin ->
        "gray-darkest"

      :bystander ->
        "yellow-100"

      :red ->
        "red"

      :blue ->
        "blue"
    end
  end
end
