defmodule RpsWeb.MatchController do
  use RpsWeb, :controller

  plug Guardian.Plug.EnsureAuthenticated, handler: __MODULE__

  alias Rps.Games
  alias Rps.Games.Match
  alias Rps.Accounts.Auth.Guardian
  alias Rps.Games.Fsm.Supervisor, as: GameFsm

  action_fallback RpsWeb.FallbackController

  def create(conn, _params) do
    logged_user = Guardian.Plug.current_resource(conn)
    match_params = %{"player1_id" => logged_user.id}

    with {:ok, %Match{} = match} <- Games.create_match(match_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", match_path(conn, :show, match))
      |> render("show.json", match: match)
    end
  end

  def join(conn, %{"id" => id}) do
    match = %{Games.get_match!(id) | status: "started"}
    logged_user = Guardian.Plug.current_resource(conn)
    match_params = %{player2_id: logged_user.id}

    with {:ok, %Match{} = match} <- Games.update_match(match, match_params),
         {:ok, _pid} <- GameFsm.start_child(match.id) do
      render(conn, "show.json", match: match)
    end
  end

  def index(conn, _params) do
    match_games = Games.list_match_games()
    render(conn, "index.json", match_games: match_games)
  end

  def show(conn, %{"id" => id}) do
    match = Games.get_match_with_rounds!(id)
    render(conn, "show.json", match: match)
  end

  def delete(conn, %{"id" => id}) do
    match = Games.get_match!(id)

    with {:ok, %Match{}} <- Games.delete_match(match) do
      send_resp(conn, :no_content, "")
    end
  end
end
