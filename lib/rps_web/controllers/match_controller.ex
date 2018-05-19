defmodule RpsWeb.MatchController do
  use RpsWeb, :controller

  alias Rps.Games
  alias Rps.Games.Match

  action_fallback RpsWeb.FallbackController

  def index(conn, _params) do
    match_games = Games.list_match_games()
    render(conn, "index.json", match_games: match_games)
  end

  def create(conn, %{"match" => match_params}) do
    with {:ok, %Match{} = match} <- Games.create_match(match_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", match_path(conn, :show, match))
      |> render("show.json", match: match)
    end
  end

  def show(conn, %{"id" => id}) do
    match = Games.get_match!(id)
    render(conn, "show.json", match: match)
  end

  def update(conn, %{"id" => id, "match" => match_params}) do
    match = Games.get_match!(id)

    with {:ok, %Match{} = match} <- Games.update_match(match, match_params) do
      render(conn, "show.json", match: match)
    end
  end

  def delete(conn, %{"id" => id}) do
    match = Games.get_match!(id)
    
    with {:ok, %Match{}} <- Games.delete_match(match) do
      send_resp(conn, :no_content, "")
    end
  end
end
