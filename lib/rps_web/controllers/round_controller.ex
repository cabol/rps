defmodule RpsWeb.RoundController do
  use RpsWeb, :controller

  alias Rps.Games
  alias Rps.Games.Round

  action_fallback RpsWeb.FallbackController

  def index(conn, _params) do
    match_rounds = Games.list_match_rounds()
    render(conn, "index.json", match_rounds: match_rounds)
  end

  def create(conn, %{"round" => round_params}) do
    with {:ok, %Round{} = round} <- Games.create_round(round_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", round_path(conn, :show, round))
      |> render("show.json", round: round)
    end
  end

  def show(conn, %{"id" => id}) do
    round = Games.get_round!(id)
    render(conn, "show.json", round: round)
  end

  def update(conn, %{"id" => id, "round" => round_params}) do
    round = Games.get_round!(id)

    with {:ok, %Round{} = round} <- Games.update_round(round, round_params) do
      render(conn, "show.json", round: round)
    end
  end

  def delete(conn, %{"id" => id}) do
    round = Games.get_round!(id)

    with {:ok, %Round{}} <- Games.delete_round(round) do
      send_resp(conn, :no_content, "")
    end
  end
end
