defmodule Rps.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :password, Rps.EncryptedString
    field :alias, :string
    field :name, :string
    field :wins, :integer, default: 0

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password, :name, :alias, :wins])
    |> validate_required([:username, :password])
    |> unique_constraint(:username)
  end
end
