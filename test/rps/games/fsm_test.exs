defmodule Rps.Games.FsmTest do
  use Rps.DataCase

  alias Rps.Repo
  alias Rps.Accounts.User
  alias Rps.Games.Match
  alias Rps.Games.Fsm
  #alias Rps.Games.Fsm.Supervisor, as: FsmSupervisor

  setup do
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
    {:ok, user1: user1, user2: user2}
  end

  test "new game", %{user1: user1, user2: user2} do
    # start errors
    {:error, :match_not_found} = Fsm.start_link(-1)
    match = Repo.insert! %Match{}
    {:error, :missing_player1} = Fsm.start_link(match.id)

    # start game
    match = Repo.insert! %Match{player1_id: user1.id, player2_id: user2.id}
    {:ok, _pid} = Fsm.start_link(match.id, match_rounds: 9, round_timeout: 10)
    refute match.winner

    # errors while playing
    assert {:error, {:invalid_player, -1}} == Fsm.move match.id, -1, "paper"
    assert {:error, {:invalid_move, "other"}} == Fsm.move match.id, user1.id, "other"

    # test all combinations
    assert {:ok, "rock"} == Fsm.move match.id, user1.id, "rock"
    assert {:ok, "rock"} == Fsm.move match.id, user1.id, "scissors"
    assert {:ok, "paper"} == Fsm.move match.id, user2.id, "paper"
    assert {:ok, "paper"} == Fsm.move match.id, user1.id, "paper"
    assert {:ok, "rock"} == Fsm.move match.id, user2.id, "rock"
    assert {:ok, "rock"} == Fsm.move match.id, user1.id, "rock"
    assert {:ok, "scissors"} == Fsm.move match.id, user2.id, "scissors"
    assert {:ok, "scissors"} == Fsm.move match.id, user1.id, "scissors"
    assert {:ok, "rock"} == Fsm.move match.id, user2.id, "rock"
    assert {:ok, "paper"} == Fsm.move match.id, user1.id, "paper"
    assert {:ok, "scissors"} == Fsm.move match.id, user2.id, "scissors"
    assert {:ok, "scissors"} == Fsm.move match.id, user1.id, "scissors"
    assert {:ok, "paper"} == Fsm.move match.id, user2.id, "paper"
    assert {:ok, "rock"} == Fsm.move match.id, user1.id, "rock"
    assert {:ok, "rock"} == Fsm.move match.id, user2.id, "rock"
    assert {:ok, "paper"} == Fsm.move match.id, user1.id, "paper"
    assert {:ok, "paper"} == Fsm.move match.id, user2.id, "paper"
    assert {:ok, "scissors"} == Fsm.move match.id, user1.id, "scissors"
    assert {:ok, "scissors"} == Fsm.move match.id, user2.id, "scissors"

    # game should have finished
    assert {:error, :invalid_match} = Fsm.move match.id, user1.id, "rock"

    # error resuming a finished game
    assert {:error, :game_over} == Fsm.start_link(match.id)

    # check results
    match = Rps.Games.get_match_with_rounds match.id
    assert "draw" == match.winner
    assert 3 == match.player1_wins
    assert 3 == match.player2_wins
    assert 9 == length(match.match_rounds)
  end

  test "default game with timeouts", %{user1: user1, user2: user2} do
    match = Repo.insert! %Match{player1_id: user1.id, player2_id: user2.id}

    {:ok, _pid} = Fsm.start_link(match.id, match_rounds: 5, round_timeout: 10)

    :ok = :timer.sleep(1000)

    match = Rps.Games.get_match_with_rounds match.id
    assert match.winner
    assert 5 == length(match.match_rounds)
  end

  test "game with some timeouts", %{user1: user1, user2: user2} do
    match = Repo.insert! %Match{player1_id: user1.id, player2_id: user2.id}

    {:ok, _pid} = Fsm.start_link(match.id, match_rounds: 5, round_timeout: 200)

    assert {:ok, "paper"} == Fsm.move match.id, user1.id, "paper"
    assert {:ok, "scissors"} == Fsm.move match.id, user2.id, "scissors"

    :ok = :timer.sleep(150)
    assert {:ok, "paper"} == Fsm.move match.id, user1.id, "paper"

    :ok = :timer.sleep(150)
    assert {:ok, "scissors"} == Fsm.move match.id, user2.id, "scissors"

    :ok = :timer.sleep(1100)

    match = Rps.Games.get_match_with_rounds match.id
    assert match.winner
    assert 5 == length(match.match_rounds)
  end

  test "match info during the game", %{user1: user1, user2: user2} do
    match = Repo.insert! %Match{player1_id: user1.id, player2_id: user2.id}

    {:ok, _pid} = Fsm.start_link(match.id, match_rounds: 4, round_timeout: 500)
    assert match = Fsm.info(match.id)
    assert user1.id == match.player1_id
    assert user2.id == match.player2_id

    :ok = :timer.sleep(1100)
    assert match = Fsm.info(match.id)
    assert 2 == length(match.match_rounds)

    assert :ok == Fsm.stop match.id
  end
end
