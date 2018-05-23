defmodule Rps.Repo.Migrations.CreateMatchRounds do
  use Ecto.Migration

  def change do
    create table(:match_rounds) do
      add :player1_move, :string
      add :player2_move, :string
      add :winner, :string
      add :num, :integer
      add :match_id, references(:match_games, on_delete: :delete_all)

      timestamps()
    end

    create index(:match_rounds, [:match_id])
  end
end
