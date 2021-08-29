defmodule Gamenite.Core.Cards.Card do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :face, :string
    field :back, :string
    field :face_image, :string
    field :back_image, :string
    field :is_face_up, :boolean, default: false
    field :is_correct, :boolean, default: false
  end

  def changeset do

  end

  def new() do

  end

  def persistant_card_to_new() do

  end


  @doc """
  Flips card by changing is_face_up value in card struct.

  Returns %Cards.Card{}.
  """
  def flip_card(%Card{} = card) do
    %{ card | is_face_up: !card.is_face_up }
  end
  def flip_card(%Card{} = card, is_face_up) do
   %{ card | is_face_up: is_face_up }
  end

  @doc """
  Returns { drawn_cards, remaining_deck}.
  """
  def draw(deck, num, is_face_up \\ true)
  def draw(_, num, _) when num < 1 or not is_integer(num), do: {:error, "Number of cards drawn must be positive integer."}
  def draw(deck, num, _) when num > Kernel.length(deck), do: {:error, "Not enough cards in deck."}
  def draw(deck, num, is_face_up) do
    {drawn_cards, remaining_deck} = Enum.split(deck, num)

    drawn_flipped_cards = Enum.map(drawn_cards, &(flip_card(&1, is_face_up)))
    { drawn_flipped_cards, remaining_deck }
  end

  @doc """
  Similar to draw but includes discard pile for reshuffles. If num > length of deck remaining, then will
  shuffle discard pile and draw remaining cards from there.

  Returns { drawn_cards, remaining_deck, discard_pile }
  """
  def draw_with_reshuffle(deck, discard_pile, num, is_face_up \\ true)
  def draw_with_reshuffle(deck, discard_pile, num, _) when num > Kernel.length(discard_pile) + Kernel.length(deck) do
    { :error, "Number of cards drawn must be less than left in deck and discard pile combined."}
  end
  def draw_with_reshuffle(deck, discard_pile, num, is_face_up) when num <= Kernel.length(deck) do
    { drawn_cards, remaining_deck } = draw(deck, num, is_face_up)
    { drawn_cards, remaining_deck, discard_pile }
  end
  def draw_with_reshuffle(deck, discard_pile, num, is_face_up) when Kernel.length(deck) == 0 do
    replenished_deck = Enum.shuffle(discard_pile)
    { drawn_after_reshuffle, remaining_deck } = draw(replenished_deck, num, is_face_up)
    { drawn_after_reshuffle , remaining_deck, [] }
  end
  def draw_with_reshuffle(deck, discard_pile, num, is_face_up) do
    cards_left = Kernel.length(deck)
    { initial_drawn_cards, _ } = draw(deck, cards_left, is_face_up)

    replenished_deck = Enum.shuffle(discard_pile)
    { drawn_after_reshuffle, remaining_deck } = draw(replenished_deck, num - cards_left, is_face_up)
    { initial_drawn_cards ++ drawn_after_reshuffle, remaining_deck, [] }
  end

  @doc """
  Draws cards and adds them to hand.

  Returns {[hand], [remaining_deck], [discard_pile]}
  """

  def draw_into_hand(deck, hand, num \\ 1) do
    case draw(deck, num) do
      { :error, reason } ->
        { :error, reason }

      { drawn_cards, remaining_deck } ->
        { [ drawn_cards | hand ], remaining_deck }
    end
  end

  def draw_into_hand_with_reshuffle(deck, hand, discard_pile, num \\ 1) do
    case draw_with_reshuffle(deck, discard_pile, num) do
      { :error, reason } ->
        { :error, reason }

      { drawn_cards, remaining_deck, new_discard_pile } ->
        { [ drawn_cards | hand ], remaining_deck, new_discard_pile }
    end
  end

  @doc """
  Shuffles deck.

  Returns deck in random order.
  """
  def shuffle(deck), do: Enum.shuffle(deck)

  @doc """
  Moves card from one pile to another.

  Returns { [origin_pile], [destination_pile] }
  """
  def move_card(card, origin_pile, destination_pile) do
    { List.delete(origin_pile, card), [ card | destination_pile ]}
  end

  def correct_card(card) do
    card
    |> Map.put(:is_correct, true)
  end
end
