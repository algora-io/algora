defmodule AlgoraWeb.Org.CreateJobLive do
  use AlgoraWeb, :live_view

  alias Algora.Bounties
  alias Algora.Money
  alias AlgoraWeb.Org.Forms.JobForm
  alias Algora.Users

  def mount(_params, _session, socket) do
    form =
      %JobForm{}
      |> JobForm.changeset(%{
        work_type: "remote",
        projects: [%{"title" => "", "url" => "", "amount" => ""}]
      })
      |> to_form(as: :job_form)

    {:ok,
     socket
     |> assign(:recent_bounties, Bounties.list_bounties(limit: 10))
     |> assign(
       :matching_devs,
       Users.list_matching_devs(org_id: socket.assigns.current_org.id, limit: 5)
     )
     |> assign(:selected_dev, nil)
     |> assign(:show_dev_drawer, false)
     |> assign(:is_published, false)
     |> assign(:show_publish_job_drawer, false)
     |> assign(:form, form)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 p-4 pt-6 sm:p-6 md:p-8 max-w-5xl mx-auto">
      <div class="relative rounded-lg border bg-card text-card-foreground md:gap-8 h-full">
        <div class="pt-6 px-6 flex justify-between items-center">
          <div class="flex items-center gap-2">
            <h2 class="text-2xl font-semibold">Create New Job</h2>
            <.tooltip>
              <.tooltip_trigger>
                <.icon name="tabler-help" class="w-5 h-5 text-muted-foreground" />
              </.tooltip_trigger>
              <.tooltip_content side="bottom" class="w-80 p-3 space-y-2">
                <p class="font-medium">Example Jobs:</p>
                <div class="space-y-2 text-sm">
                  <div>
                    <p class="font-medium">Senior Backend Engineer</p>
                    <p class="text-muted-foreground">
                      Lead development of our core API infrastructure and microservices
                    </p>
                  </div>
                  <div>
                    <p class="font-medium">Frontend Developer</p>
                    <p class="text-muted-foreground">
                      Build responsive web applications using React and TypeScript
                    </p>
                  </div>
                  <div>
                    <p class="font-medium">DevOps Engineer</p>
                    <p class="text-muted-foreground">
                      Manage cloud infrastructure and CI/CD pipelines
                    </p>
                  </div>
                  <div>
                    <p class="font-medium">Full Stack Developer</p>
                    <p class="text-muted-foreground">
                      Work across the entire stack to deliver end-to-end features
                    </p>
                  </div>
                </div>
              </.tooltip_content>
            </.tooltip>
          </div>
          <.button type="submit" phx-disable-with="Creating..." size="sm">
            Create job
          </.button>
        </div>
        <.simple_form for={@form} phx-change="validate" phx-submit="create_job" class="p-6 space-y-6">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-y-6 sm:gap-x-4">
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
            <fieldset>
              <legend class="text-sm font-medium mb-2">Annual Compensation Range</legend>
              <div class="mt-1 grid grid-cols-2 rounded-lg overflow-hidden border border-border divide-x divide-border">
                <div>
                  <div class="relative">
                    <.input
                      placeholder="From"
                      field={@form[:min_compensation]}
                      min="0"
                      class="rounded-none border-none"
                    />
                    <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                      <span class="text-muted-foreground text-sm">USD</span>
                    </div>
                  </div>
                </div>
                <div>
                  <div class="relative">
                    <.input
                      placeholder="To"
                      field={@form[:max_compensation]}
                      min="0"
                      class="rounded-none border-none"
                    />
                    <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                      <span class="text-muted-foreground text-sm">USD</span>
                    </div>
                  </div>
                </div>
              </div>
            </fieldset>
          </div>

          <fieldset class="space-y-4">
            <legend class="text-sm font-medium">Work Type</legend>
            <div class="grid grid-cols-2 gap-4">
              <label class={"relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none #{if @form[:work_type].value == "remote", do: 'border-primary ring-2 ring-primary bg-background', else: 'border-input bg-background/75'}"}>
                <.input
                  type="radio"
                  name="job_form[work_type]"
                  field={@form[:work_type]}
                  value="remote"
                  checked={@form[:work_type].value == "remote"}
                  class="sr-only"
                />
                <span class="flex flex-col">
                  <span class="flex items-center gap-2">
                    <.icon name="tabler-world" class="w-5 h-5" />
                    <span class="font-medium">Remote</span>
                  </span>
                  <span class="mt-1 text-sm text-muted-foreground">Work from anywhere</span>
                </span>
              </label>

              <label class={"relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none #{if @form[:work_type].value == "in_person", do: 'border-primary ring-2 ring-primary bg-background', else: 'border-input bg-background/75'}"}>
                <.input
                  type="radio"
                  name="job_form[work_type]"
                  field={@form[:work_type]}
                  value="in_person"
                  checked={@form[:work_type].value == "in_person"}
                  class="sr-only"
                />
                <span class="flex flex-col">
                  <span class="flex items-center gap-2">
                    <.icon name="tabler-building" class="w-5 h-5" />
                    <span class="font-medium">In-Person</span>
                  </span>
                  <span class="mt-1 text-sm text-muted-foreground">Office-based work</span>
                </span>
              </label>
            </div>
          </fieldset>
        </.simple_form>
        <!-- Attached Projects Section -->
        <div class="flex flex-col gap-4 bg-background/50 border-t border-border">
          <div class="px-6 pt-6">
            <h3 class="text-sm font-medium">Add Contract-to-Hire</h3>
            <p class="text-sm text-muted-foreground mt-1">
              Interview your top applicants with a paid project. It's the best way to evaluate fit, accelerate onboarding and get work done while hiring.
            </p>
          </div>

          <div class="space-y-4">
            <%= for {project, i} <- Enum.with_index(@form.params["projects"] || []) do %>
              <div class="flex items-start gap-4 p-6">
                <div class="flex-1 space-y-4">
                  <div>
                    <.label>Project Title</.label>
                    <.input
                      field={project[:title]}
                      name="projects[#{i}][title]"
                      value={project[:title]}
                      type="text"
                    />
                  </div>
                  <div>
                    <.label for="ticket_url" class="text-sm font-medium mb-2">
                      Ticket
                      <span class="font-normal text-muted-foreground  ">
                        (GitHub, Linear, Figma, Jira, Google Docs...)
                      </span>
                    </.label>
                    <div class="relative">
                      <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                        <.icon
                          name={get_url_icon(@form[:ticket_url].value)}
                          class="w-5 h-5 text-muted-foreground"
                        />
                      </div>
                      <.input
                        type="url"
                        field={@form[:ticket_url]}
                        placeholder="https://github.com/owner/repo/issues/123"
                        required
                        class="w-full pl-10 bg-background border-input rounded-lg"
                      />
                    </div>
                  </div>
                  <div>
                    <.label>Payment Amount (USD)</.label>
                    <div class="relative">
                      <.input
                        field={project[:amount]}
                        name="projects[#{i}][amount]"
                        value={project[:amount]}
                      />
                      <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                        <span class="text-muted-foreground text-sm">USD</span>
                      </div>
                    </div>
                  </div>
                </div>
                <.button
                  type="button"
                  variant="ghost"
                  size="sm"
                  phx-click="remove_project"
                  phx-value-index={i}
                >
                  <.icon name="tabler-trash" class="w-4 h-4 text-destructive" />
                </.button>
              </div>
            <% end %>
          </div>

          <.button type="button" variant="outline" size="sm" phx-click="add_project" class="mx-auto">
            <.icon name="tabler-plus" class="w-4 h-4 mr-2" /> Add Project
          </.button>
        </div>
      </div>

      <div class="mt-8 p-6 relative rounded-lg border bg-card text-card-foreground">
        <div class="flex justify-between mb-6">
          <div class="flex flex-col space-y-1.5">
            <h2 class="text-2xl font-semibold leading-none tracking-tight">Applicants</h2>
            <p class="text-sm text-muted-foreground">
              Developers interested in working full-time with you
            </p>
          </div>
        </div>

        <div class="relative w-full overflow-auto">
          <table class={classes(["w-full caption-bottom text-sm", "blur-sm": !@is_published])}>
            <thead class="[&_tr]:border-b">
              <tr class="border-b transition-colors hover:bg-background/50">
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
                <tr class="border-b transition-colors hover:bg-background/50">
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
                    <.button
                      phx-click="view_dev"
                      phx-value-id={dev.id}
                      size="sm"
                      variant={if @is_published, do: "default", else: "outline"}
                    >
                      View Profile
                    </.button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
          <%= if !@is_published do %>
            <div class="absolute bg-gradient-to-b from-transparent to-card inset-0"></div>
            <div class="absolute flex items-center justify-center inset-0 z-10">
              <div class="bg-black">
                <.button type="button" variant="default" size="xl" phx-click="publish_job">
                  Publish Job
                </.button>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <div class="mt-8">
        <.bounties_card current_org={@current_org} bounties={@recent_bounties} />
      </div>

      <.drawer show={@show_dev_drawer} on_cancel="close_drawer">
        <%= if @selected_dev do %>
          <.drawer_header class="flex items-center gap-4">
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
          </.drawer_header>
          <.drawer_content>
            <div class="grid grid-cols-2 gap-6">
              <!-- Left Column -->
              <div class="space-y-6">
                <!-- Stats Grid -->
                <div>
                  <h5 class="text-sm font-medium mb-3 opacity-0">Stats</h5>
                  <div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
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
                  <div class="rounded-lg bg-card border border-border">
                    <div class="px-4 py-2 border-b border-border">
                      <div class="flex items-center gap-2 text-sm text-muted-foreground">
                        <.icon name="tabler-message" class="w-4 h-4" />
                        <span>
                          <%= @selected_dev.handle %> wrote to you <%= Algora.Util.time_ago(
                            DateTime.utc_now()
                            |> DateTime.add(-3, :day)
                          ) %>
                        </span>
                      </div>
                    </div>
                    <div class="px-4 leading-5 text-base whitespace-pre-line min-h-[12rem]">
                      <%= @selected_dev.message %>
                    </div>
                  </div>
                </div>
              </div>
              <!-- Right Column -->
              <div>
                <h5 class="text-sm font-medium mb-3">Past Reviews</h5>
                <div class="space-y-6">
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
          </.drawer_content>
          <.drawer_footer>
            <div class="grid grid-cols-2 gap-6">
              <.button phx-click="close_drawer" variant="hover:destructive" size="lg">
                Decline
              </.button>
              <.button phx-click="accept_dev" phx-value-id={@selected_dev.id} class="flex-1" size="lg">
                Accept
              </.button>
            </div>
          </.drawer_footer>
        <% end %>
      </.drawer>
    </div>
    <.drawer id="publish-job-drawer" show={@show_publish_job_drawer} on_cancel="close_drawer">
      <.drawer_header>
        Publish Job
      </.drawer_header>
      <.drawer_content class="space-y-6">
        <div class="grid grid-cols-5 gap-6">
          <div class="col-span-3 rounded-lg ring-1 ring-border aspect-video w-full h-full bg-card">
          </div>
          <div class="col-span-2 space-y-6">
            <.card>
              <.card_header>
                <.card_title>Why Algora?</.card_title>
              </.card_header>
              <.card_content>
                <div class="space-y-8">
                  <div class="relative flex gap-4">
                    <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border-2 border-success bg-success text-background">
                      <.icon name="tabler-users" class="h-5 w-5" />
                    </div>
                    <div class="flex flex-col pt-1.5">
                      <span class="text-sm font-medium">Reach Top Talent</span>
                      <span class="text-sm text-muted-foreground">
                        Publish to the Algora network of proven developers
                      </span>
                    </div>
                    <div class="absolute left-5 top-10 h-full w-px bg-border" aria-hidden="true" />
                  </div>

                  <div class="relative flex gap-4">
                    <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border-2 border-success bg-success text-background">
                      <.icon name="tabler-list-check" class="h-5 w-5" />
                    </div>
                    <div class="flex flex-col pt-1.5">
                      <span class="text-sm font-medium">Track Applicants</span>
                      <span class="text-sm text-muted-foreground">
                        Review and manage candidates in one place
                      </span>
                    </div>
                    <div class="absolute left-5 top-10 h-full w-px bg-border" aria-hidden="true" />
                  </div>

                  <div class="relative flex gap-4">
                    <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border-2 border-success bg-success text-background">
                      <.icon name="tabler-briefcase" class="h-5 w-5" />
                    </div>
                    <div class="flex flex-col pt-1.5">
                      <span class="text-sm font-medium">Contract-to-Hire</span>
                      <span class="text-sm text-muted-foreground">
                        Test fit with paid trial projects before hiring
                      </span>
                    </div>
                  </div>
                </div>
              </.card_content>
            </.card>

            <.card>
              <.card_header>
                <.card_title>Payment Summary</.card_title>
              </.card_header>
              <.card_content>
                <dl class="space-y-4">
                  <div class="flex justify-between">
                    <dt class="text-muted-foreground">
                      Job posting
                    </dt>
                    <dd class="font-semibold font-display tabular-nums">
                      <%= Money.format!(
                        Decimal.new(599),
                        "USD"
                      ) %>
                    </dd>
                  </div>
                  <div class="h-px bg-border" />
                  <div class="flex justify-between">
                    <dt class="font-medium">Total Due</dt>
                    <dd class="font-semibold font-display tabular-nums">
                      <%= Money.format!(
                        Decimal.new(599),
                        "USD"
                      ) %>
                    </dd>
                  </div>
                </dl>
              </.card_content>
            </.card>
          </div>
        </div>

        <div class="flex justify-end gap-3">
          <.button variant="outline" phx-click="close_drawer">
            Cancel
          </.button>
          <.button phx-click="submit_collaboration">
            <.icon name="tabler-credit-card" class="w-4 h-4 mr-2" /> Pay with Stripe
          </.button>
        </div>
      </.drawer_content>
    </.drawer>
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
                href={"https://github.com/#{bounty.ticket.owner}/#{bounty.ticket.repo}/issues/#{bounty.ticket.number}"}
              >
                <div class="min-w-0 flex-auto">
                  <div class="flex items-center gap-x-3">
                    <div class="flex-none rounded-full p-1 bg-success/10 text-success">
                      <div class="h-2 w-2 rounded-full bg-current"></div>
                    </div>
                    <h2 class="line-clamp-2 min-w-0 text-base font-semibold leading-none text-white group-hover:underline">
                      <%= bounty.ticket.title %>
                    </h2>
                  </div>
                  <div class="ml-7 mt-px flex items-center gap-x-2 text-xs leading-5 text-gray-400">
                    <div class="flex items-center gap-x-2 md:hidden lg:flex">
                      <span class="truncate">tv#<%= bounty.ticket.number %></span>
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

  def handle_event("validate", %{"job_form" => params}, socket) do
    form =
      %JobForm{}
      |> JobForm.changeset(params)
      |> Map.put(:action, :validate)
      |> to_form(as: :job_form)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("add_project", _, socket) do
    existing = Map.get(socket.assigns.form.params, "projects", [])

    params =
      Map.put(
        socket.assigns.form.params,
        "projects",
        existing ++ [%{"title" => "", "url" => "", "amount" => ""}]
      )

    form =
      %JobForm{}
      |> JobForm.changeset(params)
      |> to_form(as: :job_form)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("remove_project", %{"index" => index}, socket) do
    index = String.to_integer(index)
    existing = Map.get(socket.assigns.form.params, "projects", [])

    params =
      Map.put(
        socket.assigns.form.params,
        "projects",
        List.delete_at(existing, index)
      )

    form =
      %JobForm{}
      |> JobForm.changeset(params)
      |> to_form(as: :job_form)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("create_job", %{"job_form" => params}, socket) do
    case JobForm.changeset(params) do
      {:ok, job} ->
        {:noreply,
         socket
         |> put_flash(:info, "Job created successfully")
         |> redirect(to: ~p"/jobs/#{job}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :job_form))}
    end
  end

  def handle_event("publish_job", _, socket) do
    {:noreply, socket |> assign(:show_publish_job_drawer, true)}
  end

  def handle_event("view_dev", %{"id" => dev_id}, socket) do
    dev = Users.get_user_with_stats(dev_id)

    {:noreply,
     socket
     |> assign(:selected_dev, dev)
     |> assign(:show_dev_drawer, true)}
  end

  def handle_event("close_drawer", _, socket) do
    {:noreply,
     socket
     |> assign(:show_dev_drawer, false)
     |> assign(:show_publish_job_drawer, false)}
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

  def handle_event("begin_collaboration", _, socket) do
    {:noreply, socket |> assign(:show_publish_job_drawer, true)}
  end

  def handle_event("submit_collaboration", _params, socket) do
    # TODO: Implement payment method addition and collaboration initiation
    {:noreply, socket |> redirect(to: ~p"/contracts/123")}
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
