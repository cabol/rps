defmodule Rps.Fixtures do
  @moduledoc false

  alias Rps.Repo
  alias Rps.Games.Match
  alias Rps.Accounts.User

  @create_attrs %{player1_id: nil, player2_id: nil, player1_wins: 0, player2_wins: 0, winner: nil}

  def fixture(:users) do
    user1 = Repo.insert!(%User{username: "user1", password: "user1"})
    user2 = Repo.insert!(%User{username: "user2", password: "user2"})
    {user1, user2}
  end

  def fixture({:match, user1, _user2}) do
    %Match{}
    |> Match.changeset(%{@create_attrs | player1_id: user1.id})
    |> Repo.insert!()
  end

  def create_match(%{user1: user1, user2: user2}) do
    match = fixture({:match, user1, user2})
    {:ok, match: match}
  end

  def create_users(_) do
    {user1, user2} = fixture(:users)
    {:ok, user1: user1, user2: user2}
  end
end
