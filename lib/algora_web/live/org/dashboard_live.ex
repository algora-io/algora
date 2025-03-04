defmodule AlgoraWeb.Org.DashboardLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.Achievement
  import AlgoraWeb.Components.Experts
  import Ecto.Changeset

  alias Algora.Accounts
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

  @impl true
  def mount(_params, _session, socket) do
    %{current_org: current_org} = socket.assigns

    if socket.assigns.current_user_role in [:admin, :mod] do
      experts =
        current_org.tech_stack
        |> List.first()
        |> Accounts.list_experts()
        |> Enum.take(6)

      installations = Workspace.list_installations_by(connected_user_id: current_org.id, provider: "github")

      if connected?(socket) do
        Phoenix.PubSub.subscribe(Algora.PubSub, "auth:#{socket.id}")
      end

      {:ok,
       socket
       |> assign(:installations, installations)
       |> assign(:oauth_url, Github.authorize_url(%{socket_id: socket.id}))
       |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
       |> assign(:tip_form, to_form(TipForm.changeset(%TipForm{}, %{})))
       |> assign(:experts, experts)
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

        <.section :if={@installations != []}>
          <div class="grid grid-cols-1 gap-8 md:grid-cols-2">
            {create_bounty(assigns)}
            {create_tip(assigns)}
          </div>
        </.section>

        <.section
          :if={@experts != []}
          title="Experts"
          subtitle="Meet the experts on Algora"
          link={~p"/experts"}
        >
          <ul class="flex flex-col gap-8 md:grid md:grid-cols-2 xl:grid-cols-3">
            <.experts experts={@experts} />
          </ul>
        </.section>
      </div>
    </div>
    {sidebar(assigns)}
    """
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
    {:noreply, socket |> assign(:current_user, user) |> redirect(external: Github.install_url_select_target())}
  end

  @impl true
  def handle_event("install_app", _params, socket) do
    # TODO: immediately redirect to install_url if user has valid token
    {:noreply, push_event(socket, "open_popup", %{url: socket.assigns.oauth_url})}
  end

  def handle_event("create_bounty", %{"bounty_form" => params}, socket) do
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
  end

  def handle_event("create_tip", %{"tip_form" => params}, socket) do
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
