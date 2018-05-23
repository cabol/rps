defmodule RpsWeb.RoundControllerTest do
  use RpsWeb.ConnCase

  import Rps.Fixtures

  alias Rps.Games.Match
  alias Rps.Games.Fsm

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    setup [:create_users, :create_match]

    test "lists all match_rounds", %{conn: conn, match: match} do
      conn =
        conn
        |> login("user1", "user1")
        |> get(round_path(conn, :index, match))
      assert json_response(conn, 200)["data"] == []

      :ok = Fsm.stop(match.id)
    end
  end

  describe "play round" do
    setup [:create_users, :create_match]

    test "renders round when data is valid", %{conn: conn, match: %Match{id: id} = match} do
      conn1 =
        conn
        |> login("user2", "user2")
        |> put(match_path(conn, :join, match), match: %{})
      assert %{"id" => ^id} = json_response(conn1, 200)["data"]

      conn2 =
        conn
        |> login("user1", "user1")
        |> put(round_path(conn, :play, match), round: %{move: "rock"})
      assert %{"move" => "rock"} == json_response(conn2, 200)["data"]

      :ok = Fsm.stop(match.id)
    end

    test "renders errors when play is invalid", %{conn: conn, match: %Match{id: id} = match} do
      conn1 =
        conn
        |> login("user2", "user2")
        |> put(match_path(conn, :join, match), match: %{})
      assert %{"id" => ^id} = json_response(conn1, 200)["data"]

      conn2 =
        conn
        |> login("user1", "user1")
        |> put(round_path(conn, :play, match), round: %{move: "invalid"})
      assert json_response(conn2, 422)["errors"] != %{}

      :ok = Fsm.stop(match.id)
    end
  end

  describe "play full game" do
    setup [:create_users, :create_match]

    test "full game", %{conn: conn, match: %Match{id: id} = match, user1: user1, user2: user2} do
      conn1 =
        conn
        |> login("user2", "user2")
        |> put(match_path(conn, :join, match), match: %{})
      assert %{"id" => ^id} = json_response(conn1, 200)["data"]

      assert "rock" == play(conn, match, "user1", "rock")
      assert "paper" == play(conn, match, "user2", "paper")

      assert "rock" == play(conn, match, "user1", "rock")
      assert "scissors" == play(conn, match, "user2", "scissors")

      assert "paper" == play(conn, match, "user1", "paper")
      assert "rock" == play(conn, match, "user2", "rock")

      conn2 =
        conn
        |> login("user1", "user1")
        |> get(match_path(conn, :show, id))

      assert json_response(conn2, 200)["data"] == %{
        "id" => id,
        "player1_wins" => 2,
        "player2_wins" => 1,
        "winner" => "player1",
        "player1_id" => user1.id,
        "player2_id" => user2.id,
        "status" => "finished",
        "match_rounds" => [
          %{
            "num" => 3,
            "player1_move" => "paper",
            "player2_move" => "rock",
            "winner" => "player1"
          },
          %{
            "num" => 2,
            "player1_move" => "rock",
            "player2_move" => "scissors",
            "winner" => "player1"
          },
          %{
            "num" => 1,
            "player1_move" => "rock",
            "player2_move" => "paper",
            "winner" => "player2"
          }
        ]
      }

      conn3 =
        conn
        |> login("user2", "user2")
        |> put(round_path(conn, :play, match), round: %{move: "paper"})
      assert %{"errors" => %{}} = json_response(conn3, 404)

      :ok = Fsm.stop(match.id)
    end
  end

  defp play(conn, match, user, move) do
    conn
    |> login(user, user)
    |> put(round_path(conn, :play, match), round: %{move: move})
    |> json_response(200)
    |> Map.fetch!("data")
    |> Map.fetch!("move")
  end
end
