defmodule Rps.Accounts.Auth.Login do
  use Ecto.Schema
  import Ecto.Changeset

  schema "login" do
    field :username, :string
    field :password, :string

    timestamps()
  end

  @doc false
  def changeset(login, attrs) do
    login
    |> cast(attrs, [:username, :password])
    |> validate_required([:username, :password])
    |> validate_length(:username, max: 50)
    |> validate_length(:password, max: 50)
  end
end
