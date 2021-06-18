defmodule GameniteWeb.Presence do
  use Phoenix.Presence,
  otp_app: :gamenite,
  pubsub_server: Gamenite.PubSub
end
