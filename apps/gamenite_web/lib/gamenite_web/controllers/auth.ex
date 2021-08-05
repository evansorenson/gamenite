defmodule GameniteWeb.Auth do
  import Plug.Conn
  import Phoenix.Controller
  alias GameniteWeb.Router.Helpers, as: Routes
  alias Gamenite.Accounts.User
  alias Gamenite.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)
    user = user_id && Gamenite.Accounts.get_user(user_id)
    assign(conn, :current_user, user)
  end

  def login(conn, user) do
    IO.inspect user
    conn
    |> assign(:current_user, user)
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
  end

  def logout(conn) do
    configure_session(conn, drop: true)
  end

  def authenticate_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page.")
      |> redirect(to: Routes.game_path(conn, :index))
      |> halt()
    end
  end

  def authenticate_user_or_create_guest(conn, _opts) do
    IO.inspect conn
    if conn.assigns.current_user do
      conn
    else
      {:ok, guest_user } = Accounts.create_user(%{username: "Guest#{:rand.uniform(1000000)}"})
      login(conn, guest_user)
    end
  end
end
