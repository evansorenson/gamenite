defmodule GameniteWeb.Components.Horsepaste.Card do
  use Surface.Component

  prop(card, :map, required: true)
  prop(disabled?, :boolean, default: true)
  prop(spymaster?, :boolean)
  prop(flip, :event)

  def render(assigns) do
    class = card_color("text-", @card)

    ~F"""
    """

    # ~F"""
    # {#if @card.flipped?}
    # <button class="hover:text-white disabled #{card_color}">
    #   {@card.word}
    # </button>
    # {#elseif @spymaster?}
    # <button class={card_class(@card)}, card_color("text-", @card), "disabled": true}>
    #   {@card.word}
    # </button>
    # {#else}
    # <button :on-click={@flip} class={"w-72 h-48 text-black bg-white text-center text-4xl", "disabled": @disabled?, card_color("bg-", @card)}>
    # {@card.word}
    # </button>
    # {/if}

    # """
  end

  @spymaster_class "disabled"

  defp card_class(card) do
    "w-72 h-48 text-center text-4xl "
  end

  defp card_color(string, card) do
    case card.type do
      :assassin ->
        string <> "gray-darkest"

      :bystander ->
        string <> "yellow-100"

      :red ->
        string <> "red"

      :blue ->
        string <> "blue"
    end
  end
end
