defmodule Rps.Games.Match do
  use Ecto.Schema
  import Ecto.Changeset

  schema "match_games" do
    field :player1_wins, :integer, default: 0
    field :player2_wins, :integer, default: 0
    field :winner, :string
    belongs_to :player1, Rps.Accounts.User
    belongs_to :player2, Rps.Accounts.User
    has_many :match_rounds, Rps.Games.Round

    timestamps()
  end

  @type t :: %__MODULE__{
    player1_wins: integer,
    player2_wins: integer,
    winner: String.t,
    player1_id: integer,
    player2_id: integer
  }

  @doc false
  def changeset(match, attrs) do
    match
    |> cast(attrs, [:player1_id, :player2_id, :player1_wins, :player2_wins, :winner])
    |> validate_required([:player1_id, :player2_id])
  end
end
