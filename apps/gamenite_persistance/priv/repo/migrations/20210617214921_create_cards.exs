defmodule Gamenite.Repo.Migrations.CreateCards do
  use Ecto.Migration

  def change do
    create table(:cards) do
      add :face, :string
      add :back, :string
      add :face_image, :string
      add :back_image, :string
      add :deck_id, references(:decks, on_delete: :nothing)

      timestamps()
    end

    create index(:cards, [:deck_id])
  end
end
