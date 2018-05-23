defmodule Rps.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias Rps.Repo
  alias Rps.Accounts.User
  alias Rps.Accounts.Auth.Login
  alias Ecto.Changeset
  alias Comeonin.Bcrypt

  @doc false
  def list_users do
    Repo.all(User)
  end

  @doc false
  def get_user!(id), do: Repo.get!(User, id)

  @doc false
  def get_user(id), do: Repo.get(User, id)

  @doc false
  def get_user_by(clauses), do: Repo.get_by(User, clauses)

  @doc false
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc false
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc false
  def update_user!(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update!()
  end

  @doc false
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc false
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  @doc false
  def authenticate_user(%{"username" => username, "password" => password} = params) do
    case get_user_by(username: username) do
      nil ->
        changeset =
          %Login{}
          |> Login.changeset(params)
          |> Changeset.add_error(:username, "notfound")
        {:error, changeset}
      user ->
        if Bcrypt.checkpw(password, user.password) do
          {:ok, user}
        else
          changeset =
            %Login{}
            |> Login.changeset(params)
            |> Changeset.add_error(:password, "invalid")
          {:error, changeset}
        end
    end
  end
end
