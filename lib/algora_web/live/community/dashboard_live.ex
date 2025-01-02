defmodule AlgoraWeb.Community.DashboardLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.Achievement
  import AlgoraWeb.Components.Bounties
  import AlgoraWeb.Components.Experts
  import Ecto.Changeset

  alias Algora.Bounties
  alias Algora.Contracts
  alias Algora.Github
  alias Algora.Types.USD
  alias Algora.Users
  alias Algora.Validations
  alias Algora.Workspace

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

  def mount(_params, _session, socket) do
    experts =
      socket.assigns.current_user.tech_stack
      |> List.first()
      |> Users.list_experts()
      |> Enum.take(6)

    if connected?(socket) do
      Bounties.subscribe()
    end

    {:ok,
     socket
     |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
     |> assign(:tip_form, to_form(TipForm.changeset(%TipForm{}, %{})))
     |> assign(:experts, experts)
     |> assign_tickets()
     |> assign_achievements()}
  end

  def render(assigns) do
    ~H"""
    <div class="lg:pr-96">
      <div class="container mx-auto max-w-7xl space-y-8 p-8">
        <.section>
          <div class="grid grid-cols-1 gap-8 md:grid-cols-2">
            {create_bounty(assigns)}
            {create_tip(assigns)}
          </div>
        </.section>

        <.section title="Open bounties" subtitle="Bounties for you" link={~p"/bounties"}>
          <%= if Enum.empty?(@tickets) do %>
            <.card class="rounded-lg bg-card py-12 text-center lg:rounded-[2rem]">
              <.card_header>
                <div class="mx-auto mb-2 rounded-full bg-muted p-4">
                  <.icon name="tabler-diamond" class="h-8 w-8 text-muted-foreground" />
                </div>
                <.card_title>No bounties yet</.card_title>
                <.card_description>
                  Open bounties will appear here once created
                </.card_description>
              </.card_header>
            </.card>
          <% else %>
            <.bounties tickets={@tickets} />
          <% end %>
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

  def handle_event("create_bounty", %{"bounty_form" => params}, socket) do
    changeset =
      %BountyForm{}
      |> BountyForm.changeset(params)
      |> Map.put(:action, :validate)

    amount = get_field(changeset, :amount)
    ticket_ref = get_field(changeset, :ticket_ref)

    with %{valid?: true} <- changeset,
         {:ok, _} <-
           Bounties.create_bounty(%{
             creator: socket.assigns.current_user,
             owner: socket.assigns.current_user,
             amount: amount,
             ticket_ref: ticket_ref
           }) do
      # TODO: post comment in a separate job
      body = """
      💎 **#{socket.assigns.current_user.provider_login}** is offering a **#{Money.to_string!(amount, no_fraction_if_integer: true)}** bounty for this issue

      👉 Got a pull request resolving this? Claim the bounty by commenting `/claim ##{ticket_ref.number}` in your PR and joining swift.algora.io
      """

      Task.start(fn ->
        if Github.pat_enabled() do
          Github.create_issue_comment(
            Github.pat(),
            ticket_ref.owner,
            ticket_ref.repo,
            ticket_ref.number,
            body
          )
        else
          Logger.info("""
          Github.create_issue_comment(Github.pat(), "#{ticket_ref.owner}", "#{ticket_ref.repo}", #{ticket_ref.number},
                 \"\"\"
                 #{body}
                 \"\"\")
          """)

          :ok
        end
      end)

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
         {:ok, token} <- Users.get_access_token(socket.assigns.current_user),
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

  def handle_info(:bounties_updated, socket) do
    {:noreply, assign_tickets(socket)}
  end

  defp assign_tickets(socket) do
    tickets =
      Bounties.TicketView.list(
        status: :open,
        tech_stack: socket.assigns.current_user.tech_stack,
        limit: 100
      ) ++
        Bounties.TicketView.sample_tickets()

    assign(socket, :tickets, Enum.take(tickets, 6))
  end

  defp assign_achievements(socket) do
    tech = List.first(socket.assigns.current_user.tech_stack)

    status_fns = [
      {&personalize_status/1, "Personalize Algora"},
      {&create_bounty_status/1, "Create a bounty"},
      {&reward_bounty_status/1, "Reward a bounty"},
      {&begin_collaboration_status/1, "Contract a #{tech} developer"},
      {&complete_first_contract_status/1, "Complete a contract"}
    ]

    {achievements, _} =
      Enum.reduce_while(status_fns, {[], false}, fn {status_fn, name}, {acc, found_current} ->
        status = status_fn.(socket.assigns.current_user)

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

  defp create_bounty_status(user) do
    case Bounties.list_bounties(owner_id: user.id, limit: 1) do
      [] -> :upcoming
      _ -> :completed
    end
  end

  defp reward_bounty_status(user) do
    case Bounties.list_bounties(owner_id: user.id, status: :paid, limit: 1) do
      [] -> :upcoming
      _ -> :completed
    end
  end

  defp begin_collaboration_status(user) do
    case Contracts.list_contracts(client_id: user.id, active_or_paid?: true, limit: 1) do
      [] -> :upcoming
      _ -> :completed
    end
  end

  defp complete_first_contract_status(user) do
    case Contracts.list_contracts(client_id: user.id, status: :paid, limit: 1) do
      [] -> :upcoming
      _ -> :completed
    end
  end
end
