defmodule Algora.Matches do
  @moduledoc false

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Algora.Jobs.JobPosting
  alias Algora.Matches.JobMatch
  alias Algora.Repo

  require Logger

  def list_job_matches(opts \\ []) do
    order_by_clause = opts[:order_by] || [asc: :updated_at]

    JobMatch
    |> filter_by_job_posting_id(opts[:job_posting_id])
    |> filter_by_user_id(opts[:user_id])
    |> filter_by_org_id(opts[:org_id])
    |> filter_by_status(opts[:status])
    |> join(:inner, [m], j in assoc(m, :job_posting), as: :j)
    |> filter_by_org_id(opts[:org_id])
    |> order_by(^order_by_clause)
    |> maybe_preload(opts[:preload])
    |> Repo.all()
  end

  def get_job_match!(id) do
    JobMatch
    |> preload([:user, :job_posting])
    |> Repo.get!(id)
  end

  def get_job_match_by_id(id) do
    JobMatch
    |> preload([:user, :job_posting])
    |> Repo.get(id)
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

  def upsert_job_match(attrs) do
    case create_job_match(attrs) do
      {:ok, match} ->
        if confirmed?(match) do
          Algora.Cloud.notify_match(attrs)
        end

        {:ok, match}

      {:error, _changeset} ->
        match = Repo.get_by(JobMatch, user_id: attrs.user_id, job_posting_id: attrs.job_posting_id)

        case match |> change(%{status: attrs.status}) |> Repo.update() do
          {:ok, updated_match} = result ->
            if not confirmed?(match) and confirmed?(updated_match) do
              Algora.Cloud.notify_match(attrs)
            end

            result

          error ->
            error
        end
    end
  end

  defp confirmed?(%{status: status}) when status in [:approved, :highlighted], do: true
  defp confirmed?(_match), do: false

  def fetch_job_matches(job_posting_id) do
    job = Repo.get!(JobPosting, job_posting_id)

    existing_matches =
      Repo.all(
        from(m in JobMatch,
          where: m.job_posting_id == ^job_posting_id,
          where: m.status in [:highlighted, :approved]
        )
      )

    discarded_matches =
      Repo.all(
        from(m in JobMatch,
          where: m.job_posting_id == ^job_posting_id,
          where: m.status == :discarded
        )
      )

    ids_not = Enum.map(existing_matches, & &1.user_id) ++ Enum.map(discarded_matches, & &1.user_id)

    opts = [
      ids_not: ids_not,
      tech_stack: job.tech_stack,
      by_language_contributions: true,
      not_discarded: true,
      system_tags: job.system_tags
    ]

    location_iso_lvl4 =
      if job.location_iso_lvl4 && job.countries &&
           Enum.any?(job.countries, &String.starts_with?(job.location_iso_lvl4, &1)) do
        job.location_iso_lvl4
      end

    m1 =
      if location_iso_lvl4 do
        opts
        |> Keyword.put(:limit, 6)
        |> Keyword.put(:location_iso_lvl4, location_iso_lvl4)
        |> Algora.Cloud.list_top_matches()
      else
        []
      end

    m2 =
      opts
      |> Keyword.put(:limit, max(6 - length(m1), 3))
      |> Keyword.put(:location_iso_lvl4_not, location_iso_lvl4)
      |> Keyword.put(:countries, job.countries)
      |> Algora.Cloud.list_top_matches()

    m3 =
      opts
      |> Keyword.put(:limit, 3)
      |> Keyword.put(:sort_by, [{"regions", job.regions}])
      |> Algora.Cloud.list_top_matches()

    matches = m1 ++ m2 ++ m3

    matches
    |> Enum.uniq_by(& &1.user_id)
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

    Repo.tx(fn ->
      # Delete existing matches for this job posting
      Repo.delete_all(
        from(m in JobMatch,
          where: m.job_posting_id == ^job_posting_id,
          where: m.status not in [:highlighted, :approved, :discarded]
        )
      )

      # Insert new matches
      case Repo.insert_all(JobMatch, matches, on_conflict: :nothing) do
        {0, _} -> {:error, "No matches created"}
        {count, _} -> {:ok, count}
      end
    end)
  end

  def update_job_match(%JobMatch{} = job_match, attrs) do
    changeset = JobMatch.changeset(job_match, attrs)

    case Repo.update(changeset) do
      {:ok, updated_job_match} ->
        # Check if approval timestamps were just set and enqueue emails
        enqueue_like_emails_if_needed(job_match, updated_job_match)
        {:ok, updated_job_match}

      error ->
        error
    end
  end

  defp enqueue_like_emails_if_needed(old_match, new_match) do
    # Check if company_approved_at was just set (wasn't set before, but is now)
    if is_nil(old_match.company_approved_at) &&
         is_nil(old_match.candidate_approved_at) &&
         not is_nil(new_match.company_approved_at) do
      Algora.Cloud.notify_company_like(new_match.id)
    end

    # Check if candidate_approved_at was just set (wasn't set before, but is now)
    if is_nil(old_match.candidate_approved_at) &&
         is_nil(old_match.company_approved_at) &&
         not is_nil(new_match.candidate_approved_at) do
      Algora.Cloud.notify_candidate_like(new_match.id)
    end
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

  def list_user_approved_matches(user_id) do
    JobMatch
    |> filter_by_user_id(user_id)
    |> filter_by_status([:approved, :highlighted])
    |> join(:inner, [m], j in assoc(m, :job_posting), as: :j)
    |> order_by([m],
      asc: m.candidate_approved_at,
      asc: m.candidate_bookmarked_at,
      desc: m.candidate_discarded_at,
      # asc: fragment("CASE WHEN ? = 'highlighted' THEN 0 WHEN ? = 'approved' THEN 1 ELSE 2 END", m.status, m.status),
      desc: m.inserted_at
    )
    |> preload(job_posting: :user)
    |> Repo.all()
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

  defp filter_by_org_id(query, nil), do: query

  defp filter_by_org_id(query, org_id) do
    where(query, [m, j], j.user_id == ^org_id)
  end

  defp filter_by_status(query, nil), do: query

  defp filter_by_status(query, status) when is_list(status) do
    where(query, [m], m.status in ^status)
  end

  defp filter_by_status(query, status) do
    where(query, [m], m.status == ^status)
  end

  defp maybe_preload(query, nil), do: query

  defp maybe_preload(query, preload_list) do
    preload(query, ^preload_list)
  end
end
