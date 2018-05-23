defmodule RpsWeb.UserView do
  use RpsWeb, :view
  alias RpsWeb.UserView

  def render("index.json", %{users: users}) do
    %{data: render_many(users, UserView, "user.json")}
  end

  def render("show.json", %{user: user}) do
    %{data: render_one(user, UserView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      username: user.username,
      name: user.name,
      alias: user.alias,
      wins: user.wins
    }
  end
end
