defmodule Rps.Repo.Migrations.CreateMatchGames do
  use Ecto.Migration

  def change do
    create table(:match_games) do
      add :player1_wins, :integer
      add :player2_wins, :integer
      add :winner, :string
      add :player1_id, references(:users, on_delete: :nothing)
      add :player2_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:match_games, [:player1_id])
    create index(:match_games, [:player2_id])
  end
end
