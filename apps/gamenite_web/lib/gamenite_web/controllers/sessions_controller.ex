defmodule GameniteWeb.SessionController do
  use GameniteWeb, :controller

  def new(conn, _) do
    render(conn, "new.html")
  end

  def create(conn, %{"session" => %{"username" => username, "password" => pass}}) do
    case GamenitePersistance.Accounts.authenticate_by_username_and_pass(username, pass) do
      {:ok, user} ->
        conn
        |> GameniteWeb.Auth.login(user)
        |> put_flash(:info, "Welcome back, #{user.username}!")
        |> redirect(to: Routes.game_path(conn, :index))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid username/password combination.")
        |> render("new.html")
    end
  end

  def delete(conn, _) do
    conn
    |> GameniteWeb.Auth.logout()
    |> put_flash(:info, "Successfully logged out!")
    |> redirect(to: Routes.game_path(conn, :index))
  end
end
