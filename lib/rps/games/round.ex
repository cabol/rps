defmodule Rps.Games.Round do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rps.Games.Round

  schema "match_rounds" do
    field :player1_move, :string
    field :player2_move, :string
    field :winner, :string
    field :num, :integer
    belongs_to :match, Rps.Games.Match

    timestamps()
  end

  @type t :: %__MODULE__{
    player1_move: String.t,
    player2_move: String.t,
    winner: String.t,
    match_id: integer
  }

  @valid_moves ["rock", "paper", "scissors"]

  @doc false
  def changeset(round, attrs) do
    round
    |> cast(attrs, [:match_id, :player1_move, :player2_move, :winner, :num])
    |> validate_required([:match_id, :player1_move, :player2_move, :winner, :num])
    |> validate_inclusion(:player1_move, @valid_moves)
    |> validate_inclusion(:player2_move, @valid_moves)
  end

  @doc false
  def play(%{"move" => move}) when move in  @valid_moves,
    do: {:ok, move}
  def play(_) do
    changeset =
      %Round{}
      |> change(%{})
      |> add_error(:move, "empty or invalid")
    {:error, changeset}
  end
end
