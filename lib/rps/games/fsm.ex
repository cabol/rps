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
  #alias Rps.Accounts.User
  alias Ecto.Changeset

  ## FSM default config
  @config Application.get_env(:rps, __MODULE__, [])

  ## Valid game options
  @valid_moves ["rock", "paper", "scissors"]

  defmodule Data do
    defstruct [:match, tref: nil, opts: [], round: [], rounds: [], players: []]
  end

  ## API

  @spec start_link(integer, Keyword.t) :: {:ok, pid} | {:error, any}
  def start_link(match_id, opts \\ []) do
    match_id
    |> Games.get_match_with_rounds()
    |> do_start_link(Keyword.merge(@config, opts))
  end

  defp do_start_link(nil, _opts),
    do: {:error, :match_not_found}
  defp do_start_link(%Match{player1_id: nil}, _opts),
    do: {:error, :missing_player1}
  defp do_start_link(match, opts) do
    if match && length(match.match_rounds) < Keyword.get(opts, :match_rounds, 10) do
      {:ok, pid} = :gen_statem.start_link(__MODULE__, {match, opts}, [])
      {_, ^pid} = Cache.set(match.id, {node(), pid})
      {:ok, pid}
    else
      {:error, :game_over}
    end
  end

  @spec move(integer, integer, String.t) :: {:ok, String.t} | {:error, any}
  def move(match_id, player_id, move)

  def move(match_id, player_id, move) when move in @valid_moves do
    call(:move, [match_id, player_id, move])
  end

  def move(_, _, move) do
    {:error, {:invalid_move, move}}
  end

  @spec info(integer) :: Match.t
  def info(match_id) do
    call(:info, [match_id])
  end

  @spec stop(integer) :: :ok | no_return
  def stop(match_id) do
    match_id
    |> Cache.get!()
    |> elem(1)
    |> :gen_statem.stop()
  end

  ## Mandatory callback functions

  @doc false
  def init({match, opts}) do
    _ = Process.flag(:trap_exit, true)
    data = %Data{match: match, rounds: match.match_rounds, opts: opts}
    {:ok, :play, %{data | tref: set_round_timer(data)}}
  end

  @doc false
  def terminate(_reason, _state, %Data{match: %Match{id: match_id}}) do
    Cache.delete(match_id)
  end

  @doc false
  def callback_mode, do: :state_functions

  ## State callback(s)

  def play({:call, from}, {:move, player_id, move}, %Data{match: %Match{player1_id: p1, player2_id: p2}} = data) do
    if player_id in [p1, p2] do
      do_play(from, player_id, move, data)
    else
      {:next_state, :play, data, [{:reply, from, {:error, {:invalid_player, player_id}}}]}
    end
  end

  def play({:call, from}, :round_timeout, %Data{round: round} = data) do
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

  defp do_play(from, player_id, move, %Data{round: round, rounds: rounds, match: match, opts: opts} = data) do
    player_key = player_key(player_id, match)

    case round do
      [] ->
        data = %{data | round: [{player_key, move}]}
        {:next_state, :play, data, [{:reply, from, {:ok, move}}]}
      [{^player_key, prev_move}] ->
        {:next_state, :play, data, [{:reply, from, {:ok, prev_move}}]}
      [prev_move] ->
        tref = set_round_timer(data)
        {new_round, match} = new_round(match, [prev_move, {player_key, move}])
        data = %{data | round: [], rounds: [new_round | rounds], match: match, tref: tref}

        if length(data.rounds) >= Keyword.get(opts, :match_rounds, 10) do
          # game over, stop the fsm
          {:stop_and_reply, :normal, [{:reply, from, {:ok, move}}], data}
        else
          {:next_state, :play, data, [{:reply, from, {:ok, move}}]}
        end
    end
  end

  ## Handle events common to all states

  def handle_event({:call, from}, :info, %Data{match: match, rounds: rounds} = data) do
    {:keep_state, data, [{:reply, from, %{match | match_rounds: rounds}}]}
  end

  def handle_event(_, _, data) do
    {:keep_state, data}
  end

  ## Private Functions

  defp player_key(player_id, %Match{player1_id: player_id}), do: :player1_move
  defp player_key(player_id, %Match{player2_id: player_id}), do: :player2_move

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
    match
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

  defp set_round_timer(%Data{tref: tref, opts: opts}) do
    _ = :timer.cancel(tref)
    {:ok, tref} =
      opts
      |> Keyword.get(:round_timeout, 10000)
      |> :timer.apply_after(:gen_statem, :call, [self(), :round_timeout])
    tref
  end

  defp call(fun, [match_id | args]) do
    match_id
    |> Cache.get()
    |> case do
      nil ->
        {:error, :invalid_match}
      {node, pid} ->
        args =
          case args do
            [_ | _] -> [pid, List.to_tuple([fun | args])]
            []      -> [pid, fun]
          end
        :rpc.call(node, :gen_statem, :call, args)
    end
  end
end
