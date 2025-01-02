defmodule AlgoraWeb.Org.CreateLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Users

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
     |> assign(matching_orgs: Users.list_orgs(limit: 5))}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-950 text-white sm:flex">
      <div class="flex-grow p-8 max-w-3xl mx-auto">
        <div class="mb-8">
          <div class="space-y-8">
            <h2 class="text-4xl font-semibold text-white">
              Create Your Organization
            </h2>

            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-300 mb-1">Organization Name</label>
                <input
                  id="name"
                  type="text"
                  name="name"
                  value={@org.name}
                  phx-blur="update_org"
                  phx-hook="DeriveHandle"
                  phx-value-field="name"
                  placeholder="Acme Inc."
                  class="w-full p-4 bg-gray-900 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-300 mb-1">Handle</label>
                <input
                  type="text"
                  name="handle"
                  value={@org.handle}
                  phx-blur="update_org"
                  phx-value-field="handle"
                  data-handle-target
                  placeholder="acme"
                  class="w-full p-4 bg-gray-900 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-300 mb-1">Email Domain</label>
                <input
                  type="text"
                  name="email_domain"
                  value={@org.email_domain}
                  phx-blur="update_org"
                  phx-value-field="email_domain"
                  placeholder="example.com"
                  class="w-full p-4 bg-gray-900 border border-gray-700 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
            </div>
          </div>
        </div>
        <div class="flex justify-between">
          <button
            phx-click="submit"
            class="bg-gray-100 hover:bg-gray-200 text-gray-900 font-bold py-2 px-4 rounded"
          >
            Create
          </button>
        </div>
      </div>
      <div class="font-display sm:w-1/3 border-l-2 border-gray-800 bg-gradient-to-b from-white/[5%] to-white/[2.5%] px-8 py-4 overflow-y-auto sm:max-h-screen">
        <h2 class="text-lg text-gray-200 font-display font-semibold uppercase mb-4">
          You're in good company
        </h2>
        <%= if @matching_orgs == [] do %>
          <p class="text-gray-400">Add tech_stack to see similar organizations</p>
        <% else %>
          <%= for org <- @matching_orgs do %>
            <div class="mb-4 bg-white/[7.5%] p-4 rounded-lg">
              <div class="flex mb-2 gap-3">
                <img src={org.avatar_url} alt={org.name} class="w-24 h-24 rounded-full mr-3" />
                <div class="flex-grow">
                  <div class="flex justify-between">
                    <div>
                      <div class="font-semibold">{org.name} {org.flag}</div>
                      <div class="text-sm text-gray-400">@{org.handle}</div>
                    </div>
                    <div class="flex flex-col items-end">
                      <div class="text-gray-300">Awarded</div>
                      <div class="text-white font-semibold">
                        {Money.to_string!(org.amount)}
                      </div>
                    </div>
                  </div>

                  <div class="pt-3 text-sm">
                    <div class="-ml-1 text-sm flex flex-wrap gap-1">
                      <%= for tech_stack <- org.tech_stack do %>
                        <span class="text-white rounded-xl px-2 py-0.5 text-sm ring-1 ring-white/20">
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
