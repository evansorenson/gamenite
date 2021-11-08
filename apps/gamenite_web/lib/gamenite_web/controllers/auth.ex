defmodule GameniteWeb.Auth do
  import Plug.Conn
  import Phoenix.Controller
  alias GameniteWeb.Router.Helpers, as: Routes
  alias GamenitePersistance.Accounts

  alias Ecto.UUID

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, :user_id) do
      user_id = get_session(conn, :user_id)
      user = user_id && Accounts.get_user(user_id)
      assign(conn, :current_user, user)
    else
      user_id = UUID.generate()

      conn
      |> assign(:user_id, user_id)
      |> put_session(:user_id, user_id)
    end
  end

  def login(conn, user_id) do
    conn
    |> assign(:user_id, user_id)
    |> put_session(:user_id, user_id)
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
    if conn.assigns.user_id do
      conn
    else
      user_id = Ecto.UIID.generate()
      login(conn, user_id)
    end
  end
end
