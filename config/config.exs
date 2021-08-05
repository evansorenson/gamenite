# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
use Mix.Config

# Configure Mix tasks and generators
config :gamenite,
  ecto_repos: [Gamenite.Repo]

config :gamenite_web,
  ecto_repos: [Gamenite.Repo],
  generators: [context_app: :gamenite]

# Configures the endpoint
config :gamenite_web, GameniteWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "vFT8eI8mCdkGpDxyOYEbX9SuSnpErddv6arV79NL6QUbonYft/otBfYzm5p9D1dJ",
  render_errors: [view: GameniteWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Gamenite.PubSub,
  live_view: [signing_salt: "Ku8IXljo"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
