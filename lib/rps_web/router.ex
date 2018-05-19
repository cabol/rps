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

  scope "/api/v1", RpsWeb do
    pipe_through :api

    resources "/users", UserController, except: [:new, :edit]
    resources "/match_games", MatchController, except: [:new, :edit]
    resources "/match_rounds", RoundController, except: [:new, :edit]
  end
end
