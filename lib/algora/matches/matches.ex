defmodule Algora.Matches do
  @moduledoc false

  import Ecto.Query, warn: false

  alias Algora.Jobs.JobPosting
  alias Algora.Matches.JobMatch
  alias Algora.Repo

  def list_job_matches(opts \\ []) do
    order_by_clause = opts[:order_by] || [desc: :inserted_at]

    JobMatch
    |> filter_by_job_posting_id(opts[:job_posting_id])
    |> filter_by_user_id(opts[:user_id])
    |> filter_by_status(opts[:status])
    |> order_by(^order_by_clause)
    |> maybe_preload(opts[:preload])
    |> Repo.all()
  end

  def get_job_match!(id) do
    JobMatch
    |> preload([:user, :job_posting])
    |> Repo.get!(id)
  end

  def get_job_match(user_id, job_posting_id) do
    JobMatch
    |> where([m], m.user_id == ^user_id and m.job_posting_id == ^job_posting_id)
    |> preload([:user, :job_posting])
    |> Repo.one()
  end

  def create_job_match(attrs \\ %{}) do
    %JobMatch{}
    |> JobMatch.changeset(attrs)
    |> Repo.insert()
  end

  def fetch_job_matches(job_posting_id) do
    job = Repo.get!(JobPosting, job_posting_id)

    job_countries =
      job.regions
      |> Enum.flat_map(&Algora.PSP.ConnectCountries.get_countries/1)
      |> Enum.concat(job.countries)
      |> Enum.uniq()

    [
      limit: 3,
      tech_stack: job.tech_stack,
      has_min_compensation: true,
      system_tags: job.system_tags,
      sort_by: [{"countries", job_countries}]
    ]
    |> Algora.Cloud.list_top_matches()
    |> Algora.Settings.load_matches_2()
  end

  def create_job_matches(job_posting_id) do
    job_posting_id
    |> fetch_job_matches()
    |> Enum.map(fn match -> match.user.id end)
    |> then(&create_job_matches(job_posting_id, &1))
  end

  def create_job_matches(job_posting_id, user_ids) do
    matches =
      Enum.map(user_ids, fn user_id ->
        %{
          id: Nanoid.generate(),
          user_id: user_id,
          job_posting_id: job_posting_id,
          inserted_at: DateTime.truncate(DateTime.utc_now(), :microsecond),
          updated_at: DateTime.truncate(DateTime.utc_now(), :microsecond)
        }
      end)

    Repo.transact(fn ->
      # Delete existing matches for this job posting
      Repo.delete_all(from(m in JobMatch, where: m.job_posting_id == ^job_posting_id))

      # Insert new matches
      case Repo.insert_all(JobMatch, matches, on_conflict: :nothing) do
        {0, _} -> {:error, "No matches created"}
        {count, _} -> {:ok, count}
      end
    end)
  end

  def update_job_match(%JobMatch{} = job_match, attrs) do
    job_match
    |> JobMatch.changeset(attrs)
    |> Repo.update()
  end

  def update_job_match_status(match_id, status) do
    case Repo.get(JobMatch, match_id) do
      nil -> {:error, :not_found}
      job_match -> update_job_match(job_match, %{status: status})
    end
  end

  def delete_job_match(%JobMatch{} = job_match) do
    Repo.delete(job_match)
  end

  def change_job_match(%JobMatch{} = job_match, attrs \\ %{}) do
    JobMatch.changeset(job_match, attrs)
  end

  # Private helper functions
  defp filter_by_job_posting_id(query, nil), do: query

  defp filter_by_job_posting_id(query, job_posting_id) do
    where(query, [m], m.job_posting_id == ^job_posting_id)
  end

  defp filter_by_user_id(query, nil), do: query

  defp filter_by_user_id(query, user_id) do
    where(query, [m], m.user_id == ^user_id)
  end

  defp filter_by_status(query, nil), do: query

  defp filter_by_status(query, status) do
    where(query, [m], m.status == ^status)
  end

  defp maybe_preload(query, nil), do: query

  defp maybe_preload(query, preload_list) do
    preload(query, ^preload_list)
  end
end
