defmodule RpsWeb.RoomChannel do
  use RpsWeb, :channel

  alias Rps.Games.Fsm
  alias Rps.Games.Match

  def join("room:" <> game, _payload, socket) do
    if authorized?(game, socket.assigns.user_id) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Add authorization logic here as required.
  defp authorized?(game, user_id) do
    case Fsm.info(String.to_integer(game)) do
      %Match{player1_id: id1, player2_id: id2} when user_id in [id1, id2] ->
        true
      _ ->
        false
    end
  end
end
