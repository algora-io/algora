defmodule AlgoraWeb.HomeLive do
  use AlgoraWeb, :live_view
  import AlgoraWeb.Component.Card
  alias Algora.Accounts

  @impl true
  def mount(_params, _session, socket) do
    # Get featured developer and organizations
    featured_dev = Accounts.list_matching_devs(limit: 1) |> List.first()
    orgs = Accounts.list_orgs(limit: 6)

    socket =
      socket
      |> assign(:featured_dev, featured_dev)
      |> assign(:orgs, orgs)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-20 pb-16">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <!-- Left Column -->
          <div class="space-y-8">
            <h1 class="text-5xl font-bold tracking-tight text-gray-900">
              Hire the <span class="underline decoration-blue-500">Top 3%</span>
              of<br /> Freelance Talent<span class="text-2xl align-super">®</span>
            </h1>

            <p class="text-xl text-gray-600 leading-relaxed">
              Algora is an exclusive network of the top freelance software developers, designers, marketing experts, finance experts, product managers, and project managers in the world. Top companies hire Algora freelancers for their most important projects.
            </p>

            <div>
              <.button class="px-8 py-4 text-lg bg-emerald-500 hover:bg-emerald-600 text-white rounded-md">
                Hire Top Talent
              </.button>
            </div>
          </div>
          <!-- Right Column -->
          <div class="relative">
            <div class="relative">
              <img
                src={@featured_dev.avatar_url}
                alt="Professional"
                class="w-full max-w-lg mx-auto rounded-lg object-cover aspect-[4/3]"
              />
            </div>
            <!-- Floating Card -->
            <.card class="absolute -right-8 -bottom-8 w-72 bg-white shadow-xl z-20">
              <.card_content class="space-y-4">
                <div class="flex items-start gap-4">
                  <div class="flex-1">
                    <h3 class="font-semibold text-gray-900"><%= @featured_dev.name %></h3>
                    <div class="flex items-center gap-2 text-sm text-emerald-600">
                      <.icon name="tabler-check-circle" class="w-4 h-4" />
                      <span>Verified Expert</span>
                    </div>
                    <div class="text-sm text-gray-500 flex items-center gap-2 mt-1">
                      <.icon name="tabler-briefcase" class="w-4 h-4" />
                      <span><%= @featured_dev.projects %> Projects</span>
                    </div>
                  </div>
                </div>

                <div>
                  <p class="text-xs text-gray-500 uppercase">PREVIOUSLY AT</p>
                  <div class="mt-2">
                    <img
                      :if={org = List.first(@orgs)}
                      src={org.avatar_url}
                      alt={org.name}
                      class="h-8"
                    />
                  </div>
                </div>
              </.card_content>
            </.card>
          </div>
        </div>
        <!-- Logos Section -->
        <div class="mt-24">
          <p class="text-center text-gray-600 text-sm font-medium mb-8">
            TRUSTED BY LEADING BRANDS AND STARTUPS
          </p>
          <div class="grid grid-cols-3 md:grid-cols-6 gap-8 items-center justify-items-center opacity-75">
            <%= for org <- @orgs do %>
              <img src={org.avatar_url} alt={org.name} class="h-8 w-8 object-contain" />
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
