defmodule RpsWeb.MatchView do
  use RpsWeb, :view
  alias RpsWeb.MatchView

  def render("index.json", %{match_games: match_games}) do
    %{data: render_many(match_games, MatchView, "match.json")}
  end

  def render("show.json", %{match: match}) do
    %{data: render_one(match, MatchView, "match.json")}
  end

  def render("match.json", %{match: match}) do
    %{id: match.id,
      player1_wins: match.player1_wins,
      player2_wins: match.player2_wins,
      winner: match.winner}
  end
end
