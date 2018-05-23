defmodule RpsWeb.SessionView do
  use RpsWeb, :view
  alias RpsWeb.SessionView

  def render("login.json", %{session: session}) do
    %{data: render_one(session, SessionView, "session.json")}
  end

  def render("logout.json", %{session: session}) do
    %{data: render_one(session, SessionView, "session.json")}
  end

  def render("session.json", %{session: session}) do
    session
  end
end
