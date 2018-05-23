defmodule RpsWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import RpsWeb.Router.Helpers

      # The default endpoint for testing
      @endpoint RpsWeb.Endpoint

      def login(conn, username, password) do
        case get_token(username, password) do
          {:error, _} = error ->
            error
          %{"jwt" => jwt} ->
            put_req_header(conn, "authorization", "Bearer " <> jwt)
        end
      end

      def get_token(username, password) do
        conn = put_req_header(build_conn(), "accept", "application/json")
        req = %{user: %{username: username, password: password}}
        conn = post(conn, session_path(conn, :login), req)
        case conn.status do
          200 -> json_response(conn, 200)["data"]
          _   -> {:error, :unauthorized}
        end
      end
    end
  end


  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Rps.Repo)
    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Rps.Repo, {:shared, self()})
    end
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
