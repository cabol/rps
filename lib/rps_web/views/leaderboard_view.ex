defmodule RpsWeb.LeaderboardView do
  use RpsWeb, :view

  alias RpsWeb.LeaderboardView

  def render("show.json", %{leaderboard: leaderboard}) do
    %{data: render_one(leaderboard, LeaderboardView, "leaderboard.json")}
  end

  def render("leaderboard.json", %{leaderboard: leaderboard}) do
    for {score, users} <- leaderboard do
      %{score => users}
    end
  end
end
