defmodule GameniteWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      GameniteWeb.Endpoint,
      # Start the STUN, server
      GameniteWeb.Stun,
      # Start the Telemetry supervisor
      GameniteWeb.Telemetry,
      # Start our Presence module.
      GameniteWeb.Presence,
      {GameniteWeb.LiveMonitor, %{}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GameniteWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    GameniteWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
