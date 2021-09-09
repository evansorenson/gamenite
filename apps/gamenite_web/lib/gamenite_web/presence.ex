defmodule GameniteWeb.Presence do
  use Phoenix.Presence,
  otp_app: :gamenite_web,
  pubsub_server: GamenitePersistance.PubSub

  def fetch(_topic, entries) do
    users =
      entries
      |> Map.keys()
      |> GamenitePersistance.Accounts.list_users_by_ids()
      |> Enum.into(%{}, fn user ->
        {to_string(user.id), %{username: user.username}}
      end)

    for {key, %{metas: metas}} <- entries, into: %{} do
      {key, %{metas: metas, user: users[key]}}
    end
  end
end
