defmodule Gamenite.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: Gamenite.PubSub},
      {Registry, [name: Gamenite.Registry.Game, keys: :unique]},
      {DynamicSupervisor, [name: Gamenite.Supervisor.Game, strategy: :one_for_one]},
      {Registry, [name: Gamenite.Registry.Room, keys: :unique]},
      {DynamicSupervisor, [name: Gamenite.Supervisor.Room, strategy: :one_for_one]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gamenite.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
