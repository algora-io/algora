defmodule AlgoraWeb.OnboardingLive do
  use AlgoraWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, user_type: nil, interest: nil, step: :user_type, matches: nil)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center p-4">
      <div class="bg-white rounded-lg shadow-xl p-8 max-w-md w-full">
        <h1 class="text-3xl font-bold text-center text-gray-800 mb-6">Welcome to Algora</h1>
        <div class="space-y-8">
          <%= case @step do %>
            <% :user_type -> %>
              <h2 class="text-xl font-semibold text-gray-700 mb-4">
                Are you a company or an individual?
              </h2>
              <div class="grid grid-cols-2 gap-4">
                <.onboarding_button text="Company" event="select_user_type" value="company" />
                <.onboarding_button text="Individual" event="select_user_type" value="individual" />
              </div>
            <% :interest -> %>
              <h2 class="text-xl font-semibold text-gray-700 mb-4">What are you looking for?</h2>
              <div class="grid grid-cols-3 gap-4">
                <.onboarding_button text="Bounties" event="select_interest" value="bounties" />
                <.onboarding_button text="Projects" event="select_interest" value="projects" />
                <.onboarding_button text="Jobs" event="select_interest" value="jobs" />
              </div>
            <% :matches -> %>
              <h2 class="text-xl font-semibold text-gray-700 mb-4">Your Matches</h2>
              <p class="text-gray-600 mb-4">
                Based on your selections: <span class="font-medium"><%= @user_type %></span>
                looking for <span class="font-medium"><%= @interest %></span>
              </p>
              <%= if @matches do %>
                <ul class="space-y-4">
                  <%= for match <- @matches do %>
                    <li class="bg-gray-100 rounded-lg p-4 hover:bg-gray-200 transition duration-300">
                      <h3 class="font-semibold text-gray-800"><%= match.name %></h3>
                      <p class="text-gray-600"><%= match.description %></p>
                    </li>
                  <% end %>
                </ul>
              <% else %>
                <p class="text-gray-600 text-center">Loading matches...</p>
              <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def onboarding_button(assigns) do
    ~H"""
    <onboarding_button
      phx-click={@event}
      phx-value-type={@value}
      phx-value-interest={@value}
      class="bg-indigo-500 text-white font-semibold py-2 px-4 rounded-lg hover:bg-indigo-600 transition duration-300 transform hover:scale-105"
    >
      <%= @text %>
    </onboarding_button>
    """
  end

  def handle_event("select_user_type", %{"type" => user_type}, socket) do
    {:noreply, assign(socket, user_type: user_type, step: :interest)}
  end

  def handle_event("select_interest", %{"interest" => interest}, socket) do
    {:noreply,
     socket
     |> assign(interest: interest, step: :matches)
     |> fetch_matches()}
  end

  defp fetch_matches(%{assigns: %{user_type: user_type, interest: interest}} = socket) do
    # Placeholder implementation
    matches = [
      %{
        name: "Innovative Tech Co.",
        description: "Seeking talented individuals for exciting projects"
      },
      %{
        name: "Global Solutions Inc.",
        description: "Offering competitive bounties for skilled developers"
      }
    ]

    assign(socket, matches: matches)
  end
end
