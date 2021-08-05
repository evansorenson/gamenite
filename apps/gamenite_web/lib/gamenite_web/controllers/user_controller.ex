defmodule GameniteWeb.UserController do
  use GameniteWeb, :controller

  alias Gamenite.Accounts
  alias Gamenite.Accounts.User
  plug :authenticate_user when action in [:index, :show]

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.html", users: users)
  end

  def new(conn, _params) do
    changeset = Accounts.change_registration(%User{}, %{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> GameniteWeb.Auth.login(user)
        |> put_flash(:info, "#{user.username} created!")
        |> redirect(to: Routes.user_path(conn, :show, user))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
  def show(conn, _params) do
    render(conn, "show.html", user: conn.assigns.current_user)
  end
end
