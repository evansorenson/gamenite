defmodule Gamenite.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false, default: fragment("gen_random_uuid()")
      add :username, :string, null: false
      add :email, :string
      add :password_hash, :string

      timestamps()
    end

    create unique_index(:users, [:username])
    create unique_index(:users, [:email])
  end
end
