defmodule Algora.Jobs do
  @moduledoc false

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Bounties.LineItem
  alias Algora.Interviews.JobInterview
  alias Algora.Jobs.JobApplication
  alias Algora.Jobs.JobPosting
  alias Algora.Matches.JobMatch
  alias Algora.Payments
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Util

  require Logger

  def list_jobs(opts \\ []) do
    query =
      JobPosting
      |> maybe_filter_by_ids(opts[:ids])
      |> maybe_filter_by_status(opts)
      |> maybe_filter_by_user(opts)
      |> join(:inner, [j], u in User, on: u.id == j.user_id)
      |> maybe_filter_by_handle(opts[:handle])
      |> maybe_filter_by_tech_stack(opts[:tech_stack])
      |> join(:left, [j], i in JobInterview, on: i.job_posting_id == j.id and i.status not in [:initial])
      |> join(:left, [j], m in JobMatch, on: m.job_posting_id == j.id and m.status not in [:pending, :discarded])
      |> group_by([j, u, i, m], [u.contract_signed, j.id, j.inserted_at])
      |> order_by([j, u, i, m],
        desc: u.contract_signed,
        desc_nulls_last: max(i.inserted_at),
        desc: j.inserted_at
      )
      |> maybe_limit(opts[:limit])

    query =
      if opts[:remove_dripped] do
        where(
          query,
          [j, u],
          u.contract_signed or fragment("not exists (select 1 from drips where drips.org_id = ?)", u.id)
        )
      else
        query
      end

    query =
      if opts[:dripped_only] do
        where(
          query,
          [j, u],
          not u.contract_signed and fragment("exists (select 1 from drips where drips.org_id = ?)", u.id)
        )
      else
        query
      end

    query
    |> Repo.all()
    |> apply_preloads(opts)
  end

  def count_jobs(opts \\ []) do
    JobPosting
    |> maybe_filter_by_status(opts[:status])
    |> maybe_filter_by_user(opts)
    |> join(:inner, [j], u in User, on: u.id == j.user_id)
    |> maybe_filter_by_tech_stack(opts[:tech_stack])
    |> Repo.aggregate(:count)
  end

  def create_job_posting(attrs) do
    %JobPosting{}
    |> JobPosting.changeset(attrs)
    |> Repo.insert()
  end

  defp maybe_filter_by_user(query, user_id: user_id, handles: handles) when is_nil(user_id) and is_nil(handles) do
    where(query, [j, u], j.status in [:active])
  end

  defp maybe_filter_by_user(query, user_id: user_id) do
    where(query, [j], j.user_id == ^user_id and j.status in [:active, :processing])
  end

  defp maybe_filter_by_user(query, _), do: query

  defp maybe_filter_by_handle(query, nil), do: query

  defp maybe_filter_by_handle(query, handle) do
    where(query, [j, u], u.handle == ^handle)
  end

  defp maybe_filter_by_ids(query, nil), do: query

  defp maybe_filter_by_ids(query, ids) do
    where(query, [j], j.id in ^ids)
  end

  defp maybe_filter_by_status(query, opts) do
    cond do
      opts[:status] == :all -> where(query, [j], j.status in [:active, :processing])
      opts[:user_id] -> where(query, [j], j.status in [:active, :processing])
      opts[:handle] -> where(query, [j, u], j.status in [:active, :processing])
      opts[:ids] -> where(query, [j, u], j.status in [:active, :processing])
      true -> where(query, [j], j.status in [:active])
    end
  end

  defp maybe_filter_by_tech_stack(query, nil), do: query
  defp maybe_filter_by_tech_stack(query, []), do: query

  defp maybe_filter_by_tech_stack(query, tech_stack) do
    where(query, [j], fragment("? && ?", j.tech_stack, ^tech_stack))
  end

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit), do: limit(query, ^limit)

  defp apply_preloads(jobs, opts) do
    preloads = [:user | opts[:preload] || []]
    Repo.preload(jobs, preloads)
  end

  @spec create_payment_session(User.t() | nil, JobPosting.t(), Money.t()) ::
          {:ok, String.t()} | {:error, atom()}
  def create_payment_session(user, job_posting, amount) do
    line_items = [
      %LineItem{
        amount: amount,
        title: "Algora Annual Subscription",
        description: "Hiring services annual package"
      },
      %LineItem{
        amount: Money.mult!(amount, Decimal.new("0.04")),
        title: "Processing fee (4%)"
      }
    ]

    gross_amount = LineItem.gross_amount(line_items)
    group_id = Nanoid.generate()

    job_posting = Repo.preload(job_posting, :user)

    Repo.tx(fn ->
      with {:ok, _charge} <-
             %Transaction{}
             |> change(%{
               id: Nanoid.generate(),
               provider: "stripe",
               type: :charge,
               status: :initialized,
               user_id: if(user, do: user.id),
               job_id: job_posting.id,
               gross_amount: gross_amount,
               net_amount: gross_amount,
               total_fee: Money.zero(:USD),
               line_items: Util.normalize_struct(line_items),
               group_id: group_id,
               idempotency_key: "session-#{Nanoid.generate()}"
             })
             |> Algora.Validations.validate_positive(:gross_amount)
             |> Algora.Validations.validate_positive(:net_amount)
             |> foreign_key_constraint(:user_id)
             |> unique_constraint([:idempotency_key])
             |> Repo.insert(),
           {:ok, session} <-
             Payments.create_stripe_session(
               user,
               Enum.map(line_items, &LineItem.to_stripe/1),
               %{
                 description: "Job posting - #{job_posting.company_name}",
                 metadata: %{"version" => Payments.metadata_version(), "group_id" => group_id}
               },
               success_url:
                 "#{AlgoraWeb.Endpoint.url()}/#{job_posting.user.handle}/jobs/#{job_posting.id}/applicants?status=paid",
               cancel_url: "#{AlgoraWeb.Endpoint.url()}/#{job_posting.user.handle}/jobs/#{job_posting.id}/applicants"
             ) do
        {:ok, session.url}
      end
    end)
  end

  def create_application(job_id, user, attrs \\ %{}) do
    %JobApplication{job_id: job_id, user_id: user.id}
    |> JobApplication.changeset(attrs)
    |> Repo.insert()
  end

  def ensure_application(job_id, user, attrs \\ %{}) do
    case JobApplication |> where([a], a.job_id == ^job_id and a.user_id == ^user.id) |> Repo.one() do
      nil -> create_application(job_id, user, attrs)
      application -> {:ok, application}
    end
  end

  def list_user_applications(user) do
    JobApplication
    |> where([a], a.user_id == ^user.id)
    |> select([a], a.job_id)
    |> Repo.all()
    |> MapSet.new()
  end

  def get_job_posting(id) do
    case JobPosting |> Repo.get(id) |> Repo.preload(:user) do
      nil -> {:error, :not_found}
      job -> {:ok, job}
    end
  end

  def list_job_applications(job) do
    JobApplication
    |> where([a], a.job_id == ^job.id)
    |> preload(:user)
    |> Repo.all()
  end
end
