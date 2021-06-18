defmodule Gamenite.Repo.Migrations.CreateDecks do
  use Ecto.Migration

  def change do
    create table(:decks) do
      add :title, :string

      timestamps()
    end

  end
end
