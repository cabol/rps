defmodule RpsWeb.RoomChannelTest do
  use RpsWeb.ChannelCase

  alias RpsWeb.UserSocket
  alias RpsWeb.RoomChannel
  alias Rps.Repo
  alias Rps.Games.Fsm
  alias Rps.Accounts.User
  alias Rps.Games.Match

  setup do
    match = setup_game()

    # auth errors
    :error = connect(UserSocket, %{some: :assign})
    :error = connect(UserSocket, %{username: "user1", password: "wrong"})

    # connect
    {:ok, socket} = connect(UserSocket, %{username: "user1", password: "user1"})

    # start the game
    {:ok, _pid} = Fsm.start_link(match.id, match_rounds: 3, round_timeout: 500)

    # subscribe to notifications
    {:error, %{reason: "unauthorized"}} = subscribe_and_join(socket, RoomChannel, "room:-1")
    {:ok, _, socket} = subscribe_and_join(socket, RoomChannel, "room:#{match.id}")

    {:ok, socket: socket, match: match}
  end

  test "broadcasts about game are pushed to the client", %{socket: _socket, match: %Match{id: id}} do
    for round <- 1..3 do
      :timer.sleep(800)
      assert_broadcast "round_finished", %{match_id: ^id, num: ^round}
    end
    :timer.sleep(800)
    assert_broadcast "match_finished", %{id: ^id}
    :timer.sleep(800)
  end

  defp setup_game do
    users = [
      %User{
        username: "user1",
        password: "user1"
      },
      %User{
        username: "user2",
        password: "user2"
      }
    ]
    [user1, user2] = for user <- users, do: Repo.insert!(user)
    Repo.insert! %Match{player1_id: user1.id, player2_id: user2.id}
  end
end
