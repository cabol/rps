defmodule Rps.Games do
  @moduledoc """
  The Games context.
  """

  import Ecto.Query, warn: false

  alias Rps.Repo
  alias Ecto.Changeset

  ## Match Games

  alias Rps.Games.Match

  @doc false
  def list_match_games do
    Repo.all(Match)
  end

  @doc false
  def get_match!(id), do: Repo.get!(Match, id)

  @doc false
  def get_match_with_rounds(id) do
    Match
    |> Repo.get(id)
    |> Repo.preload(:match_rounds)
  end

  @doc false
  def get_match_with_rounds!(id) do
    Match
    |> Repo.get!(id)
    |> Repo.preload(:match_rounds)
  end

  @doc false
  def create_match(attrs \\ %{}) do
    %Match{}
    |> Match.changeset(attrs)
    |> Repo.insert()
  end

  @doc false
  def update_match(%Match{} = match, attrs) do
    match
    |> Match.changeset(attrs)
    |> Repo.update()
  end

  @doc false
  def join_match(%Match{status: "created"} = match, attrs),
    do: update_match(match, attrs)
  def join_match(%Match{status: status} = match, _attrs) do
    changeset =
      match
      |> Changeset.change(%{})
      |> Changeset.add_error(:status, "cannot be #{status}")
    {:error, changeset}
  end

  @doc false
  def delete_match(%Match{status: "created"} = match),
    do: Repo.delete(match)
  def delete_match(%Match{status: status} = match) do
    changeset =
      match
      |> Changeset.change(%{})
      |> Changeset.add_error(:status, "cannot be #{status}")
    {:error, changeset}
  end

  @doc false
  def change_match(%Match{} = match) do
    Match.changeset(match, %{})
  end

  ## Match Rounds

  alias Rps.Games.Round

  @doc false
  def list_match_rounds do
    Repo.all(Round)
  end

  @doc false
  def list_match_rounds(match_id) do
    Repo.all from r in Round,
      where: r.match_id == ^match_id
  end

  @doc false
  def get_round!(id), do: Repo.get!(Round, id)

  @doc false
  def create_round(attrs \\ %{}) do
    %Round{}
    |> Round.changeset(attrs)
    |> Repo.insert()
  end

  @doc false
  def update_round(%Round{} = round, attrs) do
    round
    |> Round.changeset(attrs)
    |> Repo.update()
  end

  @doc false
  def delete_round(%Round{} = round) do
    Repo.delete(round)
  end

  @doc false
  def change_round(%Round{} = round) do
    Round.changeset(round, %{})
  end
end
