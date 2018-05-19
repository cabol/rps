defmodule Rps.Games.Fsm do
  @moduledoc """
  This module uses `gen_statem` behaviour to implement a match game session,
  this state machine manage the game logic between two opponents.

  The FSM works in distributed fashion, when a new game session is created,
  the local `pid` and `node` are cached and associated to the `match_id`,
  which acts as key. The distribued cache acts as registry (or name server)
  in order to locate the resources (games) in distributed way.

  In the case the game is located in the same node where the FSM is being
  called, the function is invoked locally, no RPC calls are involved.
  On other hand, if the node is not the local, then the FSM function
  is invoked using `:rpc` module.

  NOTE: For the cache, `Nebulex` library is being used.
  """

  @behaviour :gen_statem

  alias Rps.Cache
  alias Rps.Repo
  alias Rps.Games
  alias Rps.Games.Match
  alias Rps.Games.Round
  alias Ecto.Changeset

  ## Valid game options
  @valid_moves ["rock", "paper", "scissors"]

  defmodule Data do
    defstruct [:match, tref: nil, round: [], rounds: [], opts: []]
  end

  ## API

  @spec start_link(integer, Keyword.t) :: {:ok, pid} | :ignore | {:error, any}
  def start_link(match_id, opts \\ []) do
    case :gen_statem.start(__MODULE__, {match_id, opts}, []) do
      {:ok, pid} ->
        {_, ^pid} = Cache.set(match_id, {node(), pid})
        {:ok, pid}
      other ->
        other
    end
  end

  @spec move(integer, integer, String.t) :: {:ok, String.t} | {:error, any} | no_return
  def move(match_id, player, move) when move in @valid_moves do
    call(:move, [match_id, player, move])
  end
  def move(_, _, move) do
    {:error, {:invalid_move, move}}
  end

  @spec info(integer) :: [Round.t] | no_return
  def info(match_id) do
    call(:info, [match_id])
  end

  @spec stop(integer) :: :ok | no_return
  def stop(match_id) do
    match_id
    |> get_pid()
    |> :gen_statem.stop()
  end

  @spec get_pid(integer) :: pid | no_return
  def get_pid(match_id) do
    match_id
    |> Cache.get!()
    |> elem(1)
  end

  ## Mandatory callback functions

  @doc false
  def init({match_id, opts}) do
    _ = Process.flag(:trap_exit, true)
    match = Games.get_match_with_rounds(match_id)
    data = %Data{match: match, rounds: match.match_rounds, opts: opts}

    if match && length(match.match_rounds) < Keyword.get(opts, :match_rounds, 10) do
      {:ok, :play, %{data | tref: set_timer(data)}}
    else
      # the match was played already, so stop the fsm
      {:stop, :normal}
    end
  end

  @doc false
  def terminate(_reason, _state, %Data{match: %Match{id: match_id}}) do
    Cache.delete(match_id)
  end

  @doc false
  def callback_mode, do: :state_functions

  ## State callback(s)

  @doc false
  def play({:call, from}, {:move, player, move}, %Data{match: %Match{player1_id: p1, player2_id: p2}} = data) do
    if player in [p1, p2] do
      do_play(from, player, move, data)
    else
      {:next_state, :play, data, [{:reply, from, {:error, :invalid_player}}]}
    end
  end
  def play({:call, from}, :timeout, %Data{round: round} = data) do
    case round do
      [{:player1_move, _}] ->
        do_play(from, data.match.player2_id, Enum.random(@valid_moves), data)
      [{:player2_move, _}] ->
        do_play(from, data.match.player1_id, Enum.random(@valid_moves), data)
      [] ->
        data = %{data | round: [player1_move: Enum.random(@valid_moves)]}
        do_play(from, data.match.player2_id, Enum.random(@valid_moves), data)
    end
  end
  def play(event_type, event_content, data) do
    handle_event(event_type, event_content, data)
  end

  defp do_play(from, player, move, %Data{round: round, rounds: rounds, match: match, opts: opts} = data) do
    player_key = player_key(player, match)

    case round do
      [] ->
        data = %{data | round: [{player_key, move}]}
        {:next_state, :play, data, [{:reply, from, {:ok, move}}]}
      [{^player_key, prev_move}] ->
        {:next_state, :play, data, [{:reply, from, {:ok, prev_move}}]}
      [prev_move] ->
        tref = set_timer(data)
        {new_round, match} = new_round(match, [prev_move, {player_key, move}])
        data = %{data | round: [], rounds: [new_round | rounds], match: match, tref: tref}

        if length(data.rounds) >= Keyword.get(opts, :match_rounds, 10) do
          # game over, stop the fsm
          {:stop_and_reply, :normal, [{:reply, from, {:ok, move}}]}
        else
          {:next_state, :play, data, [{:reply, from, {:ok, move}}]}
        end
    end
  end

  ## Handle events common to all states

  @doc false
  def handle_event({:call, from}, :info, %Data{match: match, rounds: rounds} = data) do
    {:keep_state, data, [{:reply, from, %{match: match, rounds: rounds}}]}
  end
  def handle_event(_, _, data) do
    {:keep_state, data}
  end

  ## Private Functions

  defp player_key(player, %Match{player1_id: player}), do: :player1_move
  defp player_key(player, %Match{player2_id: player}), do: :player2_move

  defp new_round(%Match{id: match_id} = match, moves) do
    moves
    |> Enum.reduce(%Round{match_id: match_id}, fn({player_move, move}, acc) ->
      %{acc | player_move => move}
    end)
    |> pick_winner()
    |> Repo.insert!()
    |> update_match_results(match)
  end

  defp pick_winner(%Round{player1_move: "rock", player2_move: "paper"} = round),
    do: Round.changeset(round, %{winner: "player2"})
  defp pick_winner(%Round{player1_move: "paper", player2_move: "rock"} = round),
    do: Round.changeset(round, %{winner: "player1"})
  defp pick_winner(%Round{player1_move: "rock", player2_move: "scissors"} = round),
    do: Round.changeset(round, %{winner: "player1"})
  defp pick_winner(%Round{player1_move: "scissors", player2_move: "rock"} = round),
    do: Round.changeset(round, %{winner: "player2"})
  defp pick_winner(%Round{player1_move: "paper", player2_move: "scissors"} = round),
    do: Round.changeset(round, %{winner: "player2"})
  defp pick_winner(%Round{player1_move: "scissors", player2_move: "paper"} = round),
    do: Round.changeset(round, %{winner: "player1"})
  defp pick_winner(%Round{player1_move: same, player2_move: same} = round),
    do: Round.changeset(round, %{winner: "draw"})

  defp update_match_results(%Round{winner: "draw"} = round, match),
    do: {round, match}
  defp update_match_results(%Round{winner: winner} = round, match) do
    # perhaps the update of the match can be done at the end of the game,
    # in this case for the exercise, it is being updated every time
    # a round is completed
    key = String.to_atom("#{winner}_wins")
    match = update_match(match, %{key => Map.get(match, key, 0) + 1})
    {round, match}
  end

  defp update_match(match, attrs) do
    Match
    |> Repo.get!(match.id)
    |> Match.changeset(attrs)
    |> update_match_winner()
    |> Repo.update!()
  end

  defp update_match_winner(changeset) do
    player1_wins = Changeset.get_field(changeset, :player1_wins)
    player2_wins = Changeset.get_field(changeset, :player2_wins)

    cond do
      player1_wins > player2_wins ->
        Changeset.change(changeset, %{winner: "player1"})
      player2_wins > player1_wins ->
        Changeset.change(changeset, %{winner: "player2"})
      true ->
        Changeset.change(changeset, %{winner: "draw"})
    end
  end

  defp set_timer(%Data{tref: tref, opts: opts}) do
    _ = :timer.cancel(tref)
    {:ok, tref} =
      opts
      |> Keyword.get(:round_timeout, 10000)
      |> :timer.apply_after(:gen_statem, :call, [self(), :timeout])
    tref
  end

  defp call(fun, [match_id | args]) do
    match_id
    |> Cache.get!()
    |> do_call(fun, args)
  end

  defp do_call({node, pid}, fun, args) when node == node() do
    case args do
      [_ | _] ->
        apply(:gen_statem, :call, [pid, List.to_tuple([fun | args])])
      [] ->
        apply(:gen_statem, :call, [pid, fun])
    end
  end
  defp do_call({node, _pid}, fun, args) do
    :rpc.call(node, __MODULE__, fun, args)
  end
end
