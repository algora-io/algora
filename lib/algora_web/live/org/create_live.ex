defmodule AlgoraWeb.Org.CreateLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Accounts.User

  def mount(_params, session, socket) do
    org = %{
      name: "",
      handle: "",
      email_domain: "",
      country: socket.assigns.current_country,
      tech_stack: ["Elixir"]
    }

    {:ok,
     socket
     |> assign(org: org)
     |> assign(current_user: %{email: session["user_email"]})
     |> assign(matching_orgs: Accounts.list_orgs(limit: 5))}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-950 text-white sm:flex">
      <div class="mx-auto max-w-3xl flex-grow p-8">
        <div class="mb-8">
          <div class="space-y-8">
            <h2 class="text-4xl font-semibold text-white">
              Create Your Organization
            </h2>

            <div class="space-y-4">
              <div>
                <label class="mb-1 block text-sm font-medium text-gray-300">Organization Name</label>
                <input
                  id="name"
                  type="text"
                  name="name"
                  value={@org.name}
                  phx-blur="update_org"
                  phx-hook="DeriveHandle"
                  phx-value-field="name"
                  placeholder="Acme Inc."
                  class="w-full rounded-lg border border-gray-700 bg-gray-900 p-4 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              <div>
                <label class="mb-1 block text-sm font-medium text-gray-300">Handle</label>
                <input
                  type="text"
                  name="handle"
                  value={@org.handle}
                  phx-blur="update_org"
                  phx-value-field="handle"
                  data-handle-target
                  placeholder="acme"
                  class="w-full rounded-lg border border-gray-700 bg-gray-900 p-4 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              <div>
                <label class="mb-1 block text-sm font-medium text-gray-300">Email Domain</label>
                <input
                  type="text"
                  name="email_domain"
                  value={@org.email_domain}
                  phx-blur="update_org"
                  phx-value-field="email_domain"
                  placeholder="example.com"
                  class="w-full rounded-lg border border-gray-700 bg-gray-900 p-4 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
            </div>
          </div>
        </div>
        <div class="flex justify-between">
          <button
            phx-click="submit"
            class="rounded bg-gray-100 px-4 py-2 font-bold text-gray-900 hover:bg-gray-200"
          >
            Create
          </button>
        </div>
      </div>
      <div class="font-display from-white/[5%] to-white/[2.5%] overflow-y-auto border-l-2 border-gray-800 bg-gradient-to-b px-8 py-4 sm:max-h-screen sm:w-1/3">
        <h2 class="font-display mb-4 text-lg font-semibold uppercase text-gray-200">
          You're in good company
        </h2>
        <%= if @matching_orgs == [] do %>
          <p class="text-gray-400">Add tech_stack to see similar organizations</p>
        <% else %>
          <%= for org <- @matching_orgs do %>
            <div class="bg-white/[7.5%] mb-4 rounded-lg p-4">
              <div class="mb-2 flex gap-3">
                <img src={org.avatar_url} alt={org.name} class="mr-3 h-24 w-24 rounded-full" />
                <div class="flex-grow">
                  <div class="flex justify-between">
                    <div>
                      <div class="font-semibold">{org.name} {org.flag}</div>
                      <div class="text-sm text-gray-400">@{User.handle(org)}</div>
                    </div>
                    <div class="flex flex-col items-end">
                      <div class="text-gray-300">Awarded</div>
                      <div class="font-semibold text-white">
                        {Money.to_string!(org.amount)}
                      </div>
                    </div>
                  </div>

                  <div class="pt-3 text-sm">
                    <div class="-ml-1 flex flex-wrap gap-1 text-sm">
                      <%= for tech_stack <- org.tech_stack do %>
                        <span class="rounded-xl px-2 py-0.5 text-sm text-white ring-1 ring-white/20">
                          {tech_stack}
                        </span>
                      <% end %>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("submit", _, socket) do
    # Handle job submission
    {:noreply, socket}
  end

  def handle_event("update_org", %{"field" => field, "value" => value}, socket) do
    updated_org = Map.put(socket.assigns.org, String.to_atom(field), value)
    {:noreply, assign(socket, org: updated_org)}
  end
end
