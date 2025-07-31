defmodule AlgoraWeb.Data.HomeCache do
  @moduledoc """
  ETS-based cache for homepage data to reduce database load.
  """
  use GenServer

  # Cache keys
  @platform_stats_key :platform_stats
  @jobs_key :jobs_by_user
  @orgs_with_stats_key :orgs_with_stats

  # Cache TTL in milliseconds (10 minutes)
  @cache_ttl 10 * 60 * 1000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    table = :ets.new(__MODULE__, [:named_table, :public, read_concurrency: true])
    {:ok, %{table: table}}
  end

  @doc """
  Get platform stats with caching
  """
  def get_platform_stats do
    get_or_compute(@platform_stats_key, &compute_platform_stats/0)
  end

  @doc """
  Get jobs by user with caching
  """
  def get_jobs_by_user do
    get_or_compute(@jobs_key, &compute_jobs_by_user/0)
  end

  @doc """
  Get organizations with stats with caching
  """
  def get_orgs_with_stats do
    get_or_compute(@orgs_with_stats_key, &compute_orgs_with_stats/0)
  end

  @doc """
  Clear all cache entries
  """
  def clear_cache do
    :ets.delete_all_objects(__MODULE__)
  end

  @doc """
  Clear specific cache entry
  """
  def clear_cache(key) do
    :ets.delete(__MODULE__, key)
  end

  @doc """
  Invalidate platform stats cache when transactions change
  """
  def invalidate_platform_stats do
    clear_cache(@platform_stats_key)
  end

  @doc """
  Invalidate jobs cache when jobs change
  """
  def invalidate_jobs do
    clear_cache(@jobs_key)
  end

  @doc """
  Invalidate orgs cache when organizations or bounties change
  """
  def invalidate_orgs do
    clear_cache(@orgs_with_stats_key)
  end

  # Private functions

  defp get_or_compute(key, compute_fn) do
    case :ets.lookup(__MODULE__, key) do
      [{^key, value, expires_at}] ->
        if System.monotonic_time(:millisecond) < expires_at do
          value
        else
          # Cache expired, recompute
          :ets.delete(__MODULE__, key)
          compute_and_cache(key, compute_fn)
        end

      [] ->
        # Cache miss, compute and cache
        compute_and_cache(key, compute_fn)
    end
  end

  defp compute_and_cache(key, compute_fn) do
    value = compute_fn.()
    expires_at = System.monotonic_time(:millisecond) + @cache_ttl
    :ets.insert(__MODULE__, {key, value, expires_at})
    value
  end

  defp compute_platform_stats do
    import Ecto.Query
    alias Algora.Accounts.User
    alias Algora.Payments.Transaction
    alias Algora.Repo
    alias AlgoraWeb.Data.PlatformStats

    total_contributors =
      Repo.one(
        from(t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          select: count(fragment("DISTINCT ?", t.user_id))
        )
      ) || 0

    total_contributors = total_contributors + PlatformStats.get().extra_contributors

    total_countries =
      Repo.one(
        from(u in User,
          join: t in Transaction,
          on: t.user_id == u.id,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          where: not is_nil(u.country) and u.country != "",
          select: count(fragment("DISTINCT ?", u.country))
        )
      ) || 0

    total_paid_out_subtotal =
      Repo.one(
        from(t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          select: sum(t.net_amount)
        )
      ) || Money.new(0, :USD)

    total_paid_out =
      total_paid_out_subtotal
      |> Money.add!(PlatformStats.get().extra_paid_out)
      |> Money.round(currency_digits: 0)

    completed_bounties_subtotal =
      Repo.one(
        from(t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          where: not is_nil(t.bounty_id),
          select: count(fragment("DISTINCT (?, ?)", t.bounty_id, t.user_id))
        )
      ) || 0

    completed_tips_subtotal =
      Repo.one(
        from(t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          where: not is_nil(t.tip_id),
          select: count(fragment("DISTINCT (?, ?)", t.tip_id, t.user_id))
        )
      ) || 0

    completed_bounties_count =
      completed_bounties_subtotal + completed_tips_subtotal + PlatformStats.get().extra_completed_bounties

    %{
      total_contributors: total_contributors,
      total_countries: total_countries,
      total_paid_out: total_paid_out,
      completed_bounties_count: completed_bounties_count
    }
  end

  defp compute_jobs_by_user do
    Enum.group_by(Algora.Jobs.list_jobs(), & &1.user)
  end

  defp compute_orgs_with_stats do
    orgs = Algora.Organizations.list_orgs(limit: 6)

    Enum.map(orgs, fn org ->
      stats = Algora.Bounties.fetch_stats(org_id: org.id)
      Map.put(org, :bounty_stats, stats)
    end)
  end
end
