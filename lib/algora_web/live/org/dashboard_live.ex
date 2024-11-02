defmodule AlgoraWeb.Org.DashboardLive do
  use AlgoraWeb, :live_view

  alias Algora.Bounties
  alias Algora.Money
  alias Algora.Bounties.Bounty
  alias AlgoraWeb.Org.Forms.BountyForm

  def mount(_params, _session, socket) do
    org_id = socket.assigns.current_org.id
    stats = Bounties.fetch_stats(org_id)
    recent_bounties = Bounties.list_bounties(owner_id: org_id, limit: 10)
    recent_activities = fetch_recent_activities()

    changeset =
      %BountyForm{}
      |> BountyForm.changeset(%{
        payment_type: "fixed",
        currency: "USD"
      })

    {:ok,
     socket
     |> assign(:onboarding_completed?, true)
     |> assign(:stats, stats)
     |> assign(:recent_bounties, recent_bounties)
     |> assign(:recent_activities, recent_activities)
     |> assign(:get_started_cards, get_started_cards())
     |> assign(:tech_stack, ["Elixir", "TypeScript"])
     |> assign(:locations, ["United States", "Remote"])
     |> assign(:matches, Algora.Accounts.list_matching_devs(limit: 8, country: "US"))
     |> assign_form(changeset)}
  end

  def render(assigns) do
    ~H"""
    <%= if @onboarding_completed? do %>
      <.dashboard_onboarded {assigns} />
    <% else %>
      <.dashboard_onboarding {assigns} />
    <% end %>
    """
  end

  def dashboard_onboarded(assigns) do
    ~H"""
    <div class="flex-1 space-y-4 p-4 pt-6 sm:p-6 md:p-8">
      <div class="p-6 relative rounded-xl border border-white/10 bg-white/[2%] bg-gradient-to-br from-white/[2%] via-white/[2%] to-white/[2%] md:gap-8 h-full">
        <div class="flex justify-between items-center">
          <h2 class="text-2xl font-semibold mb-6">Create New Bounty</h2>
          <.button
            type="submit"
            phx-disable-with="Creating..."
            class="bg-white text-gray-900 hover:bg-gray-100"
          >
            <.icon name="tabler-plus" class="w-4 h-4 mr-2" /> Create Bounty
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
                class="w-full bg-gray-900/50 border-white/10 rounded-lg"
              />
            </div>
            <div>
              <.label for="task_url" class="text-sm font-medium mb-2">
                Ticket
                <span class="font-normal text-gray-300 text-xs">
                  (GitHub, Linear, Figma, Jira, Google Docs...)
                </span>
              </.label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                  <.icon name={get_url_icon(@form[:task_url].value)} class="w-5 h-5 text-gray-400" />
                </div>
                <.input
                  type="url"
                  field={@form[:task_url]}
                  placeholder="https://github.com/owner/repo/issues/123"
                  required
                  class="w-full pl-10 bg-gray-900/50 border-white/10 rounded-lg"
                />
              </div>
            </div>
          </div>

          <fieldset class="mb-8">
            <legend class="text-sm font-medium text-gray-300 mb-2">Payment Type</legend>
            <div class="mt-1 grid grid-cols-1 gap-y-6 sm:grid-cols-2 sm:gap-x-4">
              <label class={"relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none #{if @form[:payment_type].value == "fixed", do: 'border-indigo-600 ring-2 ring-indigo-600 bg-gray-800', else: 'border-gray-700 bg-white/[2.5%]'}"}>
                <input
                  type="radio"
                  name="bounty_form[payment_type]"
                  value="fixed"
                  checked={@form[:payment_type].value == "fixed"}
                  class="sr-only"
                />
                <span class="flex flex-1 flex-col">
                  <span class="flex items-center mb-1">
                    <span class="block text-sm font-medium text-gray-200">Fixed Amount</span>
                    <svg
                      class={"ml-2 h-5 w-5 text-indigo-600 #{if @form[:payment_type].value != "fixed", do: 'invisible'}"}
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
                  <span class="mt-1 text-sm text-gray-400">
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
                        class="font-display w-full py-1.5 bg-gray-900/50 border-white/10 rounded-lg text-sm text-green-300 font-medium"
                      />
                      <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                        <span class="text-gray-400 text-sm">USD</span>
                      </div>
                    </div>
                  </div>
                </span>
              </label>

              <label class={"relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none #{if @form[:payment_type].value == "hourly", do: 'border-indigo-600 ring-2 ring-indigo-600 bg-gray-800', else: 'border-gray-700 bg-white/[2.5%]'}"}>
                <input
                  type="radio"
                  name="bounty_form[payment_type]"
                  value="hourly"
                  checked={@form[:payment_type].value == "hourly"}
                  class="sr-only"
                />
                <span class="flex flex-1 flex-col">
                  <span class="flex items-center mb-1">
                    <span class="block text-sm font-medium text-gray-200">Hourly Rate</span>
                    <svg
                      class={"ml-2 h-5 w-5 text-indigo-600 #{if @form[:payment_type].value != "hourly", do: 'invisible'}"}
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
                  <span class="mt-1 text-sm text-gray-400">
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
                          class="font-display w-full py-1.5 bg-gray-900/50 border-white/10 rounded-lg text-sm text-green-300 font-medium"
                        />
                        <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                          <span class="text-gray-400 text-sm">USD/h</span>
                        </div>
                      </div>
                      <div class="relative">
                        <.input
                          field={@form[:expected_hours]}
                          min="1"
                          step="1"
                          placeholder="10"
                          required={@form[:payment_type].value == "hourly"}
                          class="font-display w-full py-1.5 bg-gray-900/50 border-white/10 rounded-lg text-sm"
                        />
                        <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                          <span class="text-gray-400 text-sm">hours per week</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </span>
              </label>
            </div>
          </fieldset>
        </.simple_form>
      </div>

      <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <.stat_card
          title="Open Bounties"
          value={Money.format!(@stats.open_bounties_amount, @stats.currency)}
          subtext={"#{@stats.open_bounties_count} bounties"}
          href={"/org/#{@current_org.handle}/bounties?status=open"}
          icon="tabler-diamond"
        />
        <.stat_card
          title="Total Awarded"
          value={Money.format!(@stats.total_awarded, @stats.currency)}
          subtext={"#{@stats.completed_bounties_count} bounties / tips"}
          href={"/org/#{@current_org.handle}/bounties?status=completed"}
          icon="tabler-gift"
        />
        <.stat_card
          title="Solvers"
          value={@stats.solvers_count}
          subtext={"+#{@stats.solvers_diff} from last month"}
          href={"/org/#{@current_org.handle}/solvers"}
          icon="tabler-user-code"
        />
        <.stat_card
          title="Members"
          value={@stats.members_count}
          subtext=""
          href={"/org/#{@current_org.handle}/members"}
          icon="tabler-users"
        />
      </div>
      <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
        <.bounties_card current_org={@current_org} bounties={@recent_bounties} />
        <.activity_card activities={@recent_activities} />
      </div>
    </div>
    """
  end

  def dashboard_onboarding(assigns) do
    ~H"""
    <div class="text-white p-4 pt-6 sm:p-6 md:p-8">
      <h1 class="text-2xl font-semibold text-white mb-8">Get started</h1>

      <div class="grid grid-cols-3 gap-8 mb-12">
        <%= for card <- @get_started_cards do %>
          <div class="group flex h-full w-full max-w-md items-center justify-center">
            <div class="relative z-10 flex h-full w-full cursor-pointer items-center overflow-hidden ring-1 group-hover:ring-2 rounded-md ring-purple-400/20 p-[1.5px]">
              <div class="absolute inset-0 h-full w-full opacity-100 group-hover:opacity-100 transition-opacity animate-rotate rounded-full bg-[conic-gradient(#5D59EB_20deg,#8b5cf6_120deg)]">
              </div>
              <.link
                class="relative flex h-full w-full overflow-hidden rounded-md bg-gray-900"
                navigate={card.href}
              >
                <div class="rounded-lg p-6 relative cursor-pointer group">
                  <div class="flex items-center gap-3 mb-4">
                    <.icon
                      name={card.icon}
                      class="h-8 w-8 text-indigo-400 group-hover:text-white transition-colors"
                    />
                    <h2 class="text-xl font-display font-semibold text-indigo-300 group-hover:text-white transition-colors">
                      <%= card.title %>
                    </h2>
                  </div>
                  <%= for paragraph <- card.paragraphs do %>
                    <p class="text-base mb-2 text-gray-300 font-medium group-hover:text-gray-100 transition-colors">
                      <%= paragraph %>
                    </p>
                  <% end %>
                  <div class="absolute bottom-4 right-6 text-3xl group-hover:translate-x-2 transition-transform">
                    &rarr;
                  </div>
                </div>
              </.link>
            </div>
          </div>
        <% end %>
      </div>

      <%= if @onboarding_completed? do %>
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
      <% end %>
    </div>
    """
  end

  defp get_started_cards do
    [
      %{
        title: "Create bounties",
        href: ~p"/bounties/new",
        icon: "tabler-diamond",
        paragraphs: [
          "Install Algora in your GitHub repo(s), use the Algora commands in issues and pull requests, and reward bounties without leaving GitHub.",
          "You can share your bounty board with anyone and toggle bounties between private & public."
        ]
      },
      %{
        title: "Create projects",
        href: ~p"/projects/new",
        icon: "tabler-rocket",
        paragraphs: [
          "Get matched with top developers, manage contract work and make payments globally.",
          "You can share projects with anyone and pay on hourly, fixed, milestone or bounty basis."
        ]
      },
      %{
        title: "Create jobs",
        href: ~p"/jobs/new",
        icon: "tabler-briefcase",
        paragraphs: [
          "Find new teammates, manage applicants and simplify contract-to-hire.",
          "You can use your job board and ATS privately as well as publish jobs on Algora."
        ]
      }
    ]
  end

  def stat_card(assigns) do
    ~H"""
    <.link href={@href}>
      <div class="group/card relative rounded-xl border border-white/10 bg-white/[2%] bg-gradient-to-br from-white/[2%] via-white/[2%] to-white/[2%] md:gap-8 hover:border-white/15 hover:bg-white/[4%] h-full transition-colors duration-75 hover:brightness-125">
        <div class="p-6 flex flex-row items-center justify-between space-y-0 pb-2">
          <h3 class="tracking-tight text-sm font-medium"><%= @title %></h3>
          <.icon name={@icon} class="h-6 w-6 text-gray-400" />
        </div>
        <div class="p-6 pt-0">
          <div class="text-2xl font-bold"><%= @value %></div>
          <p class="text-xs text-gray-400"><%= @subtext %></p>
        </div>
      </div>
    </.link>
    """
  end

  def bounties_card(assigns) do
    ~H"""
    <div class="group/card relative h-full rounded-xl border border-white/10 bg-white/[2%] bg-gradient-to-br from-white/[2%] via-white/[2%] to-white/[2%] md:gap-8 overflow-hidden lg:col-span-4">
      <div class="flex justify-between">
        <div class="flex flex-col space-y-1.5 p-6">
          <h3 class="text-2xl font-semibold leading-none tracking-tight">Bounties</h3>
          <p class="text-sm text-gray-500 dark:text-gray-400">Most recently posted bounties</p>
        </div>
        <div class="p-6">
          <.link
            class="whitespace-pre text-sm text-gray-400 hover:underline hover:brightness-125"
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
                    <div class="flex-none rounded-full p-1 bg-emerald-400/10 text-emerald-400">
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
                  <div class="flex-none rounded-xl px-3 py-1 font-mono text-lg font-extrabold ring-1 ring-inset bg-emerald-400/5 text-emerald-400 ring-emerald-400/30">
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

  def activity_card(assigns) do
    ~H"""
    <div class="group/card relative h-full rounded-xl border border-white/10 bg-white/[2%] bg-gradient-to-br from-white/[2%] via-white/[2%] to-white/[2%] md:gap-8 overflow-hidden lg:col-span-3">
      <div class="flex flex-col space-y-1.5 p-6">
        <h3 class="text-2xl font-semibold leading-none tracking-tight">Activity</h3>
        <p class="text-sm text-gray-500 dark:text-gray-400">See what's popping</p>
      </div>
      <div class="p-6 pt-0">
        <div>
          <ul>
            <%= for activity <- @activities do %>
              <li class="relative pb-8">
                <div class="relative">
                  <span
                    class="absolute -bottom-5 left-5 -ml-px h-4 w-0.5 bg-gray-200 transition-opacity dark:bg-gray-600"
                    aria-hidden="true"
                  >
                  </span>
                  <.link class="group inline-flex" rel="noopener" href={activity.url}>
                    <div class="relative flex space-x-3">
                      <div class="flex min-w-0 flex-1 justify-between space-x-4">
                        <div class="flex items-center gap-4">
                          <span class="relative flex shrink-0 overflow-hidden rounded-full h-10 w-10">
                            <img
                              class="aspect-square h-full w-full"
                              alt={activity.user}
                              src={"https://github.com/#{activity.user}.png"}
                            />
                          </span>
                          <div class="space-y-0.5">
                            <p class="text-sm text-gray-500 transition-colors dark:text-gray-200 dark:group-hover:text-white">
                              <%= activity_text(activity) %>
                            </p>
                            <div class="whitespace-nowrap text-xs text-gray-500 dark:text-gray-400">
                              <time><%= activity.days_ago %> days ago</time>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </.link>
                </div>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  defp activity_text(%{type: :bounty_awarded, user: user, amount: amount, currency: currency}) do
    Phoenix.HTML.raw(
      "<strong class='font-bold'>Algora</strong> awarded <strong class='font-bold'>#{user}</strong> a <strong class='font-bold'>#{Money.format!(amount, currency)}</strong> bounty"
    )
  end

  defp activity_text(%{type: :pr_submitted, user: user}) do
    Phoenix.HTML.raw(
      "<strong class='font-bold'>#{user}</strong> submitted a PR that claims a bounty"
    )
  end

  defp fetch_recent_activities do
    [
      %{
        url: "https://github.com/algora-io/tv/issues/105",
        type: :bounty_awarded,
        user: "urbit-pilled",
        amount: 50,
        currency: "USD",
        days_ago: 1
      },
      %{
        url: "https://github.com/algora-io/tv/issues/104",
        type: :pr_submitted,
        user: "GauravBurande",
        days_ago: 3
      },
      %{
        url: "https://github.com/algora-io/tv/issues/103",
        type: :bounty_awarded,
        user: "gilest",
        amount: 75,
        currency: "USD",
        days_ago: 6
      },
      %{
        url: "https://github.com/algora-io/tv/issues/102",
        type: :pr_submitted,
        user: "urbit-pilled",
        days_ago: 11
      }
    ]
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
