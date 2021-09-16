defmodule GameniteWeb.RoomController do
  use GameniteWeb, :controller

  import Phoenix.LiveView.Controller
  plug :authenticate_user_or_create_guest when action in [:new, :show]


  alias GameniteWeb.Room

  def new(conn, %{ "slug" => slug, "game_id" => game_id }) do
    conn
    |> live_render(Room.NewLive, session: %{"slug" => slug, "user_id" => get_session(conn, :user_id), "game_id" => game_id })
  end

  def show(conn, %{ "slug" => slug }) do
    conn
    |> live_render(Room.ShowLive, session: %{"slug" => slug, "user_id" => get_session(conn, :user_id) })
  end

end
