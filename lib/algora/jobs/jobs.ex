defmodule Algora.Jobs do
  @moduledoc false

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Bounties.LineItem
  alias Algora.Jobs.JobApplication
  alias Algora.Jobs.JobPosting
  alias Algora.Payments
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Util

  require Logger

  def price, do: Money.new(:USD, 499, no_fraction_if_integer: true)

  def list_jobs(opts \\ []) do
    JobPosting
    |> where([j], j.status == :active)
    |> order_by([j], desc: j.inserted_at)
    |> maybe_filter_by_tech_stack(opts[:tech_stack])
    |> maybe_limit(opts[:limit])
    |> Repo.all()
    |> Repo.preload(:user)
  end

  def create_job_posting(attrs) do
    %JobPosting{}
    |> JobPosting.changeset(attrs)
    |> Repo.insert()
  end

  defp maybe_filter_by_tech_stack(query, nil), do: query
  defp maybe_filter_by_tech_stack(query, []), do: query

  defp maybe_filter_by_tech_stack(query, tech_stack) do
    where(query, [j], fragment("? && ?", j.tech_stack, ^tech_stack))
  end

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit), do: limit(query, ^limit)

  @spec create_payment_session(job_posting: JobPosting.t()) ::
          {:ok, String.t()} | {:error, atom()}
  def create_payment_session(job_posting) do
    line_items = [%LineItem{amount: price(), title: "Job posting - #{job_posting.company_name}"}]

    gross_amount = LineItem.gross_amount(line_items)
    group_id = Nanoid.generate()

    Repo.transact(fn ->
      with {:ok, user} <-
             Accounts.get_or_register_user(job_posting.email, %{
               type: :organization,
               display_name: job_posting.company_name
             }),
           {:ok, _charge} <-
             %Transaction{}
             |> change(%{
               id: Nanoid.generate(),
               provider: "stripe",
               type: :charge,
               status: :initialized,
               user_id: user.id,
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
               success_url: "#{AlgoraWeb.Endpoint.url()}/jobs?status=paid",
               cancel_url: "#{AlgoraWeb.Endpoint.url()}/jobs?status=canceled"
             ) do
        {:ok, session.url}
      end
    end)
  end

  def create_application(job_id, user) do
    %JobApplication{}
    |> JobApplication.changeset(%{job_id: job_id, user_id: user.id})
    |> Repo.insert()
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
    applications =
      JobApplication
      |> where([a], a.job_id == ^job.id)
      |> preload(:user)
      |> Repo.all()

    {:ok, applications}
  end
end
