defmodule Gamenite.Rooms.Room do
  defstruct id: nil, name: nil, password: nil, connected_users: %{}, messages: []

  def new(%{password: password} = attrs) do
    hash = Pbkdf2.hash_pwd_salt(password)
    struct!(__MODULE__, Map.replace(attrs, :password, hash))
  end

  def new(attrs) do
    struct!(__MODULE__, attrs)
  end
end