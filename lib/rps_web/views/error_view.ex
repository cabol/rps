defmodule RpsWeb.ErrorView do
  use RpsWeb, :view

  require Logger

  def render("400.json", %{errors: errors}) do
    %{errors: errors}
  end
  def render("400.html", _assigns) do
    "Bad request"
  end

  def render("401.json", _assigns) do
    %{errors: %{unauthorized: "invalid_token"}}
  end
  def render("401.html", _assigns) do
    "Unauthorized"
  end

  def render("403.json", _assigns) do
    %{errors: %{forbidden: "forbidden_action"}}
  end
  def render("403.html", _assigns) do
    "Resource forbidden"
  end

  def render("404.json", _assigns) do
    %{errors: %{not_found: "requested resource wasn't found"}}
  end
  def render("404.html", _assigns) do
    "Page not found"
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def render("500.json", _assigns) do
    Logger.error "Server Error! Stacktrace: #{inspect System.stacktrace}"
    %{errors: %{internal_error: "We're experimenting problems, try later!."}}
  end
  def render("500.html", _assigns) do
    "Internal server error"
  end
end
