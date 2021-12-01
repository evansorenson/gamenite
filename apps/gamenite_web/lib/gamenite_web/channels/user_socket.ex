defmodule GameniteWeb.UserSocket do
  use Phoenix.Socket

  channel("room:*", GameniteWeb.RoomChannel)

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    with {:ok, user_id} <- GameniteWeb.Auth.verify_token(token) do
      {:ok, assign(socket, :user_id, user_id)}
    else
      {:error, _reason} ->
        :error
    end
  end

  @impl true
  def id(_socket), do: nil
end
