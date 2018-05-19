defmodule Rps.Games do
  @moduledoc """
  The Games context.
  """

  import Ecto.Query, warn: false

  alias Rps.Repo
  alias Rps.Games.Match
  alias Rps.Games.Fsm.Supervisor, as: FsmSupervisor

  @doc """
  Returns the list of match_games.

  ## Examples

      iex> list_match_games()
      [%Match{}, ...]

  """
  def list_match_games do
    Repo.all(Match)
  end

  @doc """
  Gets a single match.

  Raises `Ecto.NoResultsError` if the Match does not exist.

  ## Examples

      iex> get_match!(123)
      %Match{}

      iex> get_match!(456)
      ** (Ecto.NoResultsError)

  """
  def get_match!(id), do: Repo.get!(Match, id)

  @doc """
  Gets a single match with its associated rounds

  ## Examples

      iex> get_match_with_rounds!(123)
      %Match{rounds: [%Round{}, ...]}

      iex> get_match_with_rounds!(456)
      ** (Ecto.NoResultsError)

  """
  def get_match_with_rounds(id) do
    Match
    |> Repo.get(id)
    |> Repo.preload(:match_rounds)
  end

  @doc """
  Creates a match.

  ## Examples

      iex> create_match(%{field: value})
      {:ok, %Match{}}

      iex> create_match(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_match(attrs \\ %{}) do
    %Match{}
    |> Match.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, match} ->
        # start a new game session (new FSM)
        {:ok, _pid} = FsmSupervisor.start_child(match.id)
        {:ok, match}
      error ->
        error
    end
  end

  @doc """
  Updates a match.

  ## Examples

      iex> update_match(match, %{field: new_value})
      {:ok, %Match{}}

      iex> update_match(match, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_match(%Match{} = match, attrs) do
    match
    |> Match.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Match.

  ## Examples

      iex> delete_match(match)
      {:ok, %Match{}}

      iex> delete_match(match)
      {:error, %Ecto.Changeset{}}

  """
  def delete_match(%Match{} = match) do
    Repo.delete(match)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking match changes.

  ## Examples

      iex> change_match(match)
      %Ecto.Changeset{source: %Match{}}

  """
  def change_match(%Match{} = match) do
    Match.changeset(match, %{})
  end

  alias Rps.Games.Round

  @doc """
  Returns the list of match_rounds.

  ## Examples

      iex> list_match_rounds()
      [%Round{}, ...]

  """
  def list_match_rounds do
    Repo.all(Round)
  end

  @doc """
  Returns a list of match_rounds filtered by `match_id`

  ## Examples

      iex> list_match_rounds()
      [%Round{}, ...]

  """
  def list_match_rounds(match_id) do
    Repo.all from r in Round,
      where: r.match_id == ^match_id
  end

  @doc """
  Gets a single round.

  Raises `Ecto.NoResultsError` if the Round does not exist.

  ## Examples

      iex> get_round!(123)
      %Round{}

      iex> get_round!(456)
      ** (Ecto.NoResultsError)

  """
  def get_round!(id), do: Repo.get!(Round, id)

  @doc """
  Creates a round.

  ## Examples

      iex> create_round(%{field: value})
      {:ok, %Round{}}

      iex> create_round(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_round(attrs \\ %{}) do
    %Round{}
    |> Round.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a round.

  ## Examples

      iex> update_round(round, %{field: new_value})
      {:ok, %Round{}}

      iex> update_round(round, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_round(%Round{} = round, attrs) do
    round
    |> Round.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Round.

  ## Examples

      iex> delete_round(round)
      {:ok, %Round{}}

      iex> delete_round(round)
      {:error, %Ecto.Changeset{}}

  """
  def delete_round(%Round{} = round) do
    Repo.delete(round)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking round changes.

  ## Examples

      iex> change_round(round)
      %Ecto.Changeset{source: %Round{}}

  """
  def change_round(%Round{} = round) do
    Round.changeset(round, %{})
  end
end
