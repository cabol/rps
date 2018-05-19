defmodule RpsWeb.RoundControllerTest do
  use RpsWeb.ConnCase

  alias Rps.Games
  alias Rps.Repo
  alias Rps.Games.Match
  alias Rps.Accounts.User
  alias Rps.Games.Round

  @create_attrs %{match_id: nil, player1_move: "rock", player2_move: "rock", winner: "draw"}
  @update_attrs %{player1_move: "paper", player2_move: "paper", winner: "draw"}
  @invalid_attrs %{match_id: nil, player1_move: nil, player2_move: nil, winner: nil}

  def users_fixture() do
    user1 = Repo.insert!(%User{username: "cabol", password: "cabol"})
    user2 = Repo.insert!(%User{username: "cabol", password: "cabol"})
    {user1, user2}
  end

  def match_fixture() do
    {user1, user2} = users_fixture()

    %Match{}
    |> Match.changeset(%{player1_id: user1.id, player2_id: user2.id})
    |> Repo.insert!()
  end

  def fixture(:round) do
    match = match_fixture()
    {:ok, round} = Games.create_round(%{@create_attrs | match_id: match.id})
    round
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all match_rounds", %{conn: conn} do
      conn = get conn, round_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create round" do
    test "renders round when data is valid", %{conn: conn} do
      match = match_fixture()
      conn = post conn, round_path(conn, :create), round: %{@create_attrs | match_id: match.id}
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, round_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "player1_move" => "rock",
        "player2_move" => "rock",
        "winner" => "draw"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, round_path(conn, :create), round: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update round" do
    setup [:create_round]

    test "renders round when data is valid", %{conn: conn, round: %Round{id: id} = round} do
      conn = put conn, round_path(conn, :update, round), round: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, round_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "player1_move" => "paper",
        "player2_move" => "paper",
        "winner" => "draw"}
    end

    test "renders errors when data is invalid", %{conn: conn, round: round} do
      conn = put conn, round_path(conn, :update, round), round: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete round" do
    setup [:create_round]

    test "deletes chosen round", %{conn: conn, round: round} do
      conn = delete conn, round_path(conn, :delete, round)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, round_path(conn, :show, round)
      end
    end
  end

  defp create_round(_) do
    round = fixture(:round)
    {:ok, round: round}
  end
end
