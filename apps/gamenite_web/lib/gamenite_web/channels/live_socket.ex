defmodule GameniteWeb.LiveSocket do
  @moduledoc """
  The LiveView socket for Phoenix Endpoints.
  """
  use Phoenix.Socket

  require Logger

  if Version.match?(System.version(), ">= 1.8.0") do
    @derive {Inspect,
             only: [
               :id,
               :endpoint,
               :router,
               :view,
               :parent_pid,
               :root_pid,
               :assigns,
               :transport_pid
             ]}
  end

  defstruct id: nil,
            endpoint: nil,
            view: nil,
            parent_pid: nil,
            root_pid: nil,
            router: nil,
            assigns: %{__changed__: %{}},
            private: %{__changed__: %{}},
            fingerprints: Phoenix.LiveView.Diff.new_fingerprints(),
            redirected: nil,
            host_uri: nil,
            transport_pid: nil

  channel "lvu:*", Phoenix.LiveView.UploadChannel
  channel "lv:*", Phoenix.LiveView.Channel
  channel "room:*", GameniteWeb.RoomChannel

  @impl Phoenix.Socket

  def connect(%{"user_token" => token} = _params, %Phoenix.Socket{} = socket, connect_info) do
    with {:ok, user_id} <- GameniteWeb.Auth.verify_token(token) do
      {:ok,
       put_in(socket.private[:connect_info], connect_info)
       |> assign(:user_id, user_id)}
    else
      {:error, _reason} ->
        :error
    end
  end

  @impl Phoenix.Socket
  def id(socket), do: socket.private.connect_info[:session]["live_socket_id"]
end
