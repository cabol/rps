defmodule Rps.Games.FsmTest do
  use Rps.DataCase

  alias Rps.Repo
  alias Rps.Accounts.User
  alias Rps.Games.Match
  alias Rps.Games.Fsm
  alias Rps.Games.Fsm.Supervisor, as: FsmSupervisor

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
    match = Repo.insert! %Match{player1_id: user1.id, player2_id: user2.id}
    {:ok, _pid} = FsmSupervisor.start_child(match.id, match_rounds: 9, round_timeout: 10)
    refute match.winner

    assert {:error, :invalid_player} == Fsm.move match.id, 3, "paper"
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

    assert_raise KeyError, "key #{match.id} not found in: Rps.Cache", fn ->
      Fsm.move match.id, user1.id, "rock"
    end

    assert {:error, :normal} == FsmSupervisor.start_child(match.id)

    match = Rps.Games.get_match_with_rounds match.id
    assert "draw" == match.winner
    assert 3 == match.player1_wins
    assert 3 == match.player2_wins
    assert 9 == length(match.match_rounds)
  end

  test "default game with timeouts", %{user1: user1, user2: user2} do
    match = Repo.insert! %Match{player1_id: user1.id, player2_id: user2.id}
    {:ok, _pid} = FsmSupervisor.start_child(match.id, match_rounds: 5, round_timeout: 10)

    :ok = :timer.sleep(1000)

    match = Rps.Games.get_match_with_rounds match.id
    assert match.winner
    assert 5 == length(match.match_rounds)
  end

  test "game with some timeouts", %{user1: user1, user2: user2} do
    match = Repo.insert! %Match{player1_id: user1.id, player2_id: user2.id}
    {:ok, _pid} = FsmSupervisor.start_child(match.id, match_rounds: 5, round_timeout: 200)

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
    {:ok, _pid} = FsmSupervisor.start_child(match.id, match_rounds: 3, round_timeout: 1000)

    :ok = :timer.sleep(1100)
    %{match: _, rounds: _} = Fsm.info(match.id)

    assert :ok == Fsm.stop match.id
  end
end
