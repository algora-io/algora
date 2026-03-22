defmodule AlgoraWeb.OrgBountyLive do
  use AlgoraWeb, :live_view

  alias Algora.{Bounties, Library}

  @impl true
  def mount(%{"org_handle" => org_handle}, _session, socket) do
    org = Library.get_org_by_handle!(org_handle)
    
    bounties = Bounties.list_org_bounties_with_github_status(org.id)
    
    {:ok, assign(socket, org: org, bounties: bounties)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "#{socket.assigns.org.name} - Bounties")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-3xl">
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-gray-900">
            <%= @org.name %> Bounties
          </h1>
          <p class="mt-2 text-gray-600">
            Open bounties for <%= @org.name %>
          </p>
        </div>

        <div class="space-y-6">
          <%= for bounty <- @bounties do %>
            <div class="bg-white shadow rounded-lg p-6">
              <div class="flex items-start justify-between">
                <div class="flex-1">
                  <h3 class="text-lg font-semibold text-gray-900">
                    <%= bounty.title %>
                  </h3>
                  <p class="mt-2 text-gray-600">
                    <%= bounty.description %>
                  </p>
                  <div class="mt-4 flex items-center space-x-4 text-sm text-gray-500">
                    <span class={[
                      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                      bounty_status_class(bounty.github_issue_status)
                    ]}>
                      <%= format_status(bounty.github_issue_status) %>
                    </span>
                    <span>
                      <%= bounty.claim_count %> claim<%= if bounty.claim_count != 1, do: "s" %>
                    </span>
                    <span>
                      $<%= bounty.reward_amount %>
                    </span>
                  </div>
                </div>
                <div class="ml-4">
                  <.link
                    navigate={~p"/bounties/#{bounty.id}"}
                    class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                  >
                    View Details
                  </.link>
                </div>
              </div>
            </div>
          <% end %>

          <%= if @bounties == [] do %>
            <div class="text-center py-12">
              <h3 class="text-lg font-medium text-gray-900">No bounties found</h3>
              <p class="mt-2 text-gray-500">
                <%= @org.name %> hasn't posted any bounties yet.
              </p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp bounty_status_class("open"), do: "bg-green-100 text-green-800"
  defp bounty_status_class("closed"), do: "bg-red-100 text-red-800"
  defp bounty_status_class(_), do: "bg-gray-100 text-gray-800"

  defp format_status("open"), do: "Open"
  defp format_status("closed"), do: "Closed"
  defp format_status(_), do: "Unknown"
end