defmodule AlgoraWeb.Admin.CompanyAnalyticsLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.Activity

  alias Algora.Activities
  alias Algora.Analytics

  def mount(_params, _session, socket) do
    {:ok, analytics} = Analytics.get_company_analytics()
    funnel_data = Analytics.get_funnel_data()
    :ok = Activities.subscribe()

    {:ok,
     socket
     |> assign(:analytics, analytics)
     |> assign(:funnel_data, funnel_data)
     |> assign(:selected_period, "30d")
     |> stream(:activities, [])
     |> start_async(:get_activities, fn -> Activities.all() end)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-8 p-8">
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold">Company Analytics</h1>
        <div class="flex gap-2">
          <.button
            :for={period <- ["7d", "30d", "90d"]}
            variant={if @selected_period == period, do: "default", else: "outline"}
            phx-click="select_period"
            phx-value-period={period}
          >
            {period}
          </.button>
        </div>
      </div>

      <div class="mx-auto h-500 flex">
        <div class="w-3/4 p-0">
          <.card>
            <.card_header>
              <.card_title>Company Funnel</.card_title>
            </.card_header>
            <.card_content>
              <div class="h-[400px]" phx-update="ignore" id="funnel-chart">
                <canvas id="funnelChart"></canvas>
              </div>
            </.card_content>
          </.card>
        </div>
        <.scroll_area class="w-1/4 ml-4 pr-4">
          <.card class="h-[500px]">
            <.card_header>
              <.card_title>Recent Activities</.card_title>
            </.card_header>
            <.activities_timeline id="admin-activities-timeline" activities={@streams.activities} />
          </.card>
        </.scroll_area>
      </div>
      <!-- Key Metrics -->
      <div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
        <.stat_card
          title="Total Companies"
          value={@analytics.total_companies}
          change={@analytics.companies_change}
          trend={@analytics.companies_trend}
        />
        <.stat_card
          title="Active Companies"
          value={@analytics.active_companies}
          change={@analytics.active_change}
          trend={@analytics.active_trend}
        />
        <.stat_card
          title="Avg Time to Fill"
          value={"#{@analytics.avg_time_to_fill}d"}
          change={@analytics.time_to_fill_change}
          trend={@analytics.time_to_fill_trend}
        />
        <.stat_card
          title="Contract Success Rate"
          value={"#{@analytics.contract_success_rate}%"}
          change={@analytics.success_rate_change}
          trend={@analytics.success_rate_trend}
        />
      </div>
      <!-- Company Table -->
      <.card>
        <.card_header>
          <.card_title>Company Details</.card_title>
        </.card_header>
        <.card_content>
          <div class="overflow-x-auto">
            <table class="w-full">
              <thead>
                <tr class="border-b border-border">
                  <th class="p-4 text-left">Company</th>
                  <th class="p-4 text-left">Joined</th>
                  <th class="p-4 text-left">Status</th>
                  <th class="p-4 text-left">Contracts</th>
                  <th class="p-4 text-left">Success Rate</th>
                  <th class="p-4 text-left">Last Active</th>
                </tr>
              </thead>
              <tbody>
                <%= for company <- @analytics.companies do %>
                  <tr class="border-b border-border">
                    <td class="p-4">
                      <div class="flex items-center gap-3">
                        <.avatar class="h-8 w-8">
                          <.avatar_image src={company.avatar_url} />
                        </.avatar>
                        <div>
                          <div class="font-medium">{company.name}</div>
                          <div class="text-sm text-muted-foreground">@{company.handle}</div>
                        </div>
                      </div>
                    </td>
                    <td class="p-4 text-sm">
                      {Calendar.strftime(company.joined_at, "%b %d, %Y")}
                    </td>
                    <td class="p-4">
                      <.badge variant={status_color(company.status)}>
                        {company.status}
                      </.badge>
                    </td>
                    <td class="p-4 text-sm">
                      {company.total_contracts}
                    </td>
                    <td class="p-4 text-sm">
                      {company.success_rate}%
                    </td>
                    <td class="p-4 text-sm text-muted-foreground">
                      {Calendar.strftime(company.last_active_at, "%b %d, %Y")}
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </.card_content>
      </.card>
    </div>
    """
  end

  def status_color(:active), do: "success"
  def status_color(:pending), do: "warning"
  def status_color(_), do: "secondary"

  def handle_event("select_period", %{"period" => period}, socket) do
    {:ok, analytics} = Analytics.get_company_analytics(period)
    funnel_data = Analytics.get_funnel_data(period)

    {:noreply,
     socket
     |> assign(:analytics, analytics)
     |> assign(:funnel_data, funnel_data)
     |> assign(:selected_period, period)}
  end

  def handle_async(:get_activities, {:ok, fetched}, socket) do
    {:noreply, stream(socket, :activities, fetched)}
  end

  def handle_info(%Activities.Activity{} = activity, socket) do
    {:noreply, stream_insert(socket, :activities, activity, at: 0)}
  end
end
