defmodule Rps.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :password, :string
      add :name, :string
      add :alias, :string
      add :wins, :integer

      timestamps()
    end

    create unique_index(:users, [:username])
  end
end
