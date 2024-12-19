defmodule AlgoraWeb.TROTWLive do
  use AlgoraWeb, :live_view

  alias Algora.Users
  alias Algora.Misc.Regions
  alias Algora.Payments.Transaction
  alias Algora.Repo
  import Ecto.Query

  def mount(_params, _session, socket) do
    weeks = get_weekly_rankings()
    medals = calculate_medals(weeks)
    {:ok, assign(socket, weeks: weeks, medals: medals)}
  end

  def render(assigns) do
    ~H"""
    <div class="font-display container mx-auto px-4 py-8">
      <.header class="mb-8 text-center">
        <span class="text-6xl font-display font-bold">TROTW</span>
        <:subtitle>
          <span class="text-base font-display font-medium">Top Regions of the Week</span>
        </:subtitle>
      </.header>

      <.card class="mb-8">
        <.card_header>
          <h3 class="text-lg font-semibold">All-Time Medal Count</h3>
        </.card_header>
        <div class="p-6">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <%= for {region, medals} <- Enum.sort_by(@medals, fn {_, m} -> m.total end, :desc) do %>
              <div class="flex flex-col space-y-4 p-4 rounded-lg border bg-card">
                <div class="flex justify-between items-center">
                  <div class="text-xl font-medium font-display">{region}</div>
                  <div class="flex gap-6 items-center">
                    <span class="flex items-center gap-1">
                      <span class="text-2xl">🥇</span>
                      <span class="text-xl font-semibold">{medals.gold}</span>
                    </span>
                    <span class="flex items-center gap-1">
                      <span class="text-2xl">🥈</span>
                      <span class="text-xl font-semibold">{medals.silver}</span>
                    </span>
                    <span class="flex items-center gap-1">
                      <span class="text-2xl">🥉</span>
                      <span class="text-xl font-semibold">{medals.bronze}</span>
                    </span>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </.card>

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
                <%= for {{region, total_earned, top_earners}, index} <- rankings |> Enum.take(3) |> Enum.with_index(1) do %>
                  <div class={[
                    "flex flex-col space-y-4 p-4 rounded-lg border",
                    case index do
                      1 -> "bg-amber-500/20 border-amber-700/50"
                      2 -> "bg-slate-700/50 border-slate-500/50"
                      3 -> "bg-orange-700/20 border-orange-700/50"
                    end
                  ]}>
                    <div class="flex justify-between items-center">
                      <div class="text-xl font-display font-medium">
                        <span class="font-display font-bold text-4xl">
                          {case index do
                            1 -> "🥇"
                            2 -> "🥈"
                            3 -> "🥉"
                          end}
                        </span>
                        {region}
                      </div>
                      <div class="font-display text-2xl font-semibold text-success">
                        {Money.to_string!(total_earned)}
                      </div>
                    </div>

                    <div class="flex -space-x-6 overflow-hidden">
                      <%= for earner <- top_earners do %>
                        <.tooltip>
                          <.tooltip_trigger>
                            <div class="relative">
                              <img
                                src={earner.avatar_url}
                                alt={earner.handle}
                                class="bg-muted inline-block h-16 w-16 rounded-full ring-2 ring-background hover:translate-y-1 transition-transform"
                              />
                            </div>
                          </.tooltip_trigger>
                          <.tooltip_content>
                            <div class="flex flex-col items-center gap-1">
                              <span class="font-medium">@{earner.handle}</span>
                              <span class="text-sm font-display text-muted-foreground">
                                {Money.to_string!(earner.total_earned)}
                              </span>
                            </div>
                          </.tooltip_content>
                        </.tooltip>
                      <% end %>
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

  defp get_weekly_rankings do
    transactions_query =
      from t in Transaction,
        join: u in Users.User,
        on: t.user_id == u.id,
        where: not is_nil(u.country) and not is_nil(t.succeeded_at),
        group_by: [
          u.id,
          u.country,
          u.handle,
          u.avatar_url,
          fragment("date_trunc('week', ?::timestamp)", t.succeeded_at)
        ],
        select: %{
          user_id: u.id,
          handle: u.handle,
          avatar_url: u.avatar_url,
          country: u.country,
          week: fragment("date_trunc('week', ?::timestamp)", t.succeeded_at),
          total_earned: sum(t.net_amount)
        }

    transactions = Repo.all(transactions_query)

    transactions
    |> Enum.group_by(& &1.week)
    |> Enum.map(fn {week, entries} ->
      rankings =
        entries
        |> Enum.group_by(&Regions.get_region(&1.country))
        |> Enum.reject(fn {region, _} -> is_nil(region) end)
        |> Enum.map(fn {region, region_entries} ->
          total =
            Enum.reduce(region_entries, Money.zero(:USD), fn entry, acc ->
              Money.add!(acc, entry.total_earned)
            end)

          top_earners =
            region_entries
            |> Enum.sort_by(& &1.total_earned, :desc)
            |> Enum.take(5)

          {region, total, top_earners}
        end)
        |> Enum.sort_by(fn {_, total, _} -> total end, :desc)

      {week, rankings}
    end)
    |> Enum.reject(fn {week, _} -> is_nil(week) end)
    |> Enum.sort_by(fn {week, _} -> week end, {:desc, NaiveDateTime})
  end

  defp calculate_medals(weeks) do
    weeks
    |> Enum.reduce(%{}, fn {_week, rankings}, acc ->
      rankings
      |> Enum.take(3)
      |> Enum.with_index(1)
      |> Enum.reduce(acc, fn {{region, _total, _top_earners}, position}, region_acc ->
        region_data = Map.get(region_acc, region, %{gold: 0, silver: 0, bronze: 0, total: 0})

        updated_data =
          case position do
            1 -> Map.update!(region_data, :gold, &(&1 + 1))
            2 -> Map.update!(region_data, :silver, &(&1 + 1))
            3 -> Map.update!(region_data, :bronze, &(&1 + 1))
          end

        updated_data =
          Map.put(
            updated_data,
            :total,
            updated_data.gold * 3 + updated_data.silver * 2 + updated_data.bronze
          )

        Map.put(region_acc, region, updated_data)
      end)
    end)
  end
end
