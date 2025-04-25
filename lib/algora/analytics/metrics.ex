defmodule Algora.Analytics.Metrics do
  @moduledoc false

  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Repo

  @type interval :: :daily | :weekly | :monthly
  @type period_metrics :: %{
          org_signups: non_neg_integer(),
          org_returns: non_neg_integer(),
          dev_signups: non_neg_integer(),
          dev_returns: non_neg_integer()
        }

  @doc """
  Returns user metrics for the last n periods with the given interval.
  Organizations are users who are members of an org where their handle differs from the org handle.
  Developers are all other users.
  """
  @spec get_user_metrics(pos_integer(), interval()) :: [{DateTime.t(), period_metrics()}]
  def get_user_metrics(n_periods, interval) do
    period_start = period_start_date(n_periods, interval)
    interval_str = interval_to_string(interval)

    # Generate periods using SQL
    periods_query =
      from(
        p in fragment(
          """
          SELECT generate_series(
            date_trunc(?, ?::timestamp),
            date_trunc(?, now()),
            (?||' '||?)::interval
          ) as period_start
          """,
          ^interval_str,
          ^period_start,
          ^interval_str,
          ^"1",
          ^interval_str
        ),
        select: %{period_start: fragment("period_start")}
      )

    # Base query for all users with org membership info
    base_query =
      from u in User,
        where: not is_nil(u.handle),
        select: %{
          inserted_at: fragment("date_trunc(?, ?)", ^interval_str, u.inserted_at),
          is_org:
            fragment(
              """
              EXISTS (SELECT 1
                FROM members m
                INNER JOIN users o ON m.org_id = o.id
                WHERE m.user_id = ? AND o.id != m.user_id
              )
              """,
              u.id
            )
        }

    # Get signups per period
    signups =
      from q in subquery(base_query),
        right_join: p in subquery(periods_query),
        on: q.inserted_at == p.period_start,
        group_by: p.period_start,
        select: {
          p.period_start,
          %{
            org_signups: coalesce(count(fragment("CASE WHEN ? IS TRUE THEN 1 END", q.is_org)), 0),
            dev_signups: coalesce(count(fragment("CASE WHEN ? IS NOT TRUE THEN 1 END", q.is_org)), 0)
          }
        }

    # Get returns per period using user_activities
    returns =
      from u in User,
        inner_join: ua in "user_activities",
        on: ua.assoc_id == u.id and ua.type == "user_online",
        where: not is_nil(u.handle),
        right_join: p in subquery(periods_query),
        on: fragment("date_trunc(?, ?)", ^interval_str, ua.inserted_at) == p.period_start,
        group_by: p.period_start,
        select: {
          p.period_start,
          %{
            org_returns:
              coalesce(
                count(
                  fragment(
                    """
                    DISTINCT CASE WHEN EXISTS (
                      SELECT 1 FROM members m
                      INNER JOIN users o ON m.org_id = o.id
                      WHERE m.user_id = ? AND o.id != m.user_id
                    ) THEN ? END
                    """,
                    u.id,
                    u.id
                  )
                ),
                0
              ),
            dev_returns:
              coalesce(
                count(
                  fragment(
                    """
                    DISTINCT CASE WHEN NOT EXISTS (
                      SELECT 1 FROM members m
                      INNER JOIN users o ON m.org_id = o.id
                      WHERE m.user_id = ? AND o.id != m.user_id
                    ) THEN ? END
                    """,
                    u.id,
                    u.id
                  )
                ),
                0
              )
          }
        }

    # Combine results
    signups = signups |> Repo.all() |> Map.new()
    returns = returns |> Repo.all() |> Map.new()

    # Merge metrics
    periods = Repo.all(periods_query)

    periods
    |> Enum.map(fn %{period_start: date} ->
      signup_metrics = Map.get(signups, date, %{org_signups: 0, dev_signups: 0})
      return_metrics = Map.get(returns, date, %{org_returns: 0, dev_returns: 0})
      {date, Map.merge(signup_metrics, return_metrics)}
    end)
    |> Enum.sort_by(&elem(&1, 0), {:desc, DateTime})
  end

  def period_start_date(n_periods, interval) do
    now = DateTime.utc_now()

    case interval do
      :daily -> DateTime.add(now, -n_periods, :day)
      :weekly -> DateTime.add(now, -n_periods * 7, :day)
      :monthly -> DateTime.add(now, -n_periods * 30, :day)
    end
  end

  defp interval_to_string(:daily), do: "day"
  defp interval_to_string(:weekly), do: "week"
  defp interval_to_string(:monthly), do: "month"
end
