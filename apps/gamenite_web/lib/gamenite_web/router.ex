defmodule GameniteWeb.Router do
  use GameniteWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {GameniteWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug GameniteWeb.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GameniteWeb do
    pipe_through :browser
    # plug :put_root_layout, {GameniteWeb.LayoutView, :root}

    get "/", GameController, :index

    resources "/users", UserController, only: [:index, :show, :new, :create]
    resources "/sessions", SessionController, only: [:new, :create, :delete]

    resources "/games", GameController, only: [:create, :new, :show, :edit]

    get "/:slug", RoomController, :new
    get "/:slug/:game", RoomController, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", GameniteWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: GameniteWeb.Telemetry
    end
  end
end
