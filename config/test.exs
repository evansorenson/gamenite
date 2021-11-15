use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :gamenite_persistance, GamenitePersistance.Repo,
  username: "postgres",
  password: "unitthird15",
  database: "gamenite_dev",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :gamenite_web, GameniteWeb.Endpoint,
  http: [port: 4002],
  server: false

config :gamenite,
  room_timeout: 900_000,
  game_timeout: 900_000,
  max_teams: 4,
  max_deck: 50,
  min_players: 2,
  team_colors: ["#C0392B", "#2980B9", "#27AE60", "#884EA0", "#D35400", "#FF33B8", "#F1C40F"],
  default_salad_bowl_rounds: ["Catchphrase", "Password", "Charades"],
  all_salad_bowl_rounds: ["Catchphrase", "Password", "Charades", "Pictionary"]

# Print only warnings and errors during test
config :logger, level: :warn

config :pbkdf2_elixir, :rounds, 1
