defmodule AlgoraWeb.RegionalRankingsLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import Ecto.Query

  alias Algora.Misc.Regions
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Users

  def mount(_params, _session, socket) do
    weeks = get_weekly_rankings(20)
    {:ok, assign(socket, :weeks, weeks)}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <.header class="mb-8 text-3xl">
        Regional Rankings
        <:subtitle>Weekly top performers by region</:subtitle>
      </.header>

      <div class="space-y-4">
        <%= for {week_start, rankings} <- @weeks do %>
          <.card>
            <.card_header>
              <div class="flex justify-between items-center">
                <h3 class="text-lg font-semibold">
                  Week of {Calendar.strftime(
                    DateTime.from_naive!(week_start, "Etc/UTC"),
                    "%B %d, %Y"
                  )}
                </h3>
              </div>
            </.card_header>
            <div class="p-6">
              <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                <%= for {region, user} <- rankings do %>
                  <div class="flex flex-col space-y-4 p-4 rounded-lg bg-card border">
                    <div class="flex justify-between items-center">
                      <div class="text-sm font-medium text-muted-foreground">
                        #1 {region}
                      </div>
                      <div class="text-sm font-medium text-success">
                        {Money.to_string!(user.total_earned)}
                      </div>
                    </div>
                    <div class="flex items-center space-x-4">
                      <.avatar class="h-12 w-12">
                        <.avatar_image src={user.avatar_url} alt={user.name} />
                        <.avatar_fallback>
                          {String.first(user.name || "")}
                        </.avatar_fallback>
                      </.avatar>
                      <div class="space-y-1">
                        <div class="text-sm font-medium leading-none">
                          {user.name}
                        </div>
                        <div class="text-sm text-muted-foreground">
                          @{user.handle}
                        </div>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </.card>
        <% end %>
      </div>
    </div>
    """
  end

  defp get_weekly_rankings(num_weeks) do
    end_date = DateTime.utc_now()
    start_date = DateTime.add(end_date, -num_weeks * 7 * 24 * 60 * 60)

    # Get all transactions in date range
    transactions_query =
      from t in Transaction,
        join: u in Users.User,
        on: t.user_id == u.id,
        where: t.succeeded_at >= ^start_date and t.succeeded_at <= ^end_date,
        where: not is_nil(u.country),
        group_by: [
          u.id,
          u.name,
          u.handle,
          u.avatar_url,
          u.country,
          fragment("date_trunc('week', ?::timestamp)", t.succeeded_at)
        ],
        select: %{
          user_id: u.id,
          name: u.name,
          handle: u.handle,
          avatar_url: u.avatar_url,
          country: u.country,
          week: fragment("date_trunc('week', ?::timestamp)", t.succeeded_at),
          total_earned: sum(t.net_amount)
        }

    # Get transactions and organize by week and region
    transactions = Repo.all(transactions_query)

    # Group by week, then get top earner per region
    transactions
    |> Enum.group_by(& &1.week)
    |> Enum.map(fn {week, users} ->
      rankings =
        users
        |> Enum.group_by(&Regions.get_region(&1.country))
        |> Enum.map(fn {region, region_users} ->
          {region, Enum.max_by(region_users, & &1.total_earned)}
        end)
        |> Enum.sort_by(fn {region, _} -> region end)

      {week, rankings}
    end)
    |> Enum.sort_by(fn {week, _} -> NaiveDateTime.to_date(week) end, :desc)
  end
end
