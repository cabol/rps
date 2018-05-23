defmodule RpsWeb.RoundController do
  use RpsWeb, :controller

  plug Guardian.Plug.EnsureAuthenticated, handler: __MODULE__

  alias Rps.Games
  alias Rps.Games.Round
  alias Rps.Games.Fsm

  action_fallback RpsWeb.FallbackController

  def index(conn, _params) do
    match_rounds = Games.list_match_rounds()
    render(conn, "index.json", match_rounds: match_rounds)
  end

  def play(conn, %{"match_id" => match_id, "round" => round_params}) do
    logged_user = Guardian.Plug.current_resource(conn)
    match_id = String.to_integer(match_id)

    with {:ok, move} <- Round.play(round_params),
         {:ok, move} <- Fsm.move(match_id, logged_user.id, move) do
      render(conn, "show.json", round: %{move: move})
    end
  end
end
