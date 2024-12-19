defmodule AlgoraWeb.Org.DashboardAdminLive do
  use AlgoraWeb, :live_view
  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Reviews
  alias Algora.Users
  alias AlgoraWeb.Org.Forms.JobForm
  alias Algora.Contracts
  alias Algora.Payments
  alias Algora.FeeTier
  def middle_rate(%{min: min, max: max}), do: Money.div!(Money.add!(min, max), 2)

  def mount(_params, _session, socket) do
    %{tech_stack: tech_stack} = socket.assigns.current_org
    hourly_rate = %{min: Money.new!(50, :USD), max: Money.new!(100, :USD)}
    hours_per_week = 20

    {:ok, contract} =
      Contracts.fetch_contract(client_id: socket.assigns.current_org.id, open?: true)

    job_form =
      %JobForm{}
      |> JobForm.changeset(%{work_type: "remote"})
      |> to_form(as: :job_form)

    socket =
      socket
      |> assign(:tech_stack, tech_stack)
      |> assign(:view_mode, "compact")
      |> assign(:looking_to_collaborate, true)
      |> assign(:hourly_rate, hourly_rate)
      |> assign(:hours_per_week, hours_per_week)
      |> assign(:weekly_amount, Money.mult!(middle_rate(hourly_rate), hours_per_week))
      |> assign(:selected_dev, nil)
      |> assign(:matching_devs, fetch_matching_devs(tech_stack))
      |> assign(:contract, contract)
      |> assign(:achievements, fetch_achievements(socket))
      |> assign(:show_begin_collaboration_drawer, false)
      |> assign(:job_form, job_form)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 lg:pr-96 bg-background text-foreground">
      <!-- Hourly Bounties Section -->
      <div class="relative h-full max-w-4xl mx-auto p-6">
        <div class="flex justify-between px-6">
          <div class="flex flex-col space-y-1.5">
            <h2 class="text-2xl font-semibold leading-none tracking-tight">
              My matches
            </h2>
            <p class="text-sm text-muted-foreground">
              Based on tech stack and hourly rate
            </p>
          </div>
          <.button phx-click="begin_collaboration" size="lg">
            Start collaborating
          </.button>
        </div>
        <div class="px-6">
          <div class="relative w-full overflow-auto">
            <table class="w-full caption-bottom text-sm">
              <tbody>
                <.contract contract={@contract} />
                <%= for user <- @matching_devs do %>
                  <.matching_dev user={user} />
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>
      <!-- Job Creation Section -->
      <div class="relative h-full max-w-4xl mx-auto p-6">
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
                  </div>
                </.tooltip_content>
              </.tooltip>
            </div>
            <.button type="submit" phx-disable-with="Creating..." size="sm">
              Create job
            </.button>
          </div>
          <.simple_form
            for={@job_form}
            phx-change="validate_job"
            phx-submit="create_job"
            class="p-6 space-y-6"
          >
            <div class="grid grid-cols-1 md:grid-cols-2 gap-y-6 sm:gap-x-4">
              <div>
                <.label for="title" class="text-sm font-medium mb-2">
                  Title
                </.label>
                <.input
                  type="text"
                  field={@job_form[:title]}
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
                        field={@job_form[:min_compensation]}
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
                        field={@job_form[:max_compensation]}
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
                <label class={"relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none #{if @job_form[:work_type].value == "remote", do: 'border-primary ring-2 ring-primary bg-background', else: 'border-input bg-background/75'}"}>
                  <.input
                    type="radio"
                    name="job_form[work_type]"
                    field={@job_form[:work_type]}
                    value="remote"
                    checked={@job_form[:work_type].value == "remote"}
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

                <label class={"relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none #{if @job_form[:work_type].value == "in_person", do: 'border-primary ring-2 ring-primary bg-background', else: 'border-input bg-background/75'}"}>
                  <.input
                    type="radio"
                    name="job_form[work_type]"
                    field={@job_form[:work_type]}
                    value="in_person"
                    checked={@job_form[:work_type].value == "in_person"}
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
        </div>
      </div>
    </div>
    <!-- Sidebar -->
    <aside class="fixed bottom-0 right-0 top-16 hidden w-96 overflow-y-auto border-l border-border bg-background p-4 pt-6 lg:block sm:p-6 md:p-8 scrollbar-thin">
      <!-- Availability Section -->
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <label for="available" class="text-sm font-medium">I'm looking to collaborate</label>
          <.tooltip>
            <.icon name="tabler-help-circle" class="h-4 w-4 text-muted-foreground" />
            <.tooltip_content side="bottom" class="max-w-xs text-sm">
              When enabled, developers will be able to see your hourly rate and contact you.
            </.tooltip_content>
          </.tooltip>
        </div>
        <.switch
          id="available"
          name="available"
          value={@looking_to_collaborate}
          phx-click="toggle_availability"
        />
      </div>
      <div class="mt-4 grid grid-cols-2 gap-4">
        <.input
          name="hourly-rate-min"
          value={@contract.hourly_rate_min.amount}
          phx-debounce="200"
          class="w-full bg-background border-input font-display"
          icon="tabler-currency-dollar"
          label="Min hourly rate (USD)"
        />
        <.input
          name="hourly-rate-max"
          value={@contract.hourly_rate_max.amount}
          phx-debounce="200"
          class="w-full bg-background border-input font-display"
          icon="tabler-currency-dollar"
          label="Max hourly rate (USD)"
        />
      </div>
      <!-- Tech Stack Section -->
      <div class="mt-4">
        <label for="tech-input" class="text-sm font-medium">Tech stack</label>
        <.input
          id="tech-input"
          name="tech-input"
          value=""
          type="text"
          placeholder="Elixir, Phoenix, PostgreSQL, etc."
          phx-keydown="handle_tech_input"
          phx-debounce="200"
          phx-hook="ClearInput"
          class="mt-2 w-full bg-background border-input"
        />
        <div class="flex flex-wrap gap-3 mt-4">
          <%= for tech <- @tech_stack do %>
            <div class="ring-foreground/25 ring-1 ring-inset bg-foreground/5 text-foreground rounded-lg px-2 py-1 text-xs font-medium">
              {tech}
              <button
                phx-click="remove_tech"
                phx-value-tech={tech}
                class="ml-1 text-foreground hover:text-foreground/80"
              >
                ×
              </button>
            </div>
          <% end %>
        </div>
      </div>
      <!-- Achievements Section -->
      <div class="mt-8 flex items-center justify-between">
        <h2 class="text-xl font-semibold leading-none tracking-tight">Achievements</h2>
        <.link
          class="whitespace-pre text-sm text-muted-foreground hover:underline hover:brightness-125"
          href="#"
        >
          View all
        </.link>
      </div>
      <nav class="pt-4">
        <ol role="list" class="space-y-6">
          <%= for achievement <- @achievements do %>
            <li>
              <.achievement achievement={achievement} />
            </li>
          <% end %>
        </ol>
      </nav>
      <div class="pt-8 opacity-0">
        <.link href="https://algora.io/challenges/golem">
          <img src={~p"/images/golem-challenge.png"} alt="Golem Challenge" class="aspect-video block" />
        </.link>
      </div>
    </aside>
    <.drawer
      id="begin-collaboration-drawer"
      show={@show_begin_collaboration_drawer}
      on_cancel="close_drawer"
    >
      <.drawer_header>
        Begin Collaboration
      </.drawer_header>
      <.drawer_content class="space-y-6">
        <div class="grid grid-cols-5 gap-6">
          <div class="col-span-3 rounded-lg ring-1 ring-border aspect-video w-full h-full bg-card">
          </div>
          <div class="col-span-2 space-y-6">
            <.card>
              <.card_header>
                <.card_title>How it works</.card_title>
              </.card_header>
              <.card_content>
                <div class="space-y-8">
                  <div class="relative flex gap-4">
                    <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border-2 border-success bg-success text-background">
                      <.icon name="tabler-credit-card" class="h-5 w-5" />
                    </div>
                    <div class="flex flex-col pt-1.5">
                      <span class="text-sm font-medium">Add payment method</span>
                      <span class="text-sm text-muted-foreground">
                        Add your credit card to initiate the collaboration
                      </span>
                    </div>
                    <div class="absolute left-5 top-10 h-full w-px bg-border" aria-hidden="true" />
                  </div>

                  <div class="relative flex gap-4">
                    <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border-2 border-border bg-background">
                      <.icon name="tabler-lock" class="h-5 w-5" />
                    </div>
                    <div class="flex flex-col pt-1.5">
                      <span class="text-sm font-medium">Funds held in escrow</span>
                      <%= if @selected_dev do %>
                        <span class="text-sm text-muted-foreground">
                          Once accepted,
                          <span class="font-semibold text-foreground">
                            {Money.to_string!(Money.mult!(@hourly_rate, @hours_per_week))}
                          </span>
                          will be held securely
                        </span>
                      <% else %>
                        <span class="text-sm text-muted-foreground">
                          Once the developer accepts, the amount will be held securely
                        </span>
                      <% end %>
                    </div>
                    <div class="absolute left-5 top-10 h-full w-px bg-border" aria-hidden="true" />
                  </div>

                  <div class="relative flex gap-4">
                    <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border-2 border-border bg-background">
                      <.icon name="tabler-check" class="h-5 w-5" />
                    </div>
                    <div class="flex flex-col pt-1.5">
                      <span class="text-sm font-medium">Release and renew</span>
                      <span class="text-sm text-muted-foreground">
                        Release funds to the developer and continue collaboration
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
                      Weekly amount ({@hours_per_week} hours x {Money.to_string!(
                        middle_rate(@hourly_rate)
                      )}/hr)
                    </dt>
                    <dd class="font-semibold font-display tabular-nums">
                      {Money.to_string!(@weekly_amount)}
                    </dd>
                  </div>
                  <div class="flex justify-between">
                    <dt class="text-muted-foreground">
                      Algora fees (19%)
                    </dt>
                    <dd class="font-semibold font-display tabular-nums">
                      {Money.to_string!(Money.mult!(@weekly_amount, Decimal.new("0.19")))}
                    </dd>
                  </div>
                  <div class="flex justify-between">
                    <dt class="text-muted-foreground">Transaction fees (4%)</dt>
                    <dd class="font-semibold font-display tabular-nums">
                      {Money.to_string!(Money.mult!(@weekly_amount, Decimal.new("0.04")))}
                    </dd>
                  </div>
                  <div class="h-px bg-border" />
                  <div class="flex justify-between">
                    <dt class="font-medium">Total Due</dt>
                    <dd class="font-semibold font-display tabular-nums">
                      {Money.to_string!(Money.mult!(@weekly_amount, Decimal.new("1.23")))}
                    </dd>
                  </div>
                </dl>
                <div class="mt-1 text-muted-foreground text-sm">
                  <p>Estimated based on the middle of your hourly rate range.</p>
                  <p>
                    Actual charges may vary (up to
                    <span class="font-semibold">
                      {Money.to_string!(
                        Money.mult!(
                          Money.mult!(@hourly_rate.max, @hours_per_week),
                          Decimal.new("1.23")
                        )
                      )}
                    </span>
                    including fees).
                  </p>
                </div>
              </.card_content>
            </.card>
          </div>
        </div>

        <div class="flex justify-end gap-3">
          <.button variant="outline" phx-click="close_drawer">
            Cancel
          </.button>
          <.button phx-click="submit_collaboration">
            <.icon name="tabler-credit-card" class="w-4 h-4 mr-2" /> Add payment method
          </.button>
        </div>
      </.drawer_content>
    </.drawer>
    """
  end

  defp fetch_achievements(socket) do
    achievements = [
      {&personalize_status/1, "Personalize Algora"},
      {&begin_collaboration_status/1, "Begin collaboration"},
      {&complete_first_contract_status/1, "Complete first contract"},
      {&unlock_lower_fees_status/1, "Unlock lower fees with a developer"},
      {&refer_a_friend/1, "Refer a friend"}
    ]

    {result, _} =
      Enum.reduce_while(achievements, {[], false}, fn {status_fn, name}, {acc, found_current} ->
        status = status_fn.(socket.assigns.current_org)

        result =
          cond do
            found_current -> {acc ++ [%{status: status, name: name}], found_current}
            status == :completed -> {acc ++ [%{status: status, name: name}], false}
            true -> {acc ++ [%{status: :current, name: name}], true}
          end

        {:cont, result}
      end)

    result
  end

  defp personalize_status(_socket), do: :completed

  defp begin_collaboration_status(org) do
    case Contracts.list_contracts(client_id: org.id, active_or_paid?: true, limit: 1) do
      [] -> :upcoming
      _ -> :completed
    end
  end

  defp complete_first_contract_status(org) do
    case Contracts.list_contracts(client_id: org.id, status: :paid, limit: 1) do
      [] -> :upcoming
      _ -> :completed
    end
  end

  defp unlock_lower_fees_status(org) do
    {_contractor_id, max_amount} = Payments.get_max_paid_to_single_contractor(org.id)

    case FeeTier.first_threshold_met?(max_amount) do
      false -> :upcoming
      _ -> :completed
    end
  end

  # TODO: implement referrals
  defp refer_a_friend(_socket), do: :upcoming

  def achievement(%{achievement: %{status: :completed}} = assigns) do
    ~H"""
    <.link href="#" class="group flex items-center gap-3">
      <div class="flex h-5 w-5 items-center justify-center text-success">
        <.icon name="tabler-circle-check-filled" class="h-5 w-5" />
      </div>
      <span class="text-sm font-medium text-success group-hover:text-muted">
        {@achievement.name}
      </span>
    </.link>
    """
  end

  def achievement(%{achievement: %{status: :upcoming}} = assigns) do
    ~H"""
    <.link href="#" class="group flex items-center gap-3">
      <div class="flex h-5 w-5 items-center justify-center">
        <div class="h-2 w-2 rounded-full bg-muted-foreground group-hover:bg-muted"></div>
      </div>
      <span class="text-sm font-medium text-muted-foreground group-hover:text-muted">
        {@achievement.name}
      </span>
    </.link>
    """
  end

  def achievement(%{achievement: %{status: :current}} = assigns) do
    ~H"""
    <.link href="#" class="flex items-start" aria-current="step">
      <span class="relative flex h-5 w-5 flex-shrink-0 items-center justify-center" aria-hidden="true">
        <span class="absolute h-5 w-5 rounded-full bg-success/25 animate-pulse"></span>
        <span class="relative block h-2 w-2 rounded-full bg-success"></span>
      </span>
      <span class="ml-3 text-sm font-medium text-muted-foreground group-hover:text-muted">
        {@achievement.name}
      </span>
    </.link>
    """
  end

  def handle_event("handle_tech_input", %{"key" => "Enter", "value" => tech}, socket)
      when byte_size(tech) > 0 do
    tech_stack = [String.trim(tech) | socket.assigns.tech_stack] |> Enum.uniq()

    {:noreply,
     socket
     |> assign(:tech_stack, tech_stack)
     |> assign(:bounties, Bounties.list_bounties(tech_stack: tech_stack, limit: 10))
     |> push_event("clear-input", %{selector: "[phx-keydown='handle_tech_input']"})}
  end

  def handle_event("handle_tech_input", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("remove_tech", %{"tech" => tech}, socket) do
    tech_stack = List.delete(socket.assigns.tech_stack, tech)

    {:noreply,
     socket
     |> assign(:tech_stack, tech_stack)
     |> assign(:bounties, Bounties.list_bounties(tech_stack: tech_stack, limit: 10))}
  end

  def handle_event("view_mode", %{"value" => mode}, socket) do
    {:noreply, assign(socket, :view_mode, mode)}
  end

  def handle_event("begin", %{"org" => _org_handle}, socket) do
    # TODO: Implement contract acceptance logic
    {:noreply, socket}
  end

  def handle_event("begin_collaboration", _, socket) do
    {:noreply, socket |> assign(:show_begin_collaboration_drawer, true)}
  end

  def handle_event("submit_collaboration", _params, socket) do
    # TODO: Implement payment method addition and collaboration initiation
    {:noreply, socket |> redirect(to: ~p"/contracts/123")}
  end

  def handle_event("close_drawer", _, socket) do
    {:noreply, socket |> assign(:show_begin_collaboration_drawer, false)}
  end

  def handle_event("validate_job", %{"job_form" => params}, socket) do
    form =
      %JobForm{}
      |> JobForm.changeset(params)
      |> Map.put(:action, :validate)
      |> to_form(as: :job_form)

    {:noreply, assign(socket, job_form: form)}
  end

  def handle_event("create_job", %{"job_form" => params}, socket) do
    case JobForm.changeset(params) do
      {:ok, job} ->
        {:noreply,
         socket
         |> put_flash(:info, "Job created successfully")
         |> redirect(to: ~p"/jobs/#{job}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, job_form: to_form(changeset, as: :job_form))}
    end
  end

  def compact_view(assigns) do
    ~H"""
    <tr class="border-b transition-colors hover:bg-muted/10">
      <td class="py-1 px-4 align-middle">
        <div class="flex items-center gap-4">
          <div class="font-display text-base font-semibold text-success whitespace-nowrap shrink-0">
            {Money.to_string!(@bounty.amount)}
          </div>

          <.link
            href={Bounty.url(@bounty)}
            class="truncate text-sm text-foreground hover:underline max-w-[400px]"
          >
            {@bounty.ticket.title}
          </.link>

          <div class="flex items-center gap-1 text-sm text-muted-foreground whitespace-nowrap shrink-0">
            <.link href={~p"/org/#{@bounty.owner.handle}"} class="font-semibold hover:underline">
              {@bounty.owner.name}
            </.link>
            <.icon name="tabler-chevron-right" class="h-4 w-4" />
            <.link href={Bounty.url(@bounty)} class="hover:underline">
              {Bounty.path(@bounty)}
            </.link>
          </div>
        </div>
      </td>
    </tr>
    """
  end

  def contract(assigns) do
    ~H"""
    <tr class="border-b transition-colors">
      <td class="py-4 align-middle">
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-4">
            <.link href={~p"/org/#{@contract.client.handle}"}>
              <.avatar class="h-32 w-auto aspect-[1200/630] rounded-lg">
                <.avatar_image
                  src={@contract.client.og_image_url || @contract.client.avatar_url}
                  alt={@contract.client.name}
                  class="object-cover"
                />
                <.avatar_fallback class="rounded-lg"></.avatar_fallback>
              </.avatar>
            </.link>

            <div class="flex flex-col gap-1">
              <div class="flex items-center gap-1 text-base text-foreground">
                <.link
                  href={~p"/org/#{@contract.client.handle}"}
                  class="font-semibold hover:underline"
                >
                  {@contract.client.og_title || @contract.client.name}
                </.link>
              </div>
              <div class="text-muted-foreground line-clamp-2">
                {@contract.client.bio}
              </div>

              <div class="group flex items-center gap-2">
                <div class="font-display text-xl font-semibold text-success">
                  {Money.to_string!(@contract.hourly_rate_min)} - {Money.to_string!(
                    @contract.hourly_rate_max
                  )}/hr
                </div>
                <span class="text-sm text-muted-foreground">
                  · {@contract.hours_per_week} hours/week
                </span>
              </div>

              <div class="mt-1 flex flex-wrap gap-2">
                <%= for tag <- @contract.client.tech_stack do %>
                  <div class="ring-foreground/25 ring-1 ring-inset bg-foreground/5 text-foreground rounded-lg px-2 py-1 text-xs font-medium">
                    {tag}
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </td>
    </tr>
    """
  end

  def default_view(assigns) do
    ~H"""
    <tr class="border-b transition-colors hover:bg-muted/10">
      <td class="p-4 align-middle">
        <div class="flex items-center gap-4">
          <.link href={~p"/org/#{@bounty.owner.handle}"}>
            <.avatar class="h-14 w-14 rounded-xl">
              <.avatar_image src={@bounty.owner.avatar_url} alt={@bounty.owner.name} />
              <.avatar_fallback>
                {String.first(@bounty.owner.name)}
              </.avatar_fallback>
            </.avatar>
          </.link>

          <div class="flex flex-col gap-1">
            <div class="flex items-center gap-1 text-sm text-muted-foreground">
              <.link href={~p"/org/#{@bounty.owner.handle}"} class="font-semibold hover:underline">
                {@bounty.owner.name}
              </.link>
              <.icon name="tabler-chevron-right" class="h-4 w-4" />
              <.link href={Bounty.url(@bounty)} class="hover:underline">
                {Bounty.path(@bounty)}
              </.link>
            </div>

            <.link href={Bounty.url(@bounty)} class="group flex items-center gap-2">
              <div class="font-display text-xl font-semibold text-success">
                {Money.to_string!(@bounty.amount)}
              </div>
              <div class="text-foreground group-hover:underline line-clamp-1">
                {@bounty.ticket.title}
              </div>
            </.link>

            <div class="flex flex-wrap gap-2">
              <%= for tag <- @bounty.tech_stack do %>
                <span class="text-sm text-muted-foreground">
                  #{tag}
                </span>
              <% end %>
            </div>
          </div>
        </div>
      </td>
    </tr>
    """
  end

  def matching_dev(assigns) do
    ~H"""
    <tr class="border-b transition-colors">
      <td class="py-4 align-middle">
        <div class="flex items-center justify-between gap-4">
          <div class="flex items-start gap-4">
            <.link href={~p"/org/#{@user.handle}"}>
              <.avatar class="h-20 w-20 rounded-full">
                <.avatar_image src={@user.avatar_url} alt={@user.name} />
                <.avatar_fallback class="rounded-lg"></.avatar_fallback>
              </.avatar>
            </.link>

            <div class="flex flex-col gap-1">
              <div class="flex items-center gap-1 text-base text-foreground">
                <.link href={~p"/org/#{@user.handle}"} class="font-semibold hover:underline">
                  {@user.name}
                </.link>
              </div>

              <div class="group flex items-center gap-2">
                <div class="font-display text-xl font-semibold text-success">
                  {Money.to_string!(@user.hourly_rate_max)}/hr
                </div>
              </div>

              <div class="mt-1 flex flex-wrap gap-2">
                <%= for tech <- @user.tech_stack do %>
                  <div class="ring-foreground/25 ring-1 ring-inset bg-foreground/5 text-foreground rounded-lg px-2 py-1 text-xs font-medium">
                    {tech}
                  </div>
                <% end %>
              </div>
            </div>
          </div>
          <div class="max-w-xs w-full rounded-lg bg-card p-4 text-sm border border-border">
            <%= if @user.review do %>
              <div class="flex items-center gap-1 mb-2">
                <%= for i <- 1..5 do %>
                  <.icon
                    name="tabler-star-filled"
                    class={"w-4 h-4 #{if i <= @user.review.rating, do: "text-warning", else: "text-muted-foreground/25"}"}
                  />
                <% end %>
              </div>
              <p class="text-sm mb-2">{@user.review.content}</p>
              <div class="flex items-center gap-3">
                <.avatar class="h-8 w-8">
                  <.avatar_image
                    src={@user.review.reviewer.avatar_url}
                    alt={@user.review.reviewer.name}
                  />
                  <.avatar_fallback>
                    {String.first(@user.review.reviewer.name)}
                  </.avatar_fallback>
                </.avatar>
                <div class="flex flex-col">
                  <p class="text-sm font-medium">{@user.review.reviewer.name}</p>
                  <p class="text-xs text-muted-foreground">
                    {@user.review.organization.name}
                  </p>
                </div>
              </div>
            <% else %>
              <p class="text-muted-foreground text-center">No reviews yet</p>
            <% end %>
          </div>
        </div>
      </td>
    </tr>
    """
  end

  defp fetch_matching_devs(tech_stack) do
    developers =
      Users.list_developers(
        sort_by_tech_stack: tech_stack,
        limit: 3,
        min_earnings: Money.new!(200, "USD")
      )

    reviews = developers |> Enum.map(& &1.id) |> Reviews.get_top_reviews_for_users()
    developers |> Enum.map(fn dev -> Map.merge(dev, %{review: Map.get(reviews, dev.id)}) end)
  end
end
