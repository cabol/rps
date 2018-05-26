defmodule RpsWeb.MatchControllerTest do
  use RpsWeb.ConnCase

  import Rps.Fixtures

  alias Rps.Games.Match
  alias Rps.Games.Fsm

  @create_attrs %{player1_id: nil, player2_id: nil, player1_wins: 0, player2_wins: 0, winner: nil}
  @update_attrs %{player1_wins: 43, player2_wins: 43, winner: nil}
  @invalid_attrs %{player1_id: nil, player2_id: nil, player1_wins: nil, player2_wins: nil, winner: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    setup [:create_users]

    test "lists all match_games", %{conn: conn} do
      conn =
        conn
        |> login("user1", "user1")
        |> get(match_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create match" do
    setup [:create_users]

    test "renders match when data is valid", %{conn: conn, user1: user1} do
      conn1 =
        conn
        |> login("user1", "user1")
        |> post(match_path(conn, :create), match: %{@create_attrs | player1_id: user1.id})

      assert %{"id" => id} = json_response(conn1, 201)["data"]

      conn2 =
        conn
        |> login("user1", "user1")
        |> get(match_path(conn, :show, id))

      assert json_response(conn2, 200)["data"] == %{
        "id" => id,
        "player1_wins" => 0,
        "player2_wins" => 0,
        "winner" => nil,
        "match_rounds" => [],
        "player1_id" => user1.id,
        "player2_id" => nil,
        "status" => "created"}
    end
  end

  describe "join to match" do
    setup [:create_users, :create_match]

    test "renders match when data is valid", %{conn: conn, match: %Match{id: id} = match, user1: user1, user2: user2} do
      conn1 =
        conn
        |> login("user2", "user2")
        |> put(match_path(conn, :join, match), match: @update_attrs)

      assert %{"id" => ^id} = json_response(conn1, 200)["data"]

      conn2 =
        conn
        |> login("user1", "user1")
        |> get(match_path(conn, :show, id))

      assert json_response(conn2, 200)["data"] == %{
        "id" => id,
        "player1_wins" => 0,
        "player2_wins" => 0,
        "winner" => nil,
        "match_rounds" => [],
        "player1_id" => user1.id,
        "player2_id" => user2.id,
        "status" => "started"}

      conn3 =
        conn
        |> login("user2", "user2")
        |> put(match_path(conn, :join, match), match: @update_attrs)

      assert json_response(conn3, 422)["errors"] != %{}

      :ok = Fsm.stop(match.id)
    end

    test "renders errors when data is invalid", %{conn: conn, match: match} do
      conn =
        conn
        |> login("user1", "user1")
        |> put(match_path(conn, :join, match), match: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}

      :ok = Fsm.stop(match.id)
    end

    test "renders errors when user is unauthorized", %{conn: conn, match: match} do
      conn = put(conn, match_path(conn, :join, match), match: @invalid_attrs)
      assert response(conn, 401) == "unauthenticated"
    end
  end

  describe "delete match" do
    setup [:create_users, :create_match]

    test "deletes chosen match", %{conn: conn, match: match} do
      conn1 =
        conn
        |> login("user1", "user1")
        |> delete(match_path(conn, :delete, match))

      assert response(conn1, 204)

      token = get_token("user1", "user1")
      assert_error_sent 404, fn ->
        conn
        |> put_req_header("authorization", "Bearer " <> token["jwt"])
        |> get(match_path(conn, :show, match))
      end
    end
  end
end
