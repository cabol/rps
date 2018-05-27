defmodule Rps.Games.LeaderboardTest do
  use ExUnit.Case, async: true

  alias Rps.Games.Leaderboard

  test "ranking" do
    :ok = Leaderboard.flush()
    _ = Leaderboard.start_link()

    assert [] == Leaderboard.ranking()

    for {user, score} <- [{"a", 3}, {"b", 5}, {"c", 10}, {"d", 5}, {"e", 10}] do
      assert :ok == Leaderboard.update_player_score user, score
    end

    assert [
      {10, ["c", "e"]},
      {5, ["b", "d"]},
      {3, ["a"]}
    ] == Leaderboard.ranking()

    assert :ok == Leaderboard.update_player_score "a", 11, 3
    for {user, score} <- [{"f", 3}, {"g", 5}, {"b", 6}] do
      assert :ok == Leaderboard.update_player_score user, score
    end

    assert [
      {11, ["a"]},
      {10, ["c", "e"]},
      {6, ["b"]},
      {5, ["d", "g"]},
      {3, ["f"]}
    ] == Leaderboard.ranking()
  end
end
