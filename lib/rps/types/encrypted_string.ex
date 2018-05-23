defmodule Rps.EncryptedString do
  @behaviour Ecto.Type

  alias Comeonin.Bcrypt

  @doc """
  The Ecto type.
  """
  def type, do: :encrypted_string

  @doc """
  Casts to String.
  """
  def cast(value) do
    {:ok, to_string(value)}
  end

  @doc """
  Converts a string into a encrypted string.
  """
  def dump(value) do
    data =
      value
      |> to_string()
      |> Bcrypt.hashpwsalt()
    {:ok, data}
  end

  def load(value) do
    {:ok, value}
  end
end
