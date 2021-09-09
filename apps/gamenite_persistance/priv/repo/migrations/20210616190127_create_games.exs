defmodule GamenitePersistance.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :title, :string
      add :description, :text
      add :play_count, :integer

      timestamps()
    end

  end
end
