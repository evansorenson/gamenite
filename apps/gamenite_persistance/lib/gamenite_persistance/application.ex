defmodule GamenitePersistance.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      GamenitePersistance.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: GamenitePersistance.PubSub},
      # Start a worker by calling: Gamenite.Worker.start_link(arg)
      # {Gamenite.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GamenitePersistance.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # # Tell Phoenix to update the endpoint configuration
  # # whenever the application is updated.
  # def config_change(changed, _new, removed) do
  #   GameniteWeb.Endpoint.config_change(changed, removed)
  #   :ok
  # end
end
