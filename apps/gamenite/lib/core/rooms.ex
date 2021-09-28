defmodule Gamenite.Rooms do
  def join(room, player, password) do
    cond do
      Pbkdf2.verify_pass(password, room.password) ->
        join(room, player)
      true ->
        {:error, "Invalid password."}
    end
  end

  @max_room_size 8
  def join(%{connected_users: connected_users}, _player)
  when map_size(connected_users) >= @max_room_size
  do
    {:error, "Room is full."}
  end
  def join(%{password: password}, _player)
  when not is_nil(password)
  do
    {:error, "Room requires password."}
  end
  def join(%{connected_users: %{}} = room, player) do
    do_join(room, Map.put(player, :host?, true))
  end
  def join(room, player), do: do_join(room, player)
  def do_join(%{connected_users: connected_users} = room, %{user_id: id} = player) do
    %{ room | connected_users: Map.put_new(connected_users, id, player)}
  end

  def leave(%{connected_users: connected_users} = room, %{user_id: id} = _player) do
    %{ room | connected_users: Map.delete(connected_users, id)}
  end

  def change_mute_status(room, %{muted?: muted?} = player) do
    do_mute(room, player, not muted?)
  end

  def mute_all(room, host_player) do
    do_mute_all(room, true)
    do_mute(room, host_player, false)
  end

  def unmute_all(room) do
    do_mute_all(room, false)
  end

  defp do_mute(%{connected_users: connected_users} = room, %{id: player_id} = _player, mute?) do
    players = Enum.map(connected_users, fn
      %{id: ^player_id} = player -> %{player | muted?: mute?}
      player -> player end )

    %{room | connected_users: players}
  end

  def do_mute_all(%{connected_users: connected_users} = room, mute?) do
    Enum.reduce(connected_users, room, fn player, room -> do_mute(room, player, mute?) end)
  end
end
