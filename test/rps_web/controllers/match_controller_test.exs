defmodule RpsWeb.MatchControllerTest do
  use RpsWeb.ConnCase

  alias Rps.Repo
  alias Rps.Games.Match
  alias Rps.Accounts.User

  @create_attrs %{player1_id: nil, player2_id: nil, player1_wins: 42, player2_wins: 42, winner: "player1"}
  @update_attrs %{player1_wins: 43, player2_wins: 43, winner: "some updated winner"}
  @invalid_attrs %{player1_id: nil, player2_id: nil, player1_wins: nil, player2_wins: nil, winner: nil}

  def users_fixture() do
    user1 = Repo.insert!(%User{username: "cabol", password: "cabol"})
    user2 = Repo.insert!(%User{username: "cabol", password: "cabol"})
    {user1, user2}
  end

  def fixture(:match) do
    {user1, user2} = users_fixture()

    %Match{}
    |> Match.changeset(%{@create_attrs | player1_id: user1.id, player2_id: user2.id})
    |> Repo.insert!()
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all match_games", %{conn: conn} do
      conn = get conn, match_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create match" do
    test "renders match when data is valid", %{conn: conn} do
      {user1, user2} = users_fixture()
      conn = post conn, match_path(conn, :create), match: %{@create_attrs | player1_id: user1.id, player2_id: user2.id}
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, match_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "player1_wins" => 42,
        "player2_wins" => 42,
        "winner" => "player1"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, match_path(conn, :create), match: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update match" do
    setup [:create_match]

    test "renders match when data is valid", %{conn: conn, match: %Match{id: id} = match} do
      conn = put conn, match_path(conn, :update, match), match: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, match_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "player1_wins" => 43,
        "player2_wins" => 43,
        "winner" => "some updated winner"}
    end

    test "renders errors when data is invalid", %{conn: conn, match: match} do
      conn = put conn, match_path(conn, :update, match), match: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete match" do
    setup [:create_match]

    test "deletes chosen match", %{conn: conn, match: match} do
      conn = delete conn, match_path(conn, :delete, match)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, match_path(conn, :show, match)
      end
    end
  end

  defp create_match(_) do
    match = fixture(:match)
    {:ok, match: match}
  end
end
