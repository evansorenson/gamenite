defmodule GameniteWeb.Components.Kodenames.Card do
  use Surface.Component

  prop(card, :map, required: true)
  prop(coords, :tuple, required: true)
  prop(disabled?, :boolean, required: true)
  prop spymaster?, :boolean, required: true
  prop finished?, :boolean, required: true
  prop(flip, :event, required: true)

  def render(assigns) do
    class = card_class(assigns)
    # disabled? = set_disabled(assigns)

    ~F"""
    <button class={class} phx-value-x={elem(@coords, 0)} phx-value-y={elem(@coords, 1)} disabled={@disabled?} :on-click={@flip}>{@card.word}</button>
    """
  end

  defp card_class(assigns) do
    base =
      "w-full xs:text-lg sm:text-xl md:text-2xl sm:h-32 md:h-36 lg:h-42 text-center rounded-none border-0 disabled:opacity-100 rounded-md shadow-md "

    color = card_color(assigns.card)

    cond do
      # game is finished show flipped at full opacity, unflipped with light opacity
      assigns.finished? ->
        if assigns.card.flipped? do
          base <> "cursor-not-allowed bg-#{color} text-white"
        else
          base <> "cursor-not-allowed bg-#{color} opacity-50 text-black"
        end

      # card that is flipped is same for everyone
      assigns.card.flipped? ->
        base <> "hover:text-white cursor-not-allowed bg-#{color} text-#{color}"

      # current user of teams is spymaster
      assigns.spymaster? ->
        spymaster_classes(assigns.card, base, color)

      # cards for guessers, if disabled show cursor as not allowed
      true ->
        if assigns.disabled? do
          base <> " bg-white text-black cursor-not-allowed hover:bg-white"
        else
          base <>
            "bg-white text-black hover:shadow-xl hover:bg-gray-light"
        end
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

  defp spymaster_classes(card, base, color) do
    case card.type do
      :assassin ->
        base <> " bg-gray-dark cursor-not-allowed text-white border-4 border-black"

      :bystander ->
        base <> " bg-white cursor-not-allowed text-black"

      _ ->
        base <> " bg-white cursor-not-allowed text-#{color}"
    end
  end
end
