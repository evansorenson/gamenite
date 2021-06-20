defmodule Gamenite.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Gamenite.Repo,
      # Start the Telemetry supervisor
      GameniteWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Gamenite.PubSub},
      # Start our Presence module.
      GameniteWeb.Presence,
      # Start the Endpoint (http/https)
      GameniteWeb.Endpoint,
      # Start the STUN server
      GameniteWeb.Stun
      # Start a worker by calling: Gamenite.Worker.start_link(arg)
      # {Gamenite.Worker, arg}

    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gamenite.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    GameniteWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
