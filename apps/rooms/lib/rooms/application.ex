defmodule Rooms.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    config_common_dtls_key_cert()
    IO.puts("Starting rooms app")

    children = [
      {Phoenix.PubSub, name: Rooms.PubSub},
      {Registry, [name: Rooms.Registry.Room, keys: :unique]},
      {DynamicSupervisor, [name: Rooms.Supervisor.Room, strategy: :one_for_one]}
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end

  defp config_common_dtls_key_cert() do
    {:ok, pid} = ExDTLS.start_link(client_mode: false, dtls_srtp: true)
    {:ok, pkey} = ExDTLS.get_pkey(pid)
    {:ok, cert} = ExDTLS.get_cert(pid)
    :ok = ExDTLS.stop(pid)
    Application.put_env(:rooms, :dtls_pkey, pkey)
    Application.put_env(:rooms, :dtls_cert, cert)
  end
end
