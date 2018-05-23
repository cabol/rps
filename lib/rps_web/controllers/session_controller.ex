defmodule RpsWeb.SessionController do
  use RpsWeb, :controller

  plug Guardian.Plug.EnsureAuthenticated, [handler: __MODULE__] when action in [:logout]

  alias Rps.Accounts
  alias Rps.Accounts.Auth.Guardian

  def login(conn, %{"user" => user_params}) do
    case Accounts.authenticate_user(user_params) do
      {:ok, user} ->
        conn = Guardian.Plug.sign_in(conn, user)
        jwt = Guardian.Plug.current_token(conn)
        claims = Guardian.Plug.current_claims(conn)
        exp = Map.get(claims, "exp")

        conn
        |> put_resp_header("authorization", "Bearer #{jwt}")
        |> put_resp_header("x-expires", "Bearer #{exp}")
        |> render("login.json", session: %{jwt: jwt, exp: exp})
      {:error, changeset} ->
        conn
        |> put_status(401)
        |> render(RpsWeb.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def logout(conn, _) do
    # @TODO: maybe implement in the right way the logout larer!
    jwt = Guardian.Plug.current_token(conn)
    _ = Guardian.revoke(jwt)
    render(conn, "logout.json", session: %{jwt: :revoked, exp: 0})
  end
end
