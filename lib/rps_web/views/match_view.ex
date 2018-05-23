defmodule RpsWeb.MatchView do
  use RpsWeb, :view

  alias RpsWeb.MatchView
  alias RpsWeb.RoundView

  def render("index.json", %{match_games: match_games}) do
    %{data: render_many(match_games, MatchView, "match.json")}
  end

  def render("show.json", %{match: match}) do
    %{data: render_one(match, MatchView, "match.json")}
  end

  def render("match.json", %{match: match}) do
    %{
      id: match.id,
      player1_id: match.player1_id,
      player2_id: match.player2_id,
      player1_wins: match.player1_wins,
      player2_wins: match.player2_wins,
      winner: match.winner,
      status: match.status,
      match_rounds: get_match_rounds(match.match_rounds)
    }
  end

  defp get_match_rounds(match_rounds) when is_list(match_rounds),
    do: render_many(match_rounds, RoundView, "round.json")
  defp get_match_rounds(_match_rounds),
    do: []
end
