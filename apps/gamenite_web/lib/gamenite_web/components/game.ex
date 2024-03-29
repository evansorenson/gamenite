defmodule GameniteWeb.Components.Game do
  import Phoenix.LiveView, only: [assign: 2, put_flash: 3]

  def assign_data(
        socket,
        %{slug: slug, game: game, user_id: user_id, roommates: roommates} = _assigns
      ) do
    socket
    |> assign(user_id: user_id)
    |> assign(game: game)
    |> assign(slug: slug)
    |> assign(roommates: roommates)
  end

  def update(
        %{game: game} = _assigns,
        socket
      ) do
    {:ok,
     socket
     |> assign(game: game)}
  end

  def game_callback(:ok, socket) do
    {:noreply, socket}
  end

  def game_callback({:error, reason}, socket) do
    {:noreply, put_flash(socket, :error, reason)}
  end
end
