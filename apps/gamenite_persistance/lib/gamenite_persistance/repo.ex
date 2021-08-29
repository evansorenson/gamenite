defmodule GamenitePersistance.Repo do
  use Ecto.Repo,
    otp_app: :gamenite_persistance,
    adapter: Ecto.Adapters.Postgres
end
