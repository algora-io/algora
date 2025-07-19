defmodule Algora.Interviews do
  @moduledoc """
  The Interviews context.
  """

  import Ecto.Query, warn: false

  alias Algora.Interviews.JobInterview
  alias Algora.Repo

  @doc """
  Returns the list of job interviews.

  ## Examples

      iex> list_job_interviews()
      [%JobInterview{}, ...]

  """
  def list_job_interviews do
    Repo.all(JobInterview)
  end

  @doc """
  Returns the list of job interviews grouped by organization.
  Groups by the job posting's user (which represents the organization).

  ## Examples

      iex> list_job_interviews_by_org()
      %{org_id => [%JobInterview{}, ...]}

  """
  def list_job_interviews_by_org do
    JobInterview
    |> join(:inner, [ji], jp in assoc(ji, :job_posting))
    |> join(:inner, [ji, jp], org in assoc(jp, :user))
    |> preload([ji, jp, org], job_posting: {jp, user: org})
    |> preload(:user)
    |> Repo.all()
    |> Enum.group_by(fn interview -> interview.job_posting.user_id end)
  end

  @doc """
  Gets a single job interview.

  Raises `Ecto.NoResultsError` if the Job interview does not exist.

  ## Examples

      iex> get_job_interview!(123)
      %JobInterview{}

      iex> get_job_interview!(456)
      ** (Ecto.NoResultsError)

  """
  def get_job_interview!(id), do: Repo.get!(JobInterview, id)

  @doc """
  Creates a job interview.

  ## Examples

      iex> create_job_interview(%{field: value})
      {:ok, %JobInterview{}}

      iex> create_job_interview(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_job_interview(attrs \\ %{}) do
    %JobInterview{}
    |> JobInterview.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a job interview.

  ## Examples

      iex> update_job_interview(job_interview, %{field: new_value})
      {:ok, %JobInterview{}}

      iex> update_job_interview(job_interview, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_job_interview(%JobInterview{} = job_interview, attrs) do
    job_interview
    |> JobInterview.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a job interview.

  ## Examples

      iex> delete_job_interview(job_interview)
      {:ok, %JobInterview{}}

      iex> delete_job_interview(job_interview)
      {:error, %Ecto.Changeset{}}

  """
  def delete_job_interview(%JobInterview{} = job_interview) do
    Repo.delete(job_interview)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking job interview changes.

  ## Examples

      iex> change_job_interview(job_interview)
      %Ecto.Changeset{data: %JobInterview{}}

  """
  def change_job_interview(%JobInterview{} = job_interview, attrs \\ %{}) do
    JobInterview.changeset(job_interview, attrs)
  end

  @doc """
  Creates a job interview with the given status.

  ## Examples

      iex> create_interview_with_status(user_id, job_posting_id, :scheduled)
      {:ok, %JobInterview{}}

      iex> create_interview_with_status(user_id, job_posting_id, :completed, "Great candidate!")
      {:ok, %JobInterview{}}

  """
  def create_interview_with_status(user_id, job_posting_id, status, notes \\ nil) do
    attrs = %{
      user_id: user_id,
      job_posting_id: job_posting_id,
      status: status,
      notes: notes
    }

    attrs =
      case status do
        :scheduled ->
          Map.put(attrs, :scheduled_at, DateTime.utc_now())

        :completed ->
          attrs
          |> Map.put(:scheduled_at, DateTime.utc_now())
          |> Map.put(:completed_at, DateTime.utc_now())

        _ ->
          attrs
      end

    create_job_interview(attrs)
  end
end
