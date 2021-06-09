defmodule Gamenite.Repo do
  use Ecto.Repo,
    otp_app: :gamenite,
    adapter: Ecto.Adapters.Postgres
end
