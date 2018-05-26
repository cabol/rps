defmodule RpsWeb.UserSocket do
  use Phoenix.Socket

  alias Rps.Accounts

  ## Channels
  channel "room:*", RpsWeb.RoomChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket

  def connect(params, socket) do
    do_authorize(params, socket)
  end

  def id(_socket), do: nil

  defp do_authorize(params, socket) do
    case Accounts.authenticate_user(params) do
      {:ok, verified_user} ->
        {:ok, assign(socket, :user_id, verified_user.id)}
      {:error, _changeset} ->
        :error
    end
  end
end
