defmodule AlgoraWeb.SwiftBountiesLive do
  use AlgoraWeb, :live_view

  def mount(_params, _session, socket) do
    # Hardcoded data for demonstration
    active_bounties = [
      %{
        project: "Swift NIO",
        title: "Memory leak in HTTP2 handler",
        amount: Money.new(2400, :USD),
        backers: 6
      },
      %{
        project: "Swift Collections",
        title: "Add B-tree implementation",
        amount: Money.new(1800, :USD),
        backers: 4
      },
      %{
        project: "Swift Crypto",
        title: "ECDSA signing performance",
        amount: Money.new(900, :USD),
        backers: 2
      }
    ]

    recent_activity = [
      %{
        type: :tip,
        from: "@sarah",
        to: "@dave",
        amount: Money.new(50, :USD),
        description: "fixing Swift Package Manager tests"
      },
      %{
        type: :bounty,
        from: "@company123",
        amount: Money.new(500, :USD),
        description: "Swift DocC improvements"
      },
      %{
        type: :contribution,
        from: "@swift_fan",
        amount: Money.new(100, :USD),
        description: "SwiftUI navigation bounty"
      }
    ]

    {:ok,
     socket
     |> assign(:page_title, "Swift Bounties")
     |> assign(:active_bounties, active_bounties)
     |> assign(:recent_activity, recent_activity)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-background">
      <div class="container max-w-6xl mx-auto px-6 py-12 space-y-12">
        <!-- Hero Section -->
        <div class="text-center space-y-4">
          <h1 class="text-4xl font-bold tracking-tight">Swift Bounties</h1>
          <p class="text-xl text-muted-foreground max-w-2xl mx-auto">
            The Swift ecosystem needs sustainable funding for "middle ring" infrastructure - projects that are too niche for Apple but too broad for a single company.
          </p>
          <div class="flex justify-center gap-4 pt-4">
            <.button size="lg">Connect GitHub</.button>
            <.button size="lg" variant="outline">View All Bounties</.button>
          </div>
        </div>
        
    <!-- How It Works -->
        <.card class="bg-card">
          <.card_header>
            <.card_title>How It Works</.card_title>
          </.card_header>
          <.card_content>
            <div class="grid md:grid-cols-3 gap-6">
              <div class="space-y-2">
                <.icon name="tabler-git-pull-request" class="h-8 w-8 text-primary" />
                <h3 class="font-semibold">Post Bounties</h3>
                <p class="text-sm text-muted-foreground">
                  Anyone can post bounties on any issue in any Swift repository
                </p>
              </div>
              <div class="space-y-2">
                <.icon name="tabler-users" class="h-8 w-8 text-primary" />
                <h3 class="font-semibold">Pool Funds</h3>
                <p class="text-sm text-muted-foreground">
                  Multiple people can contribute to the same bounty
                </p>
              </div>
              <div class="space-y-2">
                <.icon name="tabler-coin" class="h-8 w-8 text-primary" />
                <h3 class="font-semibold">Pay Out</h3>
                <p class="text-sm text-muted-foreground">
                  Pay only when the work is completed and merged
                </p>
              </div>
            </div>
          </.card_content>
        </.card>
        
    <!-- Active Bounties -->
        <.card>
          <.card_header class="flex justify-between">
            <.card_title>Active Bounties</.card_title>
          </.card_header>
          <.card_content>
            <div class="-mx-6 overflow-x-auto">
              <table class="w-full">
                <thead>
                  <tr class="border-b">
                    <th class="px-6 py-3 text-left text-sm font-medium">Project</th>
                    <th class="px-6 py-3 text-left text-sm font-medium">Issue</th>
                    <th class="px-6 py-3 text-left text-sm font-medium">Amount</th>
                    <th class="px-6 py-3 text-left text-sm font-medium">Contributors</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for bounty <- @active_bounties do %>
                    <tr class="border-b hover:bg-muted/50">
                      <td class="px-6 py-4 text-sm">{bounty.project}</td>
                      <td class="px-6 py-4 text-sm">{bounty.title}</td>
                      <td class="px-6 py-4 text-sm font-semibold text-success">
                        {Money.to_string!(bounty.amount)}
                      </td>
                      <td class="px-6 py-4 text-sm">{bounty.backers} backers</td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
            <div class="pt-4 flex justify-center">
              <.button variant="ghost" phx-click="load_more">
                <.icon name="tabler-arrow-down" class="w-4 h-4 mr-2" /> Load More
              </.button>
            </div>
          </.card_content>
        </.card>
        
    <!-- Recent Activity -->
        <.card>
          <.card_header>
            <.card_title>Recent Activity</.card_title>
          </.card_header>
          <.card_content>
            <div class="space-y-4">
              <%= for activity <- @recent_activity do %>
                <div class="flex items-center gap-4">
                  <div class="h-9 w-9 rounded-full bg-primary/10 flex items-center justify-center">
                    <.icon
                      name={
                        case activity.type do
                          :tip -> "tabler-coin"
                          :bounty -> "tabler-gift"
                          :contribution -> "tabler-plus"
                        end
                      }
                      class="h-5 w-5 text-primary"
                    />
                  </div>
                  <div class="flex-1">
                    <p class="text-sm">
                      <span class="font-medium">{activity.from}</span>
                      <%= case activity.type do %>
                        <% :tip -> %>
                          tipped <span class="font-medium">{activity.to}</span>
                          <span class="font-medium text-success">
                            {Money.to_string!(activity.amount)}
                          </span>
                          for {activity.description}
                        <% :bounty -> %>
                          posted
                          <span class="font-medium text-success">
                            {Money.to_string!(activity.amount)}
                          </span>
                          bounty for {activity.description}
                        <% :contribution -> %>
                          added
                          <span class="font-medium text-success">
                            {Money.to_string!(activity.amount)}
                          </span>
                          to existing {activity.description}
                      <% end %>
                    </p>
                  </div>
                </div>
              <% end %>
            </div>
          </.card_content>
        </.card>
      </div>
    </div>
    """
  end
end
