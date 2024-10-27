defmodule AlgoraWeb.User.DashboardLive do
  use AlgoraWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="text-white p-6">
      <h1 class="text-4xl font-handwriting mb-8">Get started</h1>

      <div class="grid grid-cols-4 gap-6 mb-12">
        <%= for card <- @get_started_cards do %>
          <div class={[
            "bg-white/5 rounded-lg p-6 relative",
            card.active && "bg-white/10 cursor-pointer group",
            !card.active && "cursor-not-allowed opacity-70"
          ]}>
            <h2 class="text-xl font-semibold mb-4"><%= card.title %></h2>
            <%= for paragraph <- card.paragraphs do %>
              <p class="text-sm mb-2 text-gray-300"><%= paragraph %></p>
            <% end %>
            <div class="absolute bottom-4 right-6 text-3xl group-hover:translate-x-2 transition-transform">
              &rarr;
            </div>
          </div>
        <% end %>
      </div>

      <h2 class="text-3xl font-handwriting mb-6">Your matches</h2>

      <div class="flex gap-6 mb-8">
        <div class="flex items-center">
          <span class="mr-2">Tech stack:</span>
          <%= for tech <- @tech_stack do %>
            <span class="bg-gray-700 text-sm rounded-full px-3 py-1 mr-2"><%= tech %></span>
          <% end %>
        </div>

        <div class="flex items-center">
          <span class="mr-2">Location:</span>
          <%= for location <- @locations do %>
            <span class="bg-gray-700 text-sm rounded-full px-3 py-1 mr-2"><%= location %></span>
          <% end %>
        </div>
      </div>

      <div class="grid grid-cols-4 gap-6">
        <%= for match <- @matches do %>
          <div class="bg-gray-800 rounded-lg p-4 flex flex-col h-full relative">
            <div class="absolute top-2 right-2 text-xl">
              <%= match.flag %>
            </div>
            <div class="flex items-center mb-4">
              <img
                src={match.avatar_url}
                alt={match.name}
                class="w-12 h-12 rounded-full mr-3 object-cover"
              />
              <div>
                <div class="font-semibold"><%= match.name %></div>
                <div class="text-sm text-gray-400">@<%= match.handle %></div>
              </div>
            </div>
            <div class="text-sm mb-2"><%= Enum.join(match.skills, ", ") %></div>
            <div class="text-sm mb-4 mt-auto">
              $<%= match.amount %> earned (<%= match.bounties %> bounties, <%= match.projects %> projects)
            </div>
            <button class="w-full border border-dashed border-white text-sm py-2 rounded hover:bg-gray-700 transition-colors">
              Collaborate
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        get_started_cards: get_started_cards(),
        tech_stack: ["Elixir", "TypeScript"],
        locations: ["United Kingdom", "Remote"],
        matches: Algora.Accounts.list_matching_devs(limit: 8, country: "GB")
      )

    {:ok, socket}
  end

  defp get_started_cards do
    [
      %{
        title: "Set up your organization",
        paragraphs: [
          "Invite your teammates and meet new ones, manage work and make payments.",
          "We'll keep a record and help you stay compliant as you grow your business."
        ],
        active: true
      },
      %{
        title: "Create bounties",
        paragraphs: [
          "Install Algora in your GitHub repo(s), use the Algora commands in issues and pull requests, and reward bounties without leaving GitHub.",
          "You can share your bounty board with anyone and toggle bounties between private & public."
        ],
        active: false
      },
      %{
        title: "Create projects",
        paragraphs: [
          "Get matched with top developers, manage contract work and make payments globally.",
          "You can share projects with anyone and pay on hourly, fixed, milestone or bounty basis."
        ],
        active: false
      },
      %{
        title: "Create jobs",
        paragraphs: [
          "Find new teammates, manage applicants and simplify contract-to-hire.",
          "You can use your job board and ATS privately as well as publish jobs on Algora."
        ],
        active: false
      }
    ]
  end
end
