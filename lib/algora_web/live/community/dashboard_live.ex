defmodule AlgoraWeb.Community.DashboardLive do
  use AlgoraWeb, :live_view

  require Logger

  import Ecto.Changeset
  import AlgoraWeb.Components.Experts
  import AlgoraWeb.Components.Achievement

  alias Algora.Bounties
  alias Algora.Extensions.Ecto.Validations
  alias Algora.Users
  alias Algora.Workspace

  defmodule BountyForm do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :url, :string
      field :amount, Algora.Extensions.Ecto.USD

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
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :github_handle, :string
      field :amount, Algora.Extensions.Ecto.USD
    end

    def changeset(form, attrs \\ %{}) do
      form
      |> cast(attrs, [:github_handle, :amount])
      |> validate_required([:github_handle, :amount])
      |> Validations.validate_money_positive(:amount)
    end
  end

  def mount(_params, _session, socket) do
    tech_stack = "Swift"

    if connected?(socket) do
      Bounties.subscribe()
    end

    {:ok,
     socket
     |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
     |> assign(:tip_form, to_form(TipForm.changeset(%TipForm{}, %{})))
     |> assign(:experts, list_experts(tech_stack))
     |> assign(:tech_stack, [tech_stack])
     |> assign(:hours_per_week, 40)
     |> assign_tickets()
     |> assign_achievements()}
  end

  def handle_info(:bounties_updated, socket) do
    {:noreply, assign_tickets(socket)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 lg:pr-96 bg-background text-foreground">
      <.section>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          {create_bounty(assigns)}
          {create_tip(assigns)}
        </div>
      </.section>

      <.section
        title="Open bounties"
        subtitle={"View all bounties pooled from the #{@tech_stack} community"}
      >
        {bounties(assigns)}
      </.section>

      <.section
        :if={@experts != []}
        title={"#{@tech_stack} experts"}
        subtitle={"View all #{@tech_stack} experts on Algora"}
      >
        <ul class="flex flex-col gap-8 md:grid md:grid-cols-2 xl:grid-cols-3">
          <.experts experts={@experts} />
        </ul>
      </.section>
    </div>
    {sidebar(assigns)}
    """
  end

  defp create_bounty(assigns) do
    ~H"""
    <.card>
      <.card_header>
        <div class="flex items-center gap-2">
          <.icon name="tabler-diamond" class="h-8 w-8" />
          <h2 class="text-2xl font-semibold">Create new bounty</h2>
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
              <.button>Create bounty</.button>
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
        <div class="flex items-center gap-2">
          <.icon name="tabler-gift" class="h-8 w-8" />
          <h2 class="text-2xl font-semibold">Create new tip</h2>
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
              <.button>Create tip</.button>
            </div>
          </div>
        </.simple_form>
      </.card_content>
    </.card>
    """
  end

  defp bounties(assigns) do
    ~H"""
    <div class="-mt-2 -ml-4 relative w-full overflow-auto">
      <table class="w-full caption-bottom text-sm">
        <tbody>
          <%= for ticket <- @tickets do %>
            <tr class="border-b transition-colors hover:bg-muted/10 h-10">
              <td class="p-4 py-0 align-middle">
                <div class="flex items-center gap-4">
                  <div class="font-display text-base font-semibold text-success whitespace-nowrap shrink-0">
                    {Money.to_string!(ticket.total_bounty_amount)}
                  </div>

                  <.link
                    href={ticket.url}
                    class="truncate text-sm text-foreground hover:underline max-w-[400px]"
                  >
                    {ticket.title}
                  </.link>

                  <div class="flex items-center gap-1 text-sm text-muted-foreground whitespace-nowrap shrink-0">
                    <.link
                      :if={ticket.repository.owner.login}
                      href={~p"/org/#{ticket.repository.owner.login}"}
                      class="font-semibold hover:underline"
                    >
                      {ticket.repository.owner.login}
                    </.link>
                    <.icon name="tabler-chevron-right" class="h-4 w-4" />
                    <.link href={ticket.url} class="hover:underline">
                      {ticket.repository.name}#{ticket.number}
                    </.link>
                  </div>

                  <div class="flex -space-x-2">
                    <%= for bounty <- Enum.take(ticket.top_bounties, 3) do %>
                      <img
                        src={bounty.owner.avatar_url}
                        alt={bounty.owner.handle}
                        class="h-8 w-8 rounded-full ring-2 ring-background"
                      />
                    <% end %>
                    <%= if ticket.bounty_count > 3 do %>
                      <div class="flex h-8 w-8 items-center justify-center rounded-full bg-muted text-xs font-medium ring-2 ring-background">
                        +{ticket.bounty_count - 3}
                      </div>
                    <% end %>
                  </div>
                </div>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp sidebar(assigns) do
    ~H"""
    <aside class="fixed bottom-0 right-0 top-16 hidden w-96 overflow-y-auto border-l border-border bg-background p-4 pt-6 lg:block sm:p-6 md:p-8 scrollbar-thin">
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

    with %{valid?: true} <- changeset,
         {:ok, _} <-
           Bounties.create_bounty(%{
             creator: socket.assigns.current_user,
             owner: socket.assigns.current_user,
             amount: get_field(changeset, :amount),
             ticket_ref: get_field(changeset, :ticket_ref)
           }) do
      {:noreply,
       socket
       |> assign_achievements()
       |> put_flash(:info, "Bounty created")}
    else
      %{valid?: false} ->
        {:noreply, socket |> assign(:bounty_form, to_form(changeset))}

      {:error, :already_exists} ->
        {:noreply,
         socket |> put_flash(:warning, "You have already created a bounty for this ticket")}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Something went wrong")}
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
      {:noreply,
       socket
       |> redirect(external: checkout_url)}
    else
      %{valid?: false} ->
        {:noreply, socket |> assign(:tip_form, to_form(changeset))}

      {:error, reason} ->
        Logger.error("Failed to create tip: #{inspect(reason)}")
        {:noreply, socket |> put_flash(:error, "Something went wrong")}
    end
  end

  defp assign_tickets(socket) do
    socket
    |> assign(
      :tickets,
      Bounties.TicketView.list(status: :open, tech_stack: [socket.assigns.tech_stack], limit: 100)
    )
  end

  # TODO: implement this
  defp assign_achievements(socket) do
    socket
    |> assign(:achievements, [
      %{status: :completed, name: "Personalize Algora"},
      %{status: :current, name: "Create a bounty"},
      %{status: :upcoming, name: "Reward a bounty"},
      %{status: :upcoming, name: "Contract a #{socket.assigns.tech_stack} developer"},
      %{status: :upcoming, name: "Complete a contract"}
    ])
  end
end
