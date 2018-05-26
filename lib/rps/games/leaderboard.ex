defmodule Rps.Games.Leaderboard do
  @moduledoc """
  The Leaderboard can be implemented in different ways, it depends on what
  problem we are trying to optimize. The common approach might bea single
  `ordered_set` table (sorted table) where the key is the score and the value
  is a lis of users with that score. The problem with this appoach is:

    1) Given the case, the value might be huge, a long list of users
    2) Every time we have to update a score for an user, we have to get
       the list of users (the value) for that score (the key), update
       that list (write operation) and then find the previous score for
       that user, get the value and remove the user from that list
       (another read and write operation).
    3) Additionally, because we are storing several users in the same key,
       at some point we can have high concurrency in a particular key and
       maybe inconsistency issues. To prevent this, we vave to disable
       read and write concurrency on that table, and additionally perform
       all previous mentioned operation in a transactional context
       (to avoid inconsistency issues); transactions might be implemented
       using `:global` module.

  Therefore, the approach implemented here tries to provide a good trade off,
  in this case we are using two tables, one `ordered_set` to store only the
  scores in a sorted way; the key and value is the same store. The other table
  is a `duplicated_bag` where the key is the score and the value is the user
  or player, since the key is the score, it can be duplicated multiple times,
  that's why we are using a `duplicated_bag`.  With this approach:

    1) Enable read and write concurrence, since every key is related to only
       one user, hence, there is not going to be multiple different users
       accessing the same key (like in the previous mentioned approach).
       Even in the  `ordered_set` we can also allow read and write concurrency,
       in this case it doesn't matter multiple users updating the same key,
       since the kay and value are the same for all of them.
    2) For the `duplicated_bag` table, either reads and writes are performed
       in constant complexity. In the previous approach since it is an
       `ordered_set`, all operations are performed in logaritmic complexity
       (it is implemented as AVL Tree).
    3) Perhaps the downside is we are using an extra ETS table, but again,
       it is matter of find the best trade off according to our needs.

  **Considerations and/or Assumptions**

  For the `update_player_score` function, there is one thing to consider
  and it is how to track the previous score (it doesn't matter the approach
  we take). We can assume the previous score is the given one minus one,
  since a game is managed by one FSM and the score is incremented by one.
  But, in order to be more flexible, we can have another table to track
  that value, it might be a `set` whwre the key is the username of the
  player and the value the current score, so every thime we update the
  score, we can update that counter and then retrieve the previous one,
  but we have to initialize the counter with the current player scores.
  So, for purposes of the exercice, the function is implemented in the
  simplest way (assuming the previous score as the given one minus one).

  This implementation doesn't works in distributed fashion, for purposes of
  the exercice it works only locally (single-node), this is a nice-to-have
  but it might be more challenging to implement using only ETS tables,
  specially `ordered_set` tables. So currently, the way to get that info
  (about the leaderboard /ranking) in distributed way is rely on the DB,
  since we have in the DB the score for every user, we can perform a query
  to get that info.
  """

  use GenServer

  @ets_opts [
    :public,
    :named_table,
    {:read_concurrency, true},
    {:write_concurrency, true}
  ]

  ## API

  @spec start_link() :: GenServer.on_start
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec update_player_score(String.t, integer) :: :ok | no_return()
  def update_player_score(username, score) do
    update_player_score(username, score, score - 1)
  end

  @spec update_player_score(String.t, integer, integer) :: :ok | no_return()
  def update_player_score(username, score, prev_score) do
    true = :ets.delete_object(:player_scores, {prev_score, username})
    true = :ets.insert(:player_scores, {score, username})
    true = :ets.insert(:scores, {score, score})
    :ok
  end

  @spec ranking() :: [{score :: integer, [username :: String.t]}]
  def ranking() do
    :ets.foldl(fn({score, _}, acc) ->
      players = for {_, p} <- :ets.lookup(:player_scores, score), do: p
      [{score, players} | acc]
    end, [], :scores)
  end

  @spec flush() :: :ok
  def flush do
    true = :ets.delete_all_objects(:scores)
    true = :ets.delete_all_objects(:player_scores)
    :ok
  end

  ## GenServer Callbacks

  @impl true
  def init(_arg) do
    :ok = create_tables()
    {:ok, %{}}
  end

  ## Private Functions

  defp create_tables() do
    :scores = :ets.new(:scores, [:ordered_set | @ets_opts])
    :player_scores = :ets.new(:player_scores, [:duplicate_bag | @ets_opts])
    :ok
  end
end
