defmodule GameniteWeb.Components.SaladBowl do
  use Surface.LiveComponent
  import GameniteWeb.Components.Game

  alias GameniteWeb.Components.Charades.{Card}
  alias GameniteWeb.Components.{TeamsScoreboard, PlayerName}

  alias Gamenite.SaladBowl.API
  alias Gamenite.TeamGame

  data game, :map
  data user_id, :any
  data slug, :string
  data roommates, :map

  @impl true
  def handle_event("correct", _params, socket) do
    card_completed(socket, :correct)
  end

  @impl true
  def handle_event("incorrect", _params, socket) do
    card_completed(socket, :incorrect)
  end

  @impl true
  def handle_event("skip", _params, socket) do
    card_completed(socket, :skipped)
  end

  @impl true
  def handle_event("change_correct", %{"card_index" => card_index}, socket) do
    change_card_outcome(socket, card_index, :correct)
  end

  @impl true
  def handle_event("change_incorrect", %{"card_index" => card_index}, socket) do
    change_card_outcome(socket, card_index, :incorrect)
  end

  @impl true
  def handle_event("change_skip", %{"card_index" => card_index}, socket) do
    change_card_outcome(socket, card_index, :skipped)
  end

  @impl true
  def handle_event("start_turn", _params, socket) do
    API.start_turn(socket.assigns.slug)
    |> game_callback(socket)
  end

  @impl true
  def handle_event("end_turn", _params, socket) do
    API.end_turn(socket.assigns.slug)
    |> game_callback(socket)
  end

  def handle_event("submit_words", params, socket) do
    word_list = Enum.map(params, fn {_k, v} -> v end)

    API.submit_cards(socket.assigns.slug, word_list, socket.assigns.user_id)
    |> game_callback(socket)
  end

  defp card_completed(socket, outcome) do
    API.card_completed(socket.assigns.slug, outcome)
    |> game_callback(socket)
  end

  defp change_card_outcome(socket, card_index, outcome) do
    API.change_card_outcome(socket.assigns.slug, String.to_integer(card_index), outcome)
    |> game_callback(socket)
  end
end
