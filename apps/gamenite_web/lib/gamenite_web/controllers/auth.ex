defmodule GameniteWeb.Auth do
  import Plug.Conn
  import Phoenix.Controller
  alias GameniteWeb.Router.Helpers, as: Routes
  alias GamenitePersistance.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        IO.puts("no user_id yet")

        user_id = Ecto.UUID.generate()

        conn
        |> login(user_id)

      user_id ->
        login(conn, user_id)
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

  @salt "1Z73WxH/cDS96wsHXXI8QVAFOy5tg/APqIufGTO8nO2cTn/Mtp7zCnrx+0fSVY1/"
  @max_age 86_400

  def sign(conn, data) do
    Phoenix.Token.sign(conn, @salt, data)
  end

  def verify_token(token) do
    Phoenix.Token.verify(GameniteWeb.Endpoint, @salt, token, max_age: @max_age)
  end
end
