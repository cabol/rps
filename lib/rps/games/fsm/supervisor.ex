defmodule Rps.Games.Fsm.Supervisor do
  @moduledoc false
  use Supervisor

  alias Rps.Cache
  alias Rps.Games.Fsm

  ## API

  @doc """
  Starts the FSM manager supervisor.
  """
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Starts a new FSM as part of this supervision tree.
  """
  def start_child(match_id, opts \\ []) do
    Supervisor.start_child(__MODULE__, [match_id, opts])
  end

  @doc """
  Terminates the FSM attached to the given `match_id`.
  """
  def terminate_child(match_id) do
    pid = Cache.pop(match_id)
    Supervisor.terminate_child(__MODULE__, pid)
  end

  ## Callbacks

  @doc false
  def init(_arg) do
    children = [child_spec()]
    Supervisor.init(children, strategy: :simple_one_for_one)
  end

  ## Private Functions

  defp child_spec do
    %{
      id: System.unique_integer([:positive]),
      start: {Fsm, :start_link, []}
    }
  end
end
