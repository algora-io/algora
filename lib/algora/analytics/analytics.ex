defmodule Algora.Analytics do
  @moduledoc false
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Bounties.Bounty
  alias Algora.Contracts.Contract
  alias Algora.Repo

  require Algora.SQL

  # TODO
  #
  # active org: org who triggered a GMV event in given period
  # GMV events: bounty.created, bounty.rewarded, contract.payment_escrowed, contract.payment_released etc.
  # successful contract: currently active or paid contract
  # avg time to fill: time from published to accepted, avg over all successful contracts (excl. renewals)

  def get_company_analytics(period \\ "30d", from \\ DateTime.utc_now()) do
    days = period |> String.replace("d", "") |> String.to_integer()
    period_start = DateTime.add(from, -days * 24 * 3600)
    previous_period_start = DateTime.add(period_start, -days * 24 * 3600)

    orgs_query =
      from u in User,
        where: u.type == :organization,
        select: %{
          count_all: count(u.id),
          count_current: u.id |> count() |> filter(u.inserted_at <= ^from and u.inserted_at >= ^period_start),
          count_previous:
            u.id |> count() |> filter(u.inserted_at <= ^period_start and u.inserted_at >= ^previous_period_start),
          active_all: u.id |> count() |> filter(u.seeded and u.activated),
          active_current:
            u.id
            |> count()
            |> filter(u.seeded and u.activated and u.inserted_at <= ^from and u.inserted_at >= ^period_start),
          active_previous:
            u.id
            |> count()
            |> filter(
              u.seeded and u.activated and u.inserted_at <= ^period_start and u.inserted_at >= ^previous_period_start
            )
        }

    contracts_query =
      from u in Contract,
        where: u.inserted_at >= ^previous_period_start,
        select: %{
          count_current: u.id |> count() |> filter(u.inserted_at < ^from and u.inserted_at >= ^period_start),
          count_previous:
            u.id |> count() |> filter(u.inserted_at < ^period_start and u.inserted_at >= ^previous_period_start),
          success_current:
            u.id
            |> count()
            |> filter(
              u.inserted_at < ^from and u.inserted_at >= ^period_start and (u.status == :active or u.status == :paid)
            ),
          success_previous:
            u.id
            |> count()
            |> filter(
              u.inserted_at < ^period_start and u.inserted_at >= ^previous_period_start and
                (u.status == :active or u.status == :paid)
            )
        }

    companies_query =
      from u in User,
        where: u.inserted_at >= ^period_start,
        where: u.type == :organization,
        where: u.featured,
        left_join: b in Bounty,
        on: b.owner_id == u.id,
        distinct: [u.id],
        group_by: [u.id, b.id],
        order_by: [desc: b.inserted_at],
        select: %{
          id: u.id,
          name: u.name,
          handle: u.handle,
          joined_at: u.inserted_at,
          total_bounties: b.id |> count() |> filter(b.inserted_at >= ^period_start),
          successful_bounties:
            b.id |> count() |> filter(b.status == :open or (b.status == :paid and b.inserted_at >= ^period_start)),
          last_active_at: u.updated_at,
          avatar_url: u.avatar_url
        }

    Ecto.Multi.new()
    |> Ecto.Multi.one(:orgs, orgs_query)
    |> Ecto.Multi.one(:contracts, contracts_query)
    |> Ecto.Multi.all(:companies, companies_query)
    |> Repo.transaction()
    |> case do
      {:ok, resp} ->
        %{
          orgs: orgs,
          contracts: contracts,
          companies: companies
        } = resp

        current_success_rate = calculate_success_rate(contracts.success_current, contracts.count_current)
        previous_success_rate = calculate_success_rate(contracts.success_previous, contracts.count_previous)

        {:ok,
         %{
           total_companies: orgs.count_all,
           companies_change: orgs.count_current,
           companies_trend: calculate_trend(orgs.count_current, orgs.count_previous),
           active_companies: orgs.active_all,
           active_change: orgs.active_current,
           active_trend: calculate_trend(orgs.active_current, orgs.active_previous),
           # TODO track time when contract is filled
           #
           # in open contracts (contracts w/o contractor_id) we track :published_at
           # in filled contracts (contracts w/ contractor_id) we track both :published_at (inherited) and :accepted_at
           avg_time_to_fill: 0.0,
           time_to_fill_change: -0.0,
           time_to_fill_trend: :down,
           bounty_success_rate: current_success_rate,
           previous_bounty_success_rate: previous_success_rate,
           success_rate_change: current_success_rate - previous_success_rate,
           success_rate_trend: calculate_trend(current_success_rate, previous_success_rate),
           companies:
             Enum.map(companies, fn company ->
               Map.merge(company, %{
                 success_rate: calculate_success_rate(company.successful_bounties, company.total_bounties),
                 status: if(company.successful_bounties > 0, do: :active, else: :inactive)
               })
             end)
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_funnel_data(_period \\ "30d", _from \\ DateTime.utc_now()) do
    # Mock funnel data
    %{
      registered: 100,
      card_saved: 75,
      contract_started: 50,
      released_renewed: 35,
      released_only: 10,
      disputed: 5
    }
  end

  defp calculate_success_rate(successful, total) when successful == 0 or total == 0, do: 0.0
  defp calculate_success_rate(successful, total), do: Float.ceil(successful / total * 100, 0)

  defp calculate_trend(a, b) when a > b, do: :up
  defp calculate_trend(a, b) when a < b, do: :down
  defp calculate_trend(a, b) when a == b, do: :same
end
