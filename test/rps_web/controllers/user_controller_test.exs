defmodule RpsWeb.UserControllerTest do
  use RpsWeb.ConnCase

  alias Rps.Accounts
  alias Rps.Accounts.User

  @create_attrs %{alias: "some alias", name: "some name", password: "test", username: "test"}
  @update_attrs %{alias: "some updated alias", name: "some updated name", username: "some updated username"}
  @invalid_attrs %{alias: nil, name: -1, username: nil}

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    setup [:create_user]

    test "lists all users", %{conn: conn} do
      conn =
        conn
        |> login("test", "test")
        |> get(user_path(conn, :index))
      assert length(json_response(conn, 200)["data"]) == 1
    end
  end

  describe "create user" do
    test "renders user when data is valid", %{conn: conn} do
      conn1 = post conn, user_path(conn, :create), user: @create_attrs
      assert %{"id" => id} = json_response(conn1, 201)["data"]

      conn2 =
        conn
        |> login("test", "test")
        |> get(user_path(conn, :show, id))

      assert json_response(conn2, 200)["data"] == %{
        "id" => id,
        "alias" => "some alias",
        "name" => "some name",
        "username" => "test",
        "wins" => 0}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, user_path(conn, :create), user: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update user" do
    setup [:create_user]

    test "renders user when data is valid", %{conn: conn, user: %User{id: id}} do
      conn1 =
        conn
        |> login("test", "test")
        |> put(user_path(conn, :update), user: @update_attrs)

      assert %{"id" => ^id} = json_response(conn1, 200)["data"]

      conn2 =
        conn
        |> login("test", "test")
        |> get(user_path(conn, :show, id))

      assert json_response(conn2, 200)["data"] == %{
        "id" => id,
        "alias" => "some updated alias",
        "name" => "some updated name",
        "username" => "test",
        "wins" => 0}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        conn
        |> login("test", "test")
        |> put(user_path(conn, :update), user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user" do
    setup [:create_user]

    test "deletes chosen user", %{conn: conn} do
      conn1 =
        conn
        |> login("test", "test")
        |> delete(user_path(conn, :delete))
      assert response(conn1, 204)
      assert {:error, :unauthorized} == get_token("test", "test")
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end
