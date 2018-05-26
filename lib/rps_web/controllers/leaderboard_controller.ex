defmodule RpsWeb.LeaderboardController do
  use RpsWeb, :controller

  plug Guardian.Plug.EnsureAuthenticated, handler: __MODULE__

  alias Rps.Games.Leaderboard

  action_fallback RpsWeb.FallbackController

  def show(conn, _params) do
    leaderboard = Leaderboard.ranking()
    render(conn, "show.json", leaderboard: leaderboard)
  end
end
