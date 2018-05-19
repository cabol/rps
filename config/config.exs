# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :rps,
  ecto_repos: [Rps.Repo]

# Configures the endpoint
config :rps, RpsWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "HVOE1NC2lvtd+nM0sH5j0PZa+QUnwQwYZBHCOeQdSAjTKehAJVk6Qdv6OV5G8+P5",
  render_errors: [view: RpsWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Rps.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Distributed Cache
# This cache works as a registry in order to store game sessions (FSMs),
# and be able to work in distributed fashion
config :rps, Rps.Cache,
  adapter: Nebulex.Adapters.Dist,
  local: Rps.Cache.Local

# Local Cache Backend
config :rps, Rps.Cache.Local,
  adapter: Nebulex.Adapters.Local,
  gc_interval: 3600

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
