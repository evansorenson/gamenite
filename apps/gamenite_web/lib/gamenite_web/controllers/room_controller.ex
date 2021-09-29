defmodule GameniteWeb.RoomController do
  use GameniteWeb, :controller

  import Phoenix.LiveView.Controller
  plug :authenticate_user_or_create_guest when action in [:new]

  def new(conn, %{ "slug" => slug }) do
    conn
    |> live_render(GameniteWeb.RoomLive, session: %{"slug" => slug })
  end

end
