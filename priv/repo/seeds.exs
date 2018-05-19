# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Rps.Repo.insert!(%Rps.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Rps.Repo
alias Rps.Accounts.User

users = [
  %User{
    username: "cabol",
    password: "cabol"
  },
  %User{
    username: "admin",
    password: "admin"
  }
]

for user <- users do
  Repo.insert!(user)
end
