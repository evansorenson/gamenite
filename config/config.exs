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

config :gamenite,
  game_timeout: 900_000,
  max_teams: 4,
  max_deck: 50,
  min_players: 2,
  team_colors: ["#C0392B", "#2980B9", "#27AE60", "#884EA0", "#D35400", "#FF33B8", "#F1C40F"],
  salad_bowl_default_rounds: ["Catchphrase", "Password", "Pictionary"],
  salad_bowl_all_rounds: ["Catchphrase", "Password", "Pictionary", "Charades"]

config :rooms,
  room_timeout: 900_000,
  roommate_colors: [
    "#e6194B",
    "#3cb44b",
    "#ffe119",
    "#4363d8",
    "#f58231",
    "#42d4f4",
    "#f032e6",
    "#fabed4",
    "#469990",
    "#dcbeff",
    "#9A6324",
    "#fffac8",
    "#800000",
    "#aaffc3",
    "#000075",
    "#a9a9a9"
  ]

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

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:room, :peer, :request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
