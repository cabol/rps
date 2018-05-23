defmodule RpsWeb.Router do
  use RpsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug Rps.Accounts.Auth.Pipeline
  end

  scope "/api/v1", RpsWeb do
    pipe_through [:api, :auth]

    # Sessions
    post "/login", SessionController, :login
    post "/logout", SessionController, :logout

    # User Management
    post "/users", UserController, :create
    put "/users", UserController, :update
    get "/users", UserController, :index
    get "/users/:id", UserController, :show
    delete "/users", UserController, :delete

    # Match Games
    post "/match_games", MatchController, :create
    put "/match_games/:id", MatchController, :join
    get "/match_games", MatchController, :index
    get "/match_games/:id", MatchController, :show
    delete "/match_games/:id", MatchController, :delete

    # Match Rounds
    put "/match_games/:match_id/match_rounds", RoundController, :play
    get "/match_games/:match_id/match_rounds", RoundController, :index
  end
end
