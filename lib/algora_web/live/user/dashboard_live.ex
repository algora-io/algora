defmodule AlgoraWeb.User.DashboardLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

  import AlgoraWeb.Components.Achievement
  import AlgoraWeb.Components.Bounties
  import Ecto.Changeset

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Bounties
  alias Algora.Github
  alias Algora.Payments
  alias Algora.Payments.Account
  alias Algora.Repo

  defmodule SettingsForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :tech_stack, {:array, :string}
    end

    def changeset(form, attrs) do
      cast(form, attrs, [:tech_stack])
    end
  end

  defmodule AvailabilityForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :hourly_rate_min, :integer
      field :hours_per_week, :integer
    end

    def changeset(form, attrs) do
      form
      |> cast(attrs, [:hourly_rate_min, :hours_per_week])
      |> validate_required([:hourly_rate_min, :hours_per_week])
      |> validate_number(:hourly_rate_min, greater_than: 0)
      |> validate_number(:hours_per_week, greater_than: 0, less_than_or_equal_to: 40)
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Bounties.subscribe()
    end

    contracts = Algora.Contracts.list_contracts(status: :draft, contractor_id: socket.assigns.current_user.id)

    has_active_account =
      case Payments.get_account(socket.assigns.current_user) do
        %Account{payouts_enabled: true} -> true
        _ -> false
      end

    settings_form =
      %SettingsForm{}
      |> SettingsForm.changeset(%{tech_stack: socket.assigns.current_user.tech_stack})
      |> to_form()

    availability_form =
      %AvailabilityForm{}
      |> AvailabilityForm.changeset(%{
        hourly_rate_min: socket.assigns.current_user.hourly_rate_min,
        hours_per_week: socket.assigns.current_user.hours_per_week
      })
      |> to_form()

    total_earned =
      case Accounts.fetch_developer_by(handle: socket.assigns.current_user.handle) do
        {:ok, user} -> user.total_earned
        _ -> Money.zero(:USD)
      end

    socket =
      socket
      |> assign(:authorize_url, Github.authorize_url())
      |> assign(:view_mode, "compact")
      |> assign(:contracts, contracts)
      |> assign(:has_fresh_token?, Accounts.has_fresh_token?(socket.assigns.current_user))
      |> assign(:has_active_account, has_active_account)
      |> assign(:settings_form, settings_form)
      |> assign(:availability_form, availability_form)
      |> assign(:total_earned, total_earned)
      |> assign_bounties()
      |> assign_achievements()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex lg:flex-row flex-col-reverse">
      <div class="flex-1 bg-background text-foreground lg:pr-96">
        <div :if={not @has_fresh_token?} class="p-4 sm:p-6 md:p-8">
          <.section>
            <.card>
              <.card_header>
                <.card_title>Connect GitHub account</.card_title>
                <.card_description>
                  Connect your GitHub account to personalize your experience and discover more opportunities
                </.card_description>
              </.card_header>
              <.card_content>
                <div class="flex flex-col gap-3">
                  <.button href={@authorize_url} class="ml-auto">
                    Connect with GitHub <.icon name="tabler-arrow-right" class="w-4 h-4 ml-2 -mr-1" />
                  </.button>
                </div>
              </.card_content>
            </.card>
          </.section>
        </div>
        <div :if={@has_fresh_token? and not @has_active_account} class="p-4 sm:p-6 md:p-8">
          <.section>
            <.card>
              <.card_header>
                <.card_title>Connect with Stripe</.card_title>
                <.card_description>
                  Connect your Stripe account to receive payments for bounties and contracts
                </.card_description>
              </.card_header>
              <.card_content>
                <div class="flex flex-col gap-3">
                  <.button navigate={~p"/user/transactions"} class="ml-auto">
                    Connect with Stripe <.icon name="tabler-arrow-right" class="w-4 h-4 ml-2 -mr-1" />
                  </.button>
                </div>
              </.card_content>
            </.card>
          </.section>
        </div>
        <!-- Contracts section -->
        <div :if={length(@contracts) > 0} class="p-4 sm:p-6 md:p-8">
          <div class="flex justify-between">
            <div class="flex flex-col space-y-1.5">
              <h2 class="text-2xl font-semibold leading-none tracking-tight">
                Hourly contracts
              </h2>
              <p class="text-sm text-muted-foreground">Paid out weekly</p>
            </div>
          </div>
          <div class="-ml-4">
            <div class="relative w-full overflow-auto">
              <table class="w-full caption-bottom text-sm">
                <tbody>
                  <%= for contract <- @contracts do %>
                    <.contract_card contract={contract} />
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
        <!-- Bounties section -->
        <div class="p-4 sm:p-6 md:p-8">
          <div class="flex items-end justify-between pb-2">
            <div class="flex flex-col space-y-1.5">
              <h2 class="text-2xl font-semibold leading-none tracking-tight">Open bounties</h2>
              <p class="text-sm text-muted-foreground">Bounties for you</p>
            </div>
          </div>
          <%= if length(@bounties) > 0 do %>
            <div id="bounties-container" phx-hook="InfiniteScroll">
              <.bounties bounties={@bounties} />
              <div :if={@has_more_bounties} class="flex justify-center mt-4" data-load-more-indicator>
                <div class="animate-pulse text-muted-foreground">
                  <.icon name="tabler-loader" class="h-6 w-6 animate-spin" />
                </div>
              </div>
            </div>
          <% else %>
            <.card class="text-center">
              <.card_header>
                <div class="mx-auto mb-2 rounded-full bg-muted p-4">
                  <.icon name="tabler-diamond" class="h-8 w-8 text-muted-foreground" />
                </div>
                <.card_title>No bounties for your tech stack</.card_title>
                <.card_description>
                  Update your tech stack to see bounties for other tech stacks
                </.card_description>
              </.card_header>
            </.card>
          <% end %>
        </div>
      </div>
      <!-- Sidebar -->
      <aside class="lg:fixed lg:top-16 lg:right-0 lg:bottom-0 lg:w-96 lg:overflow-y-auto scrollbar-thin lg:border-l lg:border-border lg:bg-background p-4 pt-6 sm:p-6 md:p-8">
        <!-- Availability Section -->
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2">
            <label for="available" class="text-sm font-medium">Open to contract work</label>
            <.tooltip>
              <.icon name="tabler-help-circle" class="h-4 w-4 text-muted-foreground" />
              <.tooltip_content side="bottom" class="min-w-[300px]">
                When enabled, you will receive contract work offers from companies on Algora.
              </.tooltip_content>
            </.tooltip>
          </div>
          <.switch
            id="available"
            name="available"
            value={@current_user.seeking_contracts}
            on_click={
              %JS{}
              |> JS.push("toggle_availability")
              |> JS.toggle(to: "#availability-details")
            }
          />
        </div>
        <.form
          for={@availability_form}
          id="availability-form"
          phx-change="validate_availability"
          phx-submit="save_availability"
          class={
            classes([
              "mt-4 grid grid-cols-1 lg:grid-cols-2 gap-4",
              @current_user.seeking_contracts || "hidden"
            ])
          }
        >
          <.input
            field={@availability_form[:hourly_rate_min]}
            label="Hourly Rate (USD)"
            icon="tabler-currency-dollar"
          />
          <.input
            field={@availability_form[:hours_per_week]}
            label="Hours per Week"
            icon="tabler-clock"
          />
          <.button
            :if={@availability_form.source.action == :validate}
            type="submit"
            class="lg:col-span-2"
          >
            Save
          </.button>
        </.form>
        <!-- Tech Stack Section -->
        <div class="mt-4">
          <h2 class="mb-2 text-xl font-semibold">
            Tech stack
          </h2>
          <.TechStack
            classes="mt-4"
            tech={get_field(@settings_form.source, :tech_stack)}
            socket={@socket}
            form="settings_form"
          />

          <.error :for={msg <- @settings_form[:tech_stack].errors |> Enum.map(&translate_error(&1))}>
            {msg}
          </.error>
        </div>
        <!-- Achievements Section -->
        <div :if={length(@achievements) > 1} class="hidden lg:block mt-8">
          <h2 class="text-xl font-semibold leading-none tracking-tight">Achievements</h2>
          <nav class="pt-4">
            <ol role="list" class="space-y-6">
              <%= for achievement <- @achievements do %>
                <li>
                  <.achievement achievement={achievement} />
                </li>
              <% end %>
            </ol>
          </nav>
        </div>
        <div
          :if={not incomplete?(@achievements, :earn_first_bounty_status)}
          class="hidden lg:block pt-12"
        >
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-semibold leading-none tracking-tight">Share your profile</h2>
          </div>
          <.badge
            id="og-url"
            phx-hook="CopyToClipboard"
            data-value={url(~p"/#{@current_user.handle}")}
            phx-click={
              %JS{}
              |> JS.hide(
                to: "#og-url-copy-icon",
                transition: {"transition-opacity", "opacity-100", "opacity-0"}
              )
              |> JS.show(
                to: "#og-url-check-icon",
                transition: {"transition-opacity", "opacity-0", "opacity-100"}
              )
            }
            class="relative cursor-pointer mt-3 text-foreground/90 hover:text-foreground"
            variant="outline"
          >
            <.icon
              id="og-url-copy-icon"
              name="tabler-copy"
              class="absolute left-1 my-auto size-4 mr-2"
            />
            <.icon
              id="og-url-check-icon"
              name="tabler-check"
              class="absolute left-1 my-auto hidden size-4 mr-2"
            />
            <span class="pl-4">{AlgoraWeb.Endpoint.host()}{~p"/#{@current_user.handle}"}</span>
          </.badge>
          <img
            src={~p"/og/@/#{@current_user.handle}"}
            alt={@current_user.name}
            class="mt-3 w-full aspect-[1200/630] rounded-lg ring-1 ring-input bg-black"
            loading="lazy"
          />
        </div>
      </aside>
    </div>
    """
  end

  defp assign_achievements(socket) do
    achievements = [
      {&personalize_status/1, "Personalize Algora", nil},
      {&connect_github_status/1, "Connect Github account", socket.assigns.authorize_url},
      {&setup_stripe_status/1, "Create Stripe account", ~p"/user/transactions"},
      {&earn_first_bounty_status/1, "Earn first bounty", ~p"/bounties"},
      {&share_with_friend_status/1, "Share Algora with a friend", nil}
    ]

    {achievements, _} =
      Enum.reduce_while(achievements, {[], false}, fn {status_fn, name, path}, {acc, found_current} ->
        id = Function.info(status_fn)[:name]
        status = status_fn.(socket)

        result =
          cond do
            found_current -> {acc ++ [%{id: id, status: :upcoming, name: name, path: path}], found_current}
            status == :completed -> {acc ++ [%{id: id, status: status, name: name, path: path}], false}
            true -> {acc ++ [%{id: id, status: :current, name: name, path: path}], true}
          end

        {:cont, result}
      end)

    assign(socket, :achievements, Enum.reject(achievements, &(&1.status == :completed)))
  end

  defp incomplete?(achievements, id) do
    Enum.any?(achievements, &(&1.id == id and &1.status != :completed))
  end

  defp personalize_status(_socket), do: :completed

  defp connect_github_status(socket) do
    if socket.assigns.has_fresh_token? do
      :completed
    else
      :upcoming
    end
  end

  defp setup_stripe_status(socket) do
    if socket.assigns.has_active_account do
      :completed
    else
      :upcoming
    end
  end

  defp earn_first_bounty_status(socket) do
    if Money.compare(socket.assigns.total_earned, Money.new!(0, :USD)) == :gt do
      :completed
    else
      :upcoming
    end
  end

  defp share_with_friend_status(_socket), do: :upcoming

  @impl true
  def handle_event("view_mode", %{"value" => mode}, socket) do
    {:noreply, assign(socket, :view_mode, mode)}
  end

  @impl true
  def handle_event("view_contract", %{"org" => _org_handle}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    {:noreply, assign_more_bounties(socket)}
  end

  @impl true
  def handle_event("tech_stack_changed", params, socket) do
    case socket.assigns.current_user
         |> User.settings_changeset(%{tech_stack: params["tech_stack"]})
         |> Repo.update() do
      {:ok, user} ->
        {:noreply, socket |> assign(:current_user, user) |> assign_bounties()}

      {:error, changeset} ->
        {:noreply, assign(socket, :settings_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("toggle_availability", _params, socket) do
    current_user = socket.assigns.current_user

    {:ok, user} = Accounts.update_settings(current_user, %{seeking_contracts: !current_user.seeking_contracts})

    {:noreply, assign(socket, :current_user, user)}
  end

  @impl true
  def handle_event("validate_availability", %{"availability_form" => params}, socket) do
    form =
      %AvailabilityForm{}
      |> AvailabilityForm.changeset(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, availability_form: form)}
  end

  @impl true
  def handle_event("save_availability", %{"availability_form" => params}, socket) do
    changeset =
      %AvailabilityForm{}
      |> AvailabilityForm.changeset(params)
      |> Map.put(:action, :validate)

    case changeset do
      %{valid?: true} ->
        case socket.assigns.current_user
             |> User.settings_changeset(params)
             |> Repo.update() do
          {:ok, user} ->
            {:noreply,
             socket
             |> put_flash(:info, "Availability updated!")
             |> assign(:current_user, user)
             |> assign(:availability_form, changeset |> Map.put(:action, nil) |> to_form())}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to update availability")}
        end

      %{valid?: false} ->
        {:noreply, assign(socket, availability_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_info(:bounties_updated, socket) do
    {:noreply, socket}
  end

  defp assign_bounties(socket) do
    query_opts = [
      status: :open,
      limit: page_size(),
      current_user: socket.assigns.current_user,
      tech_stack: socket.assigns.current_user.tech_stack,
      amount_gt: Money.new(:USD, 200)
    ]

    bounties = Bounties.list_bounties(query_opts)

    socket
    |> assign(:bounties, bounties)
    |> assign(:query_opts, query_opts)
    |> assign(:has_more_bounties, length(bounties) >= page_size())
  end

  defp assign_more_bounties(socket) do
    %{bounties: bounties} = socket.assigns

    query_opts =
      Keyword.put(socket.assigns.query_opts, :before, %{
        inserted_at: List.last(bounties).inserted_at,
        id: List.last(bounties).id
      })

    more_bounties = Bounties.list_bounties(query_opts)

    socket
    |> assign(:bounties, bounties ++ more_bounties)
    |> assign(:query_opts, query_opts)
    |> assign(:has_more_bounties, length(more_bounties) >= page_size())
  end

  defp page_size, do: 10

  defp contract_card(assigns) do
    ~H"""
    <tr class="border-b transition-colors hover:bg-muted/10">
      <td class="p-4 align-middle">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div class="flex flex-col sm:flex-row sm:items-center gap-4">
            <.link navigate={User.url(@contract.client)}>
              <.avatar class="aspect-[1200/630] h-32 w-auto rounded-lg">
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
                <.link navigate={User.url(@contract.client)} class="font-semibold hover:underline">
                  {@contract.client.og_title || @contract.client.name}
                </.link>
              </div>
              <div class="line-clamp-2 text-muted-foreground">
                {@contract.client.bio}
              </div>
              <div class="group flex items-center gap-2">
                <div class="font-display text-xl font-semibold text-success">
                  {Money.to_string!(@contract.hourly_rate)}/hr
                </div>
                <span class="text-sm text-muted-foreground">
                  · {@contract.hours_per_week} hours/week
                </span>
              </div>

              <div class="mt-1 flex flex-wrap gap-2">
                <%= for tag <- @contract.client.tech_stack || [] do %>
                  <div class="rounded-lg bg-foreground/5 px-2 py-1 text-xs font-medium text-foreground ring-1 ring-inset ring-foreground/25">
                    {tag}
                  </div>
                <% end %>
              </div>
            </div>
          </div>

          <div class="flex flex-col items-start sm:items-end gap-3">
            <div class="hidden sm:block sm:text-right">
              <div class="whitespace-nowrap text-sm text-muted-foreground">Total contract value</div>
              <div class="font-display text-lg font-semibold text-foreground">
                {Money.to_string!(Money.mult!(@contract.hourly_rate, @contract.hours_per_week))} / wk
              </div>
            </div>
            <.button
              navigate={~p"/#{@contract.client.handle}/contracts/#{@contract.id}"}
              phx-click="view_contract"
              phx-value-org={@contract.client.handle}
              size="sm"
            >
              View contract
            </.button>
          </div>
        </div>
      </td>
    </tr>
    """
  end
end
