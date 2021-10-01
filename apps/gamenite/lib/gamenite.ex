defmodule Gamenite do
  alias Gamenite.TeamGame
  alias GamenitePersistance.Accounts
  alias Gamenite.{SaladBowlGameKeeper}

  def construct_game_data(game_info, game_options, connected_users, player_constructor_fn, opts \\ [])
  def construct_game_data(%{type: "Team Game"} = _game_info, game_options, connected_users, player_constructor_fn, [num_teams: num_teams]) do
    connected_users
    |> users_to_players
    |> Enum.map(fn player -> player_constructor_fn.(%{player: player }) end)
    |> TeamGame.Team.split_teams(num_teams)
    |> TeamGame.new(game_options)
  end
  def construct_game_data(%{type: "Single Player"} = _game_info, game_options, connected_users, player_constructor_fn, _opts) do
    |> users_to_players
    |> Enum.map(fn player -> player_constructor_fn.(%{player: player }) end)
    |> SingleGame.new(game_options)
  end

  defp users_to_players(connected_users) do
    connected_users
    |> Map.to_list()
    |> Enum.map(fn {_k, %{user_id: user_id} = _roommate} -> Accounts.get_user_by(%{id: user_id}) end)
    |> TeamGame.Player.new_players_from_users()
  end

  def start_game(%{title: "Salad Bowl"} = game, room_uuid) do
    Gamenite.SaladBowlGameKeeper.start_game(game, room_uuid)
  end
  def start_game(%{title: "Charades"} = game, room_uuid) do
    Gamenite.Charades.start_game(game, room_uuid)
  end

  def game_options_changeset("Salad Bowl") do

  end
end
