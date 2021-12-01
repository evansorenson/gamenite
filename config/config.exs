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

config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets),
    cd: Path.expand("../apps/gamenite_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure Mix tasks and generators
config :gamenite_persistance,
  ecto_repos: [GamenitePersistance.Repo]

config :gamenite_web,
  ecto_repos: [GamenitePersistance.Repo],
  generators: [context_app: :gamenite_persistance]

# Configures the endpoint
config :gamenite_web, GameniteWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "vFT8eI8mCdkGpDxyOYEbX9SuSnpErddv6arV79NL6QUbonYft/otBfYzm5p9D1dJ",
  render_errors: [view: GameniteWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: GamenitePersistance.PubSub,
  live_view: [signing_salt: "Ku8IXljo"]

config :surface, :components, [
  {Surface.Components.Form.ErrorTag,
   default_translator: {GameniteWeb.ErrorHelpers, :translate_error},
   default_class: "invalid-feedback"}
]

config :logger,
  compile_time_purge_matching: [
    [level_lower_than: :info],
    # Silence irrelevant warnings caused by resending handshake events
    [module: Membrane.SRTP.Encryptor, function: "handle_event/4", level_lower_than: :error],
    [module: MDNS.Client, level_lower_than: :error]
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:room, :peer, :request_id]

config :ex_libnice, impl: NIF

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
