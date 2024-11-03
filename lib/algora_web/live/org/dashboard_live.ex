defmodule AlgoraWeb.Org.DashboardLive do
  use AlgoraWeb, :live_view

  alias Algora.Bounties
  alias Algora.Money
  alias AlgoraWeb.Org.Forms.BountyForm
  alias Algora.Accounts

  def mount(_params, _session, socket) do
    recent_bounties = Bounties.list_bounties(limit: 10)
    matching_devs = Accounts.list_matching_devs(org_id: socket.assigns.current_org.id, limit: 5)

    changeset =
      %BountyForm{}
      |> BountyForm.changeset(%{
        payment_type: "fixed",
        currency: "USD"
      })

    {:ok,
     socket
     |> assign(:recent_bounties, recent_bounties)
     |> assign(:matching_devs, matching_devs)
     |> assign(:selected_dev, nil)
     |> assign(:show_dev_drawer, false)
     |> assign_form(changeset)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 p-4 pt-6 sm:p-6 md:p-8 max-w-5xl mx-auto">
      <div class="p-6 relative rounded-lg border bg-card text-card-foreground md:gap-8 h-full">
        <div class="flex justify-between">
          <h2 class="text-2xl font-semibold mb-6">Create New Bounty</h2>
          <.button type="submit" phx-disable-with="Creating..." size="sm">
            Create bounty
          </.button>
        </div>
        <.simple_form for={@form} phx-change="validate" phx-submit="create_bounty" class="space-y-6">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <.label for="title" class="text-sm font-medium mb-2">
                Title
              </.label>
              <.input
                type="text"
                field={@form[:title]}
                placeholder="Brief description of the task"
                required
                class="w-full bg-background border-input rounded-lg"
              />
            </div>
            <div>
              <.label for="task_url" class="text-sm font-medium mb-2">
                Ticket
                <span class="font-normal text-muted-foreground  ">
                  (GitHub, Linear, Figma, Jira, Google Docs...)
                </span>
              </.label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                  <.icon
                    name={get_url_icon(@form[:task_url].value)}
                    class="w-5 h-5 text-muted-foreground"
                  />
                </div>
                <.input
                  type="url"
                  field={@form[:task_url]}
                  placeholder="https://github.com/owner/repo/issues/123"
                  required
                  class="w-full pl-10 bg-background border-input rounded-lg"
                />
              </div>
            </div>
          </div>

          <fieldset class="mb-8">
            <legend class="text-sm font-medium text-foreground mb-2">Payment Type</legend>
            <div class="mt-1 grid grid-cols-1 gap-y-6 sm:grid-cols-2 sm:gap-x-4">
              <label class={"relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none #{if @form[:payment_type].value == "fixed", do: 'border-primary ring-2 ring-primary bg-background', else: 'border-input bg-background/75'}"}>
                <input
                  type="radio"
                  name="bounty_form[payment_type]"
                  value="fixed"
                  checked={@form[:payment_type].value == "fixed"}
                  class="sr-only"
                />
                <span class="flex flex-1 flex-col">
                  <span class="flex items-center mb-1">
                    <span class="block text-sm font-medium text-foreground">Fixed Amount</span>
                    <svg
                      class={"ml-2 h-5 w-5 text-primary #{if @form[:payment_type].value != "fixed", do: 'invisible'}"}
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </span>
                  <span class="mt-1 text-sm text-muted-foreground">
                    Pay upon full completion or reward milestones
                  </span>

                  <div class={"mt-3 transition-opacity duration-200 #{if @form[:payment_type].value != "fixed", do: 'opacity-0 h-0 overflow-hidden', else: 'opacity-100'}"}>
                    <div class="relative">
                      <.input
                        field={@form[:amount]}
                        min="1"
                        step="0.01"
                        placeholder="$1,000"
                        required={@form[:payment_type].value == "fixed"}
                        class="font-display w-full py-1.5 bg-background border-input rounded-lg text-sm text-success font-medium"
                      />
                      <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                        <span class="text-muted-foreground text-sm">USD</span>
                      </div>
                    </div>
                  </div>
                </span>
              </label>

              <label class={"relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none #{if @form[:payment_type].value == "hourly", do: 'border-primary ring-2 ring-primary bg-background', else: 'border-input bg-background/75'}"}>
                <input
                  type="radio"
                  name="bounty_form[payment_type]"
                  value="hourly"
                  checked={@form[:payment_type].value == "hourly"}
                  class="sr-only"
                />
                <span class="flex flex-1 flex-col">
                  <span class="flex items-center mb-1">
                    <span class="block text-sm font-medium text-foreground">Hourly Rate</span>
                    <svg
                      class={"ml-2 h-5 w-5 text-primary #{if @form[:payment_type].value != "hourly", do: 'invisible'}"}
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </span>
                  <span class="mt-1 text-sm text-muted-foreground">
                    Pay as you go based on hours worked
                  </span>

                  <div class={"mt-3 transition-opacity duration-200 #{if @form[:payment_type].value != "hourly", do: 'opacity-0 h-0 overflow-hidden', else: 'opacity-100'}"}>
                    <div class="grid grid-cols-2 gap-2">
                      <div class="relative">
                        <.input
                          field={@form[:amount]}
                          min="1"
                          step="0.01"
                          placeholder="$75"
                          required={@form[:payment_type].value == "hourly"}
                          class="font-display w-full py-1.5 bg-background border-input rounded-lg text-sm text-success font-medium"
                        />
                        <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                          <span class="text-muted-foreground text-sm">USD/h</span>
                        </div>
                      </div>
                      <div class="relative">
                        <.input
                          field={@form[:expected_hours]}
                          min="1"
                          step="1"
                          placeholder="10"
                          required={@form[:payment_type].value == "hourly"}
                          class="font-display w-full py-1.5 bg-background border-input rounded-lg text-sm"
                        />
                        <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                          <span class="text-muted-foreground text-sm">hours per week</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </span>
              </label>
            </div>
          </fieldset>

          <fieldset class="mb-8">
            <legend class="text-sm font-medium text-foreground mb-2">Share Bounty With</legend>
            <div class="mt-1 grid grid-cols-1 gap-y-6 sm:grid-cols-2 sm:gap-x-4">
              <label class={"relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none #{if @form[:sharing_type].value == "private", do: 'border-primary ring-2 ring-primary bg-background', else: 'border-input bg-background/75'}"}>
                <input
                  type="radio"
                  name="bounty_form[sharing_type]"
                  value="private"
                  checked={@form[:sharing_type].value == "private"}
                  class="sr-only"
                />
                <span class="flex flex-1 flex-col">
                  <span class="flex items-center mb-1">
                    <span class="block text-sm font-medium text-foreground">Private Share</span>
                    <svg
                      class={"ml-2 h-5 w-5 text-primary #{if @form[:sharing_type].value != "private", do: 'invisible'}"}
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </span>
                  <span class="mt-1 text-sm text-muted-foreground">
                    Share with specific people via email or link
                  </span>

                  <div class={"mt-3 space-y-3 transition-opacity duration-200 #{if @form[:sharing_type].value != "private", do: 'opacity-0 h-0 overflow-hidden', else: 'opacity-100'}"}>
                    <div class="relative">
                      <.input
                        type="text"
                        field={@form[:share_emails]}
                        placeholder="email1@example.com, email2@example.com"
                        class="w-full bg-background border-input rounded-lg"
                      />
                      <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                        <.icon name="tabler-mail" class="w-5 h-5 text-muted-foreground" />
                      </div>
                    </div>
                    <div class="relative">
                      <.input
                        type="text"
                        field={@form[:share_url]}
                        value="https://algora.io/bounties/share/abc123"
                        readonly
                        class="w-full bg-background/50 border-input rounded-lg cursor-pointer"
                      />
                      <div class="absolute inset-y-0 right-0 flex items-center pr-3">
                        <button type="button" class="text-muted-foreground hover:text-foreground">
                          <.icon name="tabler-copy" class="w-5 h-5" />
                        </button>
                      </div>
                    </div>
                  </div>
                </span>
              </label>

              <label class={"relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none #{if @form[:sharing_type].value == "platform", do: 'border-primary ring-2 ring-primary bg-background', else: 'border-input bg-background/75'}"}>
                <input
                  type="radio"
                  name="bounty_form[sharing_type]"
                  value="platform"
                  checked={@form[:sharing_type].value == "platform"}
                  class="sr-only"
                />
                <span class="flex flex-1 flex-col">
                  <span class="flex items-center mb-1">
                    <span class="block text-sm font-medium text-foreground">Platform</span>
                    <svg
                      class={"ml-2 h-5 w-5 text-primary #{if @form[:sharing_type].value != "platform", do: 'invisible'}"}
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </span>
                  <span class="mt-1 text-sm text-muted-foreground">
                    Share with all platform users
                  </span>
                </span>
              </label>
            </div>
          </fieldset>
        </.simple_form>
      </div>

      <div class="mt-8 p-6 relative rounded-lg border bg-card text-card-foreground">
        <div class="flex justify-between mb-6">
          <div class="flex flex-col space-y-1.5">
            <h2 class="text-2xl font-semibold leading-none tracking-tight">Applicants</h2>
            <p class="text-sm text-muted-foreground">
              Developers interested in freelancing with you
            </p>
          </div>
        </div>

        <div class="relative w-full overflow-auto">
          <table class="w-full caption-bottom text-sm">
            <thead class="[&_tr]:border-b">
              <tr class="border-b transition-colors hover:bg-muted/50">
                <th class="h-12 px-4 text-left align-middle font-medium text-muted-foreground">
                  Developer
                </th>
                <th class="h-12 px-4 text-left align-middle font-medium text-muted-foreground">
                  Skills
                </th>
                <th class="h-12 px-4 text-right align-middle font-medium text-muted-foreground">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="[&_tr:last-child]:border-0">
              <%= for dev <- @matching_devs do %>
                <tr class="border-b transition-colors hover:bg-muted/50">
                  <td class="p-4 align-middle">
                    <div class="flex items-center gap-3">
                      <span class="relative flex h-10 w-10 shrink-0 overflow-hidden rounded-full">
                        <img class="aspect-square h-full w-full" alt={dev.name} src={dev.avatar_url} />
                      </span>
                      <div class="flex flex-col">
                        <div class="flex items-center gap-2">
                          <span class="font-medium"><%= dev.name %></span>
                          <%= if dev.flag do %>
                            <span><%= dev.flag %></span>
                          <% end %>
                        </div>
                        <span class="text-sm text-muted-foreground">@<%= dev.handle %></span>
                      </div>
                    </div>
                  </td>
                  <td class="p-4 align-middle">
                    <div class="space-y-2">
                      <div class="-ml-2.5 flex flex-wrap gap-1">
                        <%= for skill <- Enum.take(dev.skills, 3) do %>
                          <span class="inline-flex items-center rounded-md border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 border-transparent bg-secondary text-secondary-foreground">
                            <%= skill %>
                          </span>
                        <% end %>
                        <%= if length(dev.skills) > 3 do %>
                          <span class="inline-flex items-center rounded-md px-2.5 py-0.5 text-xs text-muted-foreground">
                            +<%= length(dev.skills) - 3 %> more
                          </span>
                        <% end %>
                      </div>
                      <div class="flex items-center gap-4 text-sm text-muted-foreground">
                        <div class="flex items-center gap-1">
                          <.icon name="tabler-diamond" class="w-4 h-4" />
                          <span><%= dev.bounties %> bounties</span>
                        </div>
                        <div class="flex items-center gap-1">
                          <.icon name="tabler-cash" class="w-4 h-4" />
                          <span><%= Money.format!(dev.amount, "USD") %></span>
                        </div>
                      </div>
                    </div>
                  </td>
                  <td class="p-4 align-middle text-right">
                    <.button phx-click="view_dev" phx-value-id={dev.id} size="sm" variant="default">
                      View Profile
                    </.button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>

      <div class="mt-8">
        <.bounties_card current_org={@current_org} bounties={@recent_bounties} />
      </div>

      <div
        class={"fixed inset-0 bg-black/90 z-50 transition-all duration-300 #{if @show_dev_drawer, do: "opacity-100", else: "opacity-0 pointer-events-none"}"}
        phx-click="close_drawer"
      >
        <div
          class={"fixed inset-x-0 bottom-0 z-50 h-[72vh] rounded-t-xl bg-background border-t transform transition-transform duration-300 ease-in-out #{if @show_dev_drawer, do: "translate-y-0", else: "translate-y-full"}"}
          phx-click-away="close_drawer"
        >
          <%= if @selected_dev do %>
            <div class="flex flex-col relative h-full p-6">
              <!-- Drawer Header -->
              <div class="flex justify-between items-start">
                <div class="flex items-start gap-4">
                  <img src={@selected_dev.avatar_url} alt="" class="w-20 h-20 rounded-full" />
                  <div>
                    <h4 class="text-xl font-semibold">
                      <%= @selected_dev.name %> <%= @selected_dev.flag %>
                    </h4>
                    <div class="text-sm text-muted-foreground">
                      @<%= @selected_dev.handle %>
                    </div>
                    <div class="-ml-1 mt-2 flex flex-wrap gap-2">
                      <%= for skill <- @selected_dev.skills do %>
                        <span class="rounded-lg px-2 py-0.5 text-xs ring-1 ring-border bg-secondary">
                          <%= skill %>
                        </span>
                      <% end %>
                    </div>
                  </div>
                </div>
                <button phx-click="close_drawer" class="text-muted-foreground hover:text-foreground">
                  <.icon name="tabler-x" class="w-5 h-5" />
                </button>
              </div>
              <!-- Drawer Content -->
              <div class="overflow-y-auto">
                <div class="grid grid-cols-2 gap-6">
                  <!-- Left Column -->
                  <div class="space-y-6">
                    <!-- Stats Grid -->
                    <div>
                      <h5 class="text-sm font-medium mb-3 opacity-0">Stats</h5>
                      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                        <div class="p-4 rounded-lg bg-card border border-border">
                          <div class="flex items-center gap-2 mb-2">
                            <div class="text-2xl font-bold font-display">
                              <%= Money.format!(@selected_dev.amount, "USD") %>
                            </div>
                          </div>
                          <div class="text-sm text-muted-foreground">Total Earnings</div>
                        </div>
                        <div class="p-4 rounded-lg bg-card border border-border">
                          <div class="flex items-center gap-2 mb-2">
                            <div class="text-2xl font-bold font-display">
                              <%= @selected_dev.bounties %>
                            </div>
                          </div>
                          <div class="text-sm text-muted-foreground">Bounties Solved</div>
                        </div>
                        <div class="p-4 rounded-lg bg-card border border-border">
                          <div class="flex items-center gap-2 mb-2">
                            <div class="text-2xl font-bold font-display">
                              <%= @selected_dev.projects %>
                            </div>
                          </div>
                          <div class="text-sm text-muted-foreground">Projects Contributed</div>
                        </div>
                      </div>
                    </div>
                    <!-- Message -->
                    <div class="p-px">
                      <h5 class="text-sm font-medium mb-2">Note</h5>
                      <div class="rounded-lg bg-card border border-border">
                        <div class="px-4 py-2 border-b border-border">
                          <div class="flex items-center gap-2 text-sm text-muted-foreground">
                            <.icon name="tabler-message" class="w-4 h-4" />
                            <span>
                              @<%= @selected_dev.handle %> wrote to you <%= Algora.Util.time_ago(
                                DateTime.utc_now()
                                |> DateTime.add(-3, :day)
                              ) %>
                            </span>
                          </div>
                        </div>
                        <div class="px-4 leading-5 text-base whitespace-pre-line min-h-[9rem]">
                          <%= @selected_dev.message %>
                        </div>
                      </div>
                    </div>
                  </div>
                  <!-- Right Column -->
                  <div>
                    <h5 class="text-sm font-medium mb-3">Past Reviews</h5>
                    <div class="space-y-3">
                      <%= for review <- [
                        %{stars: 5, comment: "Exceptional problem-solving skills and great communication throughout the project.", company: "TechCorp Inc."},
                        %{stars: 4, comment: "Delivered high-quality work ahead of schedule. Would definitely work with again.", company: "StartupXYZ"},
                        %{stars: 5, comment: "Outstanding technical expertise and professional attitude.", company: "DevLabs"}
                      ] do %>
                        <div class="rounded-lg bg-card p-4 text-sm border border-border">
                          <div class="flex items-center gap-1 mb-2">
                            <%= for i <- 1..5 do %>
                              <.icon
                                name="tabler-star-filled"
                                class={"w-4 h-4 #{if i <= review.stars, do: "text-warning", else: "text-muted-foreground/25"}"}
                              />
                            <% end %>
                          </div>
                          <p class="text-sm mb-2"><%= review.comment %></p>
                          <p class="text-xs text-muted-foreground">— <%= review.company %></p>
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
              </div>
              <!-- Drawer Footer -->
              <div class="mt-auto">
                <div class="grid grid-cols-2 gap-6">
                  <.button phx-click="close_drawer" variant="hover:destructive" size="lg">
                    Decline
                  </.button>
                  <.button
                    phx-click="accept_dev"
                    phx-value-id={@selected_dev.id}
                    class="flex-1"
                    size="lg"
                  >
                    Accept
                  </.button>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def bounties_card(assigns) do
    ~H"""
    <div class="group/card relative h-full rounded-lg border bg-card text-card-foreground md:gap-8 overflow-hidden lg:col-span-4">
      <div class="flex justify-between">
        <div class="flex flex-col space-y-1.5 p-6">
          <h3 class="text-2xl font-semibold leading-none tracking-tight">Bounties</h3>
          <p class="text-sm text-gray-500 dark:text-gray-400">Most recently posted bounties</p>
        </div>
        <div class="p-6">
          <.link
            class="whitespace-pre text-sm text-muted-foreground hover:underline hover:brightness-125"
            href={"/org/#{@current_org.handle}/bounties?status=open"}
          >
            View all
          </.link>
        </div>
      </div>
      <div class="p-6 pt-0">
        <ul role="list" class="divide-y divide-white/5">
          <%= for bounty <- @bounties do %>
            <li>
              <.link
                class="group relative flex flex-col items-start gap-x-4 gap-y-2 py-4 sm:flex-row sm:items-center"
                rel="noopener"
                href={"https://github.com/#{bounty.task.owner}/#{bounty.task.repo}/issues/#{bounty.task.number}"}
              >
                <div class="min-w-0 flex-auto">
                  <div class="flex items-center gap-x-3">
                    <div class="flex-none rounded-full p-1 bg-success/10 text-success">
                      <div class="h-2 w-2 rounded-full bg-current"></div>
                    </div>
                    <h2 class="line-clamp-2 min-w-0 text-base font-semibold leading-none text-white group-hover:underline">
                      <%= bounty.task.title %>
                    </h2>
                  </div>
                  <div class="ml-7 mt-px flex items-center gap-x-2 text-xs leading-5 text-gray-400">
                    <div class="flex items-center gap-x-2 md:hidden lg:flex">
                      <span class="truncate">tv#<%= bounty.task.number %></span>
                      <svg viewBox="0 0 2 2" class="h-0.5 w-0.5 flex-none fill-gray-400">
                        <circle cx="1" cy="1" r="1"></circle>
                      </svg>
                    </div>
                    <p class="whitespace-nowrap">
                      <%= Algora.Util.time_ago(bounty.inserted_at) %>
                    </p>
                  </div>
                </div>
                <div class="pl-6">
                  <div class="flex-none rounded-lg px-3 py-1 font-display tabular-nums text-lg font-extrabold ring-1 ring-inset bg-success/5 text-success ring-success/30">
                    <%= Money.format!(bounty.amount, bounty.currency) %>
                  </div>
                </div>
              </.link>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  def handle_event("validate", %{"bounty_form" => params}, socket) do
    changeset =
      %BountyForm{}
      |> BountyForm.changeset(params)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("create_bounty", %{"bounty_form" => params}, socket) do
    %{current_user: creator, current_org: owner} = socket.assigns

    changeset =
      %BountyForm{}
      |> BountyForm.changeset(params)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      form_data = Ecto.Changeset.apply_changes(changeset)

      # Calculate total amount for hourly payments
      amount =
        if form_data.payment_type == "hourly" do
          Decimal.mult(form_data.amount, Decimal.new(form_data.expected_hours))
        else
          form_data.amount
        end

      # Create params map in the format expected by Bounty.create_changeset
      bounty_params = %{
        "task" => %{
          "url" => form_data.task_url,
          "title" => form_data.title
        },
        "amount" => amount,
        "status" => "open"
      }

      case Bounties.create_bounty(creator, owner, bounty_params) do
        {:ok, _bounty} ->
          {:noreply,
           socket
           |> put_flash(:info, "Bounty created successfully")
           |> push_navigate(to: "/org/#{owner.handle}/bounties")}

        {:error, _changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, "Error creating bounty")}
      end
    else
      {:noreply,
       socket
       |> assign_form(changeset)
       |> put_flash(:error, "Please fix the errors in the form")}
    end
  end

  def handle_event("view_dev", %{"id" => dev_id}, socket) do
    dev = Accounts.get_user!(dev_id)

    {:noreply,
     socket
     |> assign(:selected_dev, dev)
     |> assign(:show_dev_drawer, true)}
  end

  def handle_event("close_drawer", _, socket) do
    {:noreply,
     socket
     |> assign(:show_dev_drawer, false)}
  end

  def handle_event("accept_dev", %{"id" => dev_id}, socket) do
    # Add logic to accept developer
    {:noreply,
     socket
     |> put_flash(:info, "Developer accepted successfully")
     |> assign(:show_dev_drawer, false)
     |> assign(:selected_dev, nil)
     |> assign(:matching_devs, Enum.reject(socket.assigns.matching_devs, &(&1.id == dev_id)))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp get_url_icon(nil), do: "tabler-link"

  defp get_url_icon(url) when is_binary(url) do
    cond do
      String.contains?(url, "github.com") -> "tabler-brand-github"
      String.contains?(url, "figma.com") -> "tabler-brand-figma"
      String.contains?(url, "docs.google.com") -> "tabler-brand-google"
      # String.contains?(url, "linear.app") -> "tabler-brand-linear"
      # String.contains?(url, "atlassian.net") -> "tabler-brand-jira"
      true -> "tabler-link"
    end
  end
end
