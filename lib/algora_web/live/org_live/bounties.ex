defmodule AlgoraWeb.OrgLive.Bounties do
  use AlgoraWeb, :live_view

  alias Algora.Bounty

  @impl true
  def mount(%{"handle" => handle}, _session, socket) do
    org = Algora.Accounts.get_user_by!(handle: handle)
    
    # Sync bounty status before displaying
    Bounty.sync_bounty_status()
    
    bounties = Bounty.list_bounties_by_org(org.id)
    
    {:ok,
     socket
     |> assign(:org, org)
     |> assign(:bounties, bounties)
     |> assign(:page_title, "#{org.name} - Bounties")}
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
        <div class="bg-white py-8">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <div class="mx-auto max-w-2xl text-center">
              <h2 class="text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
                <%= @org.name %> Bounties
              </h2>
              <p class="mt-2 text-lg leading-8 text-gray-600">
                Active bounties from <%= @org.name %>
              </p>
            </div>
          </div>
        </div>

        <div class="space-y-6">
          <%= for bounty <- @bounties do %>
            <div class="bg-white overflow-hidden shadow rounded-lg">
              <div class="px-4 py-5 sm:p-6">
                <div class="flex items-center justify-between">
                  <div class="flex-1">
                    <h3 class="text-lg font-medium text-gray-900">
                      <a href={bounty.github_url} target="_blank" class="hover:text-purple-600">
                        <%= bounty.title %>
                      </a>
                    </h3>
                    <p class="mt-1 text-sm text-gray-500">
                      <%= bounty.repo_name %> • Issue #<%= bounty.github_issue_number %>
                    </p>
                    <%= if bounty.description do %>
                      <p class="mt-2 text-sm text-gray-700">
                        <%= bounty.description %>
                      </p>
                    <% end %>
                  </div>
                  <div class="ml-4 flex-shrink-0 flex flex-col items-end">
                    <div class="text-lg font-semibold text-green-600">
                      $<%= bounty.amount %>
                    </div>
                    <div class="mt-1">
                      <span class={[
                        "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                        case bounty.status do
                          "open" -> "bg-green-100 text-green-800"
                          "claimed" -> "bg-yellow-100 text-yellow-800"
                          "completed" -> "bg-blue-100 text-blue-800"
                          "cancelled" -> "bg-red-100 text-red-800"
                          _ -> "bg-gray-100 text-gray-800"
                        end
                      ]}>
                        <%= String.capitalize(bounty.status) %>
                      </span>
                    </div>
                  </div>
                </div>
                
                <div class="mt-4 flex items-center text-sm text-gray-500">
                  <span>Created <%= Calendar.strftime(bounty.inserted_at, "%B %d, %Y") %></span>
                  <%= if bounty.claim_count > 0 do %>
                    <span class="ml-4">
                      <%= bounty.claim_count %> <%= if bounty.claim_count == 1, do: "claim", else: "claims" %>
                    </span>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>

          <%= if @bounties == [] do %>
            <div class="text-center py-12">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <h3 class="mt-2 text-sm font-medium text-gray-900">No bounties</h3>
              <p class="mt-1 text-sm text-gray-500">
                <%= @org.name %> hasn't posted any bounties yet.
              </p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end