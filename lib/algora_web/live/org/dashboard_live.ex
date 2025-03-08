defmodule AlgoraWeb.Org.DashboardLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.Achievement
  import Ecto.Changeset

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Bounties
  alias Algora.Contracts
  alias Algora.Github
  alias Algora.Types.USD
  alias Algora.Validations
  alias Algora.Workspace
  alias AlgoraWeb.Components.Logos

  require Logger

  defmodule BountyForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    embedded_schema do
      field :url, :string
      field :amount, USD

      embeds_one :ticket_ref, TicketRef, primary_key: false do
        field :owner, :string
        field :repo, :string
        field :number, :integer
        field :type, :string
      end
    end

    def changeset(form, attrs \\ %{}) do
      form
      |> cast(attrs, [:url, :amount])
      |> validate_required([:url, :amount])
      |> Validations.validate_money_positive(:amount)
      |> Validations.validate_ticket_ref(:url, :ticket_ref)
    end
  end

  defmodule TipForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    embedded_schema do
      field :github_handle, :string
      field :amount, USD
    end

    def changeset(form, attrs \\ %{}) do
      form
      |> cast(attrs, [:github_handle, :amount])
      |> validate_required([:github_handle, :amount])
      |> Validations.validate_money_positive(:amount)
    end
  end

  defmodule ContractForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    embedded_schema do
      field :hourly_rate, USD
      field :hours_per_week, :integer
    end

    def changeset(form, attrs) do
      form
      |> cast(attrs, [:hourly_rate, :hours_per_week])
      |> validate_required([:hourly_rate, :hours_per_week])
      |> Validations.validate_money_positive(:hourly_rate)
      |> validate_number(:hours_per_week, greater_than: 0, less_than_or_equal_to: 40)
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    %{current_org: current_org} = socket.assigns

    if socket.assigns.current_user_role in [:admin, :mod] do
      top_earners = Accounts.list_developers(org_id: current_org.id, earnings_gt: Money.zero(:USD))

      installations = Workspace.list_installations_by(connected_user_id: current_org.id, provider: "github")

      if connected?(socket) do
        Phoenix.PubSub.subscribe(Algora.PubSub, "auth:#{socket.id}")
      end

      {:ok,
       socket
       |> assign(:has_fresh_token?, Accounts.has_fresh_token?(socket.assigns.current_user))
       |> assign(:installations, installations)
       |> assign(:matching_devs, top_earners)
       |> assign(:oauth_url, Github.authorize_url(%{socket_id: socket.id}))
       |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
       |> assign(:tip_form, to_form(TipForm.changeset(%TipForm{}, %{})))
       |> assign(:contract_form, to_form(ContractForm.changeset(%ContractForm{}, %{})))
       |> assign(:show_contract_modal, false)
       |> assign(:selected_developer, nil)
       |> assign_contracts()
       |> assign_achievements()}
    else
      {:ok, redirect(socket, to: ~p"/org/#{current_org.handle}/home")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="lg:pr-96">
      <div class="container mx-auto max-w-7xl space-y-8 p-8">
        <.section :if={@installations == []}>
          <.card>
            <.card_header>
              <.card_title>GitHub Integration</.card_title>
              <.card_description :if={@installations == []}>
                Install the Algora app to enable slash commands in your GitHub repositories
              </.card_description>
            </.card_header>
            <.card_content>
              <div class="flex flex-col gap-3">
                <%= if @installations != [] do %>
                  <%= for installation <- @installations do %>
                    <div class="flex items-center gap-2">
                      <img src={installation.avatar_url} class="w-9 h-9 rounded-lg" />
                      <div>
                        <p class="font-medium">{installation.provider_meta["account"]["login"]}</p>
                        <p class="text-sm text-muted-foreground">
                          Algora app is installed in
                          <strong>{installation.repository_selection}</strong>
                          repositories
                        </p>
                      </div>
                    </div>
                  <% end %>
                  <.button phx-click="install_app" class="ml-auto gap-2">
                    <Logos.github class="w-4 h-4 mr-2 -ml-1" />
                    Manage {ngettext("installation", "installations", length(@installations))}
                  </.button>
                <% else %>
                  <div class="flex flex-col gap-2">
                    <.button phx-click="install_app" class="ml-auto gap-2">
                      <Logos.github class="w-4 h-4 mr-2 -ml-1" /> Install GitHub App
                    </.button>
                  </div>
                <% end %>
              </div>
            </.card_content>
          </.card>
        </.section>

        <.section>
          <div class="grid grid-cols-1 gap-8 md:grid-cols-2">
            {create_bounty(assigns)}
            {create_tip(assigns)}
          </div>
        </.section>

        <div :if={@matching_devs != []} class="relative h-full">
          <div class="flex flex-col space-y-1.5">
            <h2 class="text-2xl font-semibold leading-none tracking-tight">
              Contracts
            </h2>
            <p class="text-sm text-muted-foreground">
              Engage top-performing developers with contract opportunities
            </p>
          </div>
          <div class="pt-3 relative w-full overflow-auto">
            <table class="w-full caption-bottom text-sm">
              <tbody>
                <%= for user <- @matching_devs do %>
                  <.matching_dev user={user} contracts={@contracts} current_org={@current_org} />
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    {sidebar(assigns)}
    <.drawer show={@show_contract_modal} direction="right" on_cancel="close_contract_drawer">
      <.drawer_header :if={@selected_developer}>
        <.drawer_title>Offer Contract</.drawer_title>
        <.drawer_description>
          Once you send an offer, {@selected_developer.name} will be notified and can accept or decline.
        </.drawer_description>
      </.drawer_header>
      <.drawer_content :if={@selected_developer} class="mt-4">
        <.form for={@contract_form} phx-change="validate_contract" phx-submit="create_contract">
          <div class="flex flex-col gap-8">
            <.card>
              <.card_header>
                <.card_title>Developer</.card_title>
              </.card_header>
              <.card_content>
                <div class="flex items-start gap-4">
                  <.avatar class="h-20 w-20 rounded-full">
                    <.avatar_image
                      src={@selected_developer.avatar_url}
                      alt={@selected_developer.name}
                    />
                    <.avatar_fallback class="rounded-lg"></.avatar_fallback>
                  </.avatar>

                  <div>
                    <div class="flex items-center gap-1 text-base text-foreground">
                      <span class="font-semibold">{@selected_developer.name}</span>
                    </div>

                    <div
                      :if={@selected_developer.provider_meta}
                      class="pt-0.5 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground sm:text-sm"
                    >
                      <.link
                        :if={@selected_developer.provider_login}
                        href={"https://github.com/#{@selected_developer.provider_login}"}
                        target="_blank"
                        class="flex items-center gap-1 hover:underline"
                      >
                        <Logos.github class="h-4 w-4" />
                        <span class="whitespace-nowrap">{@selected_developer.provider_login}</span>
                      </.link>
                      <.link
                        :if={@selected_developer.provider_meta["twitter_handle"]}
                        href={"https://x.com/#{@selected_developer.provider_meta["twitter_handle"]}"}
                        target="_blank"
                        class="flex items-center gap-1 hover:underline"
                      >
                        <.icon name="tabler-brand-x" class="h-4 w-4" />
                        <span class="whitespace-nowrap">
                          {@selected_developer.provider_meta["twitter_handle"]}
                        </span>
                      </.link>
                      <div
                        :if={@selected_developer.provider_meta["location"]}
                        class="flex items-center gap-1"
                      >
                        <.icon name="tabler-map-pin" class="h-4 w-4" />
                        <span class="whitespace-nowrap">
                          {@selected_developer.provider_meta["location"]}
                        </span>
                      </div>
                      <div
                        :if={@selected_developer.provider_meta["company"]}
                        class="flex items-center gap-1"
                      >
                        <.icon name="tabler-building" class="h-4 w-4" />
                        <span class="whitespace-nowrap">
                          {@selected_developer.provider_meta["company"] |> String.trim_leading("@")}
                        </span>
                      </div>
                    </div>

                    <div class="pt-1.5 flex flex-wrap gap-2">
                      <%= for tech <- @selected_developer.tech_stack do %>
                        <div class="rounded-lg bg-foreground/5 px-2 py-1 text-xs font-medium text-foreground ring-1 ring-inset ring-foreground/25">
                          {tech}
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
              </.card_content>
            </.card>

            <.card>
              <.card_header>
                <.card_title>Contract Details</.card_title>
              </.card_header>
              <.card_content>
                <div class="space-y-4">
                  <.input
                    label="Hourly Rate"
                    icon="tabler-currency-dollar"
                    field={@contract_form[:hourly_rate]}
                  />
                  <.input label="Hours per Week" field={@contract_form[:hours_per_week]} />
                </div>
              </.card_content>
            </.card>

            <div class="ml-auto flex gap-4">
              <.button variant="secondary" phx-click="close_contract_drawer" type="button">
                Cancel
              </.button>
              <.button type="submit">
                Send Contract Offer <.icon name="tabler-arrow-right" class="-mr-1 ml-2 h-4 w-4" />
              </.button>
            </div>
          </div>
        </.form>
      </.drawer_content>
    </.drawer>
    """
  end

  defp matching_dev(assigns) do
    ~H"""
    <tr class="border-b transition-colors">
      <td class="py-4 align-middle">
        <div class="flex items-center justify-between gap-4">
          <div class="flex items-start gap-4">
            <.link navigate={User.url(@user)}>
              <.avatar class="h-20 w-20 rounded-full">
                <.avatar_image src={@user.avatar_url} alt={@user.name} />
                <.avatar_fallback class="rounded-lg"></.avatar_fallback>
              </.avatar>
            </.link>

            <div>
              <div class="flex items-center gap-1 text-base text-foreground">
                <.link navigate={User.url(@user)} class="font-semibold hover:underline">
                  {@user.name}
                </.link>
              </div>

              <div
                :if={@user.provider_meta}
                class="pt-0.5 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground sm:text-sm"
              >
                <.link
                  :if={@user.provider_login}
                  href={"https://github.com/#{@user.provider_login}"}
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <Logos.github class="h-4 w-4" />
                  <span class="whitespace-nowrap">{@user.provider_login}</span>
                </.link>
                <.link
                  :if={@user.provider_meta["twitter_handle"]}
                  href={"https://x.com/#{@user.provider_meta["twitter_handle"]}"}
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <.icon name="tabler-brand-x" class="h-4 w-4" />
                  <span class="whitespace-nowrap">{@user.provider_meta["twitter_handle"]}</span>
                </.link>
                <div :if={@user.provider_meta["location"]} class="flex items-center gap-1">
                  <.icon name="tabler-map-pin" class="h-4 w-4" />
                  <span class="whitespace-nowrap">{@user.provider_meta["location"]}</span>
                </div>
                <div :if={@user.provider_meta["company"]} class="flex items-center gap-1">
                  <.icon name="tabler-building" class="h-4 w-4" />
                  <span class="whitespace-nowrap">
                    {@user.provider_meta["company"] |> String.trim_leading("@")}
                  </span>
                </div>
              </div>

              <div class="pt-1.5 flex flex-wrap gap-2">
                <%= for tech <- @user.tech_stack do %>
                  <div class="rounded-lg bg-foreground/5 px-2 py-1 text-xs font-medium text-foreground ring-1 ring-inset ring-foreground/25">
                    {tech}
                  </div>
                <% end %>
              </div>
            </div>
          </div>
          <%= if contract_for_user(@contracts, @user) do %>
            <.button
              variant="secondary"
              navigate={
                ~p"/org/#{@current_org.handle}/contracts/#{contract_for_user(@contracts, @user).id}"
              }
            >
              View contract
            </.button>
          <% else %>
            <.button phx-click="offer_contract" phx-value-user_id={@user.id}>
              Offer contract
            </.button>
          <% end %>
        </div>
      </td>
    </tr>
    """
  end

  defp contract_for_user(contracts, user) do
    Enum.find(contracts, fn contract -> contract.contractor_id == user.id end)
  end

  defp create_bounty(assigns) do
    ~H"""
    <.card>
      <.card_header>
        <div class="flex items-center gap-3">
          <.icon name="tabler-diamond" class="h-8 w-8" />
          <h2 class="text-2xl font-semibold">Post a bounty</h2>
        </div>
      </.card_header>
      <.card_content>
        <.simple_form for={@bounty_form} phx-submit="create_bounty">
          <div class="flex flex-col gap-6">
            <.input
              label="URL"
              field={@bounty_form[:url]}
              placeholder="https://github.com/swift-lang/swift/issues/1337"
            />
            <.input label="Amount" icon="tabler-currency-dollar" field={@bounty_form[:amount]} />
            <p class="text-sm text-muted-foreground">
              <span class="font-semibold">Tip:</span>
              You can also create bounties directly on
              GitHub by commenting <code class="px-1 py-0.5 text-success">/bounty $100</code>
              on any issue.
            </p>
            <div class="flex justify-end gap-4">
              <.button>Submit</.button>
            </div>
          </div>
        </.simple_form>
      </.card_content>
    </.card>
    """
  end

  defp create_tip(assigns) do
    ~H"""
    <.card>
      <.card_header>
        <div class="flex items-center gap-3">
          <.icon name="tabler-gift" class="h-8 w-8" />
          <h2 class="text-2xl font-semibold">Tip a developer</h2>
        </div>
      </.card_header>
      <.card_content>
        <.simple_form for={@tip_form} phx-submit="create_tip">
          <div class="flex flex-col gap-6">
            <.input label="GitHub handle" field={@tip_form[:github_handle]} placeholder="jsmith" />
            <.input label="Amount" icon="tabler-currency-dollar" field={@tip_form[:amount]} />
            <p class="text-sm text-muted-foreground">
              <span class="font-semibold">Tip:</span>
              You can also create tips directly on
              GitHub by commenting <code class="px-1 py-0.5 text-success">/tip $100 @username</code>
              on any pull request.
            </p>
            <div class="flex justify-end gap-4">
              <.button>Submit</.button>
            </div>
          </div>
        </.simple_form>
      </.card_content>
    </.card>
    """
  end

  defp sidebar(assigns) do
    ~H"""
    <aside class="scrollbar-thin fixed top-16 right-0 bottom-0 hidden w-96 overflow-y-auto border-l border-border bg-background p-4 pt-6 sm:p-6 md:p-8 lg:block">
      <div class="flex items-center justify-between">
        <h2 class="text-xl font-semibold leading-none tracking-tight">Getting started</h2>
      </div>
      <nav class="pt-6">
        <ol role="list" class="space-y-6">
          <%= for achievement <- @achievements do %>
            <li>
              <.achievement achievement={achievement} />
            </li>
          <% end %>
        </ol>
      </nav>
    </aside>
    """
  end

  @impl true
  def handle_info({:authenticated, user}, socket) do
    socket =
      socket
      |> assign(:current_user, user)
      |> assign(:has_fresh_token?, true)

    case socket.assigns.pending_action do
      {event, params} ->
        socket = assign(socket, :pending_action, nil)
        handle_event(event, params, socket)

      nil ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("install_app" = event, unsigned_params, socket) do
    {:noreply,
     if socket.assigns.has_fresh_token? do
       redirect(socket, external: Github.install_url_select_target())
     else
       socket
       |> assign(:pending_action, {event, unsigned_params})
       |> push_event("open_popup", %{url: socket.assigns.oauth_url})
     end}
  end

  def handle_event("create_bounty" = event, %{"bounty_form" => params} = unsigned_params, socket) do
    if socket.assigns.has_fresh_token? do
      changeset =
        %BountyForm{}
        |> BountyForm.changeset(params)
        |> Map.put(:action, :validate)

      amount = get_field(changeset, :amount)
      ticket_ref = get_field(changeset, :ticket_ref)

      with %{valid?: true} <- changeset,
           {:ok, _bounty} <-
             Bounties.create_bounty(%{
               creator: socket.assigns.current_user,
               owner: socket.assigns.current_user,
               amount: amount,
               ticket_ref: ticket_ref
             }) do
        {:noreply,
         socket
         |> assign_achievements()
         |> put_flash(:info, "Bounty created")}
      else
        %{valid?: false} ->
          {:noreply, assign(socket, :bounty_form, to_form(changeset))}

        {:error, :already_exists} ->
          {:noreply, put_flash(socket, :warning, "You have already created a bounty for this ticket")}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, "Something went wrong")}
      end
    else
      {:noreply,
       socket
       |> assign(:pending_action, {event, unsigned_params})
       |> push_event("open_popup", %{url: socket.assigns.oauth_url})}
    end
  end

  def handle_event("create_tip" = event, %{"tip_form" => params} = unsigned_params, socket) do
    if socket.assigns.has_fresh_token? do
      changeset =
        %TipForm{}
        |> TipForm.changeset(params)
        |> Map.put(:action, :validate)

      with %{valid?: true} <- changeset,
           {:ok, token} <- Accounts.get_access_token(socket.assigns.current_user),
           {:ok, recipient} <- Workspace.ensure_user(token, get_field(changeset, :github_handle)),
           {:ok, checkout_url} <-
             Bounties.create_tip(%{
               creator: socket.assigns.current_user,
               owner: socket.assigns.current_user,
               recipient: recipient,
               amount: get_field(changeset, :amount)
             }) do
        {:noreply, redirect(socket, external: checkout_url)}
      else
        %{valid?: false} ->
          {:noreply, assign(socket, :tip_form, to_form(changeset))}

        {:error, reason} ->
          Logger.error("Failed to create tip: #{inspect(reason)}")
          {:noreply, put_flash(socket, :error, "Something went wrong")}
      end
    else
      {:noreply,
       socket
       |> assign(:pending_action, {event, unsigned_params})
       |> push_event("open_popup", %{url: socket.assigns.oauth_url})}
    end
  end

  def handle_event("offer_contract", %{"user_id" => user_id}, socket) do
    developer = Enum.find(socket.assigns.matching_devs, &(&1.id == user_id))

    {:noreply,
     socket
     |> assign(:selected_developer, developer)
     |> assign(:show_contract_modal, true)}
  end

  def handle_event("offer_contract", _params, socket) do
    # When no user_id is provided, use the user from the current row
    {:noreply, put_flash(socket, :error, "Please select a developer first")}
  end

  def handle_event("close_contract_drawer", _params, socket) do
    {:noreply, assign(socket, :show_contract_modal, false)}
  end

  def handle_event("validate_contract", %{"contract_form" => params}, socket) do
    changeset =
      %ContractForm{}
      |> ContractForm.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :contract_form, to_form(changeset))}
  end

  def handle_event("create_contract", %{"contract_form" => params}, socket) do
    changeset = ContractForm.changeset(%ContractForm{}, params)

    case apply_action(changeset, :save) do
      {:ok, data} ->
        contract_params = %{
          client_id: socket.assigns.current_org.id,
          contractor_id: socket.assigns.selected_developer.id,
          hourly_rate: data.hourly_rate,
          hours_per_week: data.hours_per_week,
          status: :draft
        }

        case Contracts.create_contract(contract_params) do
          {:ok, _contract} ->
            # TODO: send email
            {:noreply,
             socket
             |> assign(:show_contract_modal, false)
             |> assign_contracts()
             |> put_flash(:info, "Contract offer sent to #{socket.assigns.selected_developer.name}")}

          {:error, changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to create contract: #{inspect(changeset.errors)}")}
        end

      {:error, changeset} ->
        {:noreply, assign(socket, :contract_form, to_form(changeset))}
    end
  end

  defp assign_contracts(socket) do
    contracts = Contracts.list_contracts(client_id: socket.assigns.current_org.id, status: :draft)

    assign(socket, :contracts, contracts)
  end

  defp assign_achievements(socket) do
    status_fns = [
      {&personalize_status/1, "Personalize Algora"},
      {&install_app_status/1, "Install the Algora app"},
      {&create_bounty_status/1, "Create a bounty"},
      {&reward_bounty_status/1, "Reward a bounty"},
      {&begin_collaboration_status/1, "Contract a contributor"},
      {&complete_first_contract_status/1, "Complete a contract"}
    ]

    {achievements, _} =
      Enum.reduce_while(status_fns, {[], false}, fn {status_fn, name}, {acc, found_current} ->
        status = status_fn.(socket)

        result =
          cond do
            found_current -> {acc ++ [%{status: status, name: name}], found_current}
            status == :completed -> {acc ++ [%{status: status, name: name}], false}
            true -> {acc ++ [%{status: :current, name: name}], true}
          end

        {:cont, result}
      end)

    assign(socket, :achievements, achievements)
  end

  defp personalize_status(_socket), do: :completed

  defp install_app_status(socket) do
    case socket.assigns.installations do
      [] -> :upcoming
      _ -> :completed
    end
  end

  defp create_bounty_status(socket) do
    case Bounties.list_bounties(owner_id: socket.assigns.current_user.id, limit: 1) do
      [] -> :upcoming
      _ -> :completed
    end
  end

  defp reward_bounty_status(socket) do
    case Bounties.list_bounties(owner_id: socket.assigns.current_user.id, status: :paid, limit: 1) do
      [] -> :upcoming
      _ -> :completed
    end
  end

  defp begin_collaboration_status(socket) do
    case Contracts.list_contracts(client_id: socket.assigns.current_user.id, active_or_paid?: true, limit: 1) do
      [] -> :upcoming
      _ -> :completed
    end
  end

  defp complete_first_contract_status(socket) do
    case Contracts.list_contracts(client_id: socket.assigns.current_user.id, status: :paid, limit: 1) do
      [] -> :upcoming
      _ -> :completed
    end
  end
end
