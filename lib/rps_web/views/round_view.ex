defmodule RpsWeb.RoundView do
  use RpsWeb, :view
  alias RpsWeb.RoundView

  def render("index.json", %{match_rounds: match_rounds}) do
    %{data: render_many(match_rounds, RoundView, "round.json")}
  end

  def render("show.json", %{round: round}) do
    %{data: render_one(round, RoundView, "round.json")}
  end

  def render("round.json", %{round: %{move: move}}),
    do: %{move: move}
  def render("round.json", %{round: round}) do
    %{
      num: round.num,
      player1_move: round.player1_move,
      player2_move: round.player2_move,
      winner: round.winner
    }
  end
end
