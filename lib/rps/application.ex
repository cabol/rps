defmodule Rps.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    # Setup the cluster
    :ok = setup_cluster()

    children = [
      # Ecto
      supervisor(Rps.Repo, []),

      # Distributed Cache for Game FSM sessions (works as a Registry)
      supervisor(Rps.Cache.Local, []),
      supervisor(Rps.Cache, []),

      # FSM for handling game sessions
      supervisor(Rps.Games.Fsm.Supervisor, []),

      # Phoenix
      supervisor(RpsWeb.Endpoint, []),

      # Leaderboard GenServer
      worker(Rps.Games.Leaderboard, [])
    ]

    opts = [strategy: :one_for_one, name: Rps.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    RpsWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp setup_cluster do
    :rps
    |> Application.get_env(:nodes, [])
    |> Enum.each(&:net_adm.ping/1)
  end
end
