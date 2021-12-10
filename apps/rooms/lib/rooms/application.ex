defmodule Rooms.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: Rooms.PubSub},
      {Registry, [name: Rooms.Registry.Room, keys: :unique]},
      {DynamicSupervisor, [name: Rooms.Supervisor.Room, strategy: :one_for_one]}
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
