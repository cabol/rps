defmodule RpsWeb.UserController do
  use RpsWeb, :controller

  plug Guardian.Plug.EnsureAuthenticated, [handler: __MODULE__] when action not in [:create]

  alias Rps.Accounts
  alias Rps.Accounts.User
  alias Rps.Accounts.Auth.Guardian

  action_fallback RpsWeb.FallbackController

  # @TODO: Implement a good signup process, maybe based on the email;
  # send a confirmation email and then using other action create an
  # activate that user. Or maybe allow this operation only to admin
  # users.
  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(Map.drop(user_params, ["wins"])) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", user_path(conn, :show, user))
      |> render("show.json", user: user)
    end
  end

  def update(conn, %{"user" => user_params}) do
    logged_user = Guardian.Plug.current_resource(conn)
    user = Accounts.get_user!(logged_user.id)
    user_params = Map.drop(user_params, ["username", "wins"])

    with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.json", users: users)
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.json", user: user)
  end

  # @TODO: maybe this function is not necessary, for now allow to delete
  # only the logged-in user
  def delete(conn, _params) do
    logged_user = Guardian.Plug.current_resource(conn)

    with {:ok, %User{}} <- Accounts.delete_user(logged_user) do
      send_resp(conn, :no_content, "")
    end
  end
end
