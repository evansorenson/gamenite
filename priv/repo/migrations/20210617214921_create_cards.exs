defmodule Gamenite.Repo.Migrations.CreateCards do
  use Ecto.Migration

  def change do
    create table(:cards) do
      add :front, :string
      add :deck_id, references(:decks, on_delete: :nothing)

      timestamps()
    end

    create index(:cards, [:deck_id])
  end
end
