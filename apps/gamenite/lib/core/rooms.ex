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
  @spec join(%{:connected_users => map, optional(any) => any}, any) ::
          {:error, <<_::104>>} | %{:connected_users => map, optional(any) => any}
  def join(%{connected_users: connected_users}, _player)
  when map_size(connected_users) >= @max_room_size
  do
    {:error, "Room is full."}
  end
  def join(%{connected_users: %{}} = room, player) do
    do_join(room, Map.put(player, :host?, true))
  end
  def join(room, player), do: do_join(room, player)
  def do_join(%{connected_users: connected_users} = room, %{user_id: id} = player) do
    %{ room | connected_users: Map.put_new(connected_users, id, player)}
  end

  def leave(%{connected_users: connected_users} = room, user_id) do
    %{ room | connected_users: Map.delete(connected_users, user_id)}
  end

  def invert_mute(room, %{muted?: muted?} = player) do
    do_mute(room, player, not muted?)
  end

  def mute_all(room, host_player) do
    do_mute_all(room, true)
    |> do_mute(host_player, false)
  end

  def unmute_all(room) do
    do_mute_all(room, false)
  end

  defp do_mute(%{connected_users: connected_users} = room, %{user_id: id} = player, mute?) do
    connected_users = Map.put(connected_users, id, %{player | muted?: mute?})

    room
    |> Map.put(:connected_users, connected_users)
  end

  defp do_mute_all(%{connected_users: connected_users} = room, mute?) do
   users = for {k, v} <- connected_users, into: %{} do
     {k, %{v | muted?: mute?}}
   end

   %{ room | connected_users: users}
  end
end
