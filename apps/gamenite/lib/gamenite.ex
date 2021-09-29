defmodule Gamenite do

  def start_game("Salad Bowl" = game_name, room_uuid) do
    Gamenite.SaladBowlGameKeeper.start_game(game_name, room_uuid)
  end
  def start_game("Charades" = game_name, room_uuid) do
    Gamenite.Charades.start_game(game_name, room_uuid)
  end

  def game_options_changeset("Salad Bowl") do

  end
end
