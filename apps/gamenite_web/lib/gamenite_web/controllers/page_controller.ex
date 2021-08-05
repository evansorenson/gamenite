defmodule GameniteWeb.PageController do
  use GameniteWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
