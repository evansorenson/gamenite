defmodule Gamenite.PlayingCards do
  alias Gamenite.PlayingCards.{PlayingCard}

  @doc """
  Flips card by changing face_up? value in card struct.

  Returns %PlayingCard{}.
  """
  def flip(%PlayingCard{} = card) do
    %{card | face_up?: !card.face_up?}
  end

  def flip(%PlayingCard{} = card, true), do: flip_face_up(card)
  def flip(%PlayingCard{} = card, false), do: flip_face_down(card)

  def flip_face_down(%PlayingCard{} = card) do
    %{card | face_up?: false}
  end

  def flip_face_up(%PlayingCard{} = card) do
    %{card | face_up?: true}
  end

  @doc """
  Creates deck of playing cards.

  Returns [ %{PlayingCard} ]
  """
  @card_suits ["❤️", "♠️", "♣️", "♦️"]
  @card_suits_in_int 0..3
  @card_ranks ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
  @card_ranks_in_int 2..14

  defp create_deck do
    Enum.flat_map(
      @card_suits_in_int,
      fn suit ->
        Enum.map(@card_ranks_in_int, fn rank -> create_card(suit, rank) end)
      end
    )
  end

  defp create_card(suit_in_int, rank_in_int) do
    PlayingCard.new(%{suit_in_int: suit_in_int, rank_in_int: rank_in_int})
  end
end
