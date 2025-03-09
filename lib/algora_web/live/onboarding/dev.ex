defmodule AlgoraWeb.Onboarding.DevLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias AlgoraWeb.Components.Logos

  @steps [:info, :oauth]

  defmodule InfoForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :tech_stack, {:array, :string}
      field :intentions, {:array, :string}
    end

    def init do
      to_form(InfoForm.changeset(%InfoForm{}, %{tech_stack: [], intentions: []}))
    end

    def changeset(form, attrs) do
      form
      |> cast(attrs, [:tech_stack, :intentions])
      |> validate_required(:tech_stack, message: "Please select at least one technology")
      |> validate_required(:intentions, message: "Please select at least one intention")
      |> validate_length(:tech_stack, min: 1, message: "Please enter at least one technology")
      |> validate_length(:intentions, min: 1, message: "Please select at least one intention")
      |> validate_subset(:intentions, Enum.map(intentions_options(), &elem(&1, 0)))
    end

    def intentions_options do
      [
        {"bounties", "Solve Bounties", "Work on open source issues and earn rewards", "tabler-diamond"},
        {"jobs", "Find Full-time Work", "Get matched with companies hiring developers", "tabler-briefcase"},
        {"projects", "Freelance Work", "Take on flexible contract-based projects", "tabler-clock"}
      ]
    end
  end

  def mount(_params, _session, socket) do
    context = %{
      country: socket.assigns.current_country,
      tech_stack: [],
      intentions: []
    }

    transactions =
      Repo.all(
        from tx in Transaction,
          where: tx.type == :credit,
          where: not is_nil(tx.succeeded_at),
          where:
            fragment(
              "? >= ('USD', 500)::money_with_currency",
              tx.net_amount
            ),
          join: u in assoc(tx, :user),
          join: b in assoc(tx, :bounty),
          join: t in assoc(b, :ticket),
          join: r in assoc(t, :repository),
          join: o in assoc(r, :user),
          select_merge: %{user: u, bounty: %{b | ticket: %{t | repository: %{r | user: o}}}},
          order_by: [desc: tx.succeeded_at],
          limit: 10
      )

    {:ok,
     socket
     |> assign(:step, Enum.at(@steps, 0))
     |> assign(:steps, @steps)
     |> assign(:total_steps, length(@steps))
     |> assign(:context, context)
     |> assign(:transactions, transactions)
     |> assign(:info_form, InfoForm.init())}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-card">
      <div class="flex flex-1">
        <div class="flex-grow px-8 py-16">
          <div class="mx-auto max-w-3xl">
            <div class="mb-4 flex items-center gap-4 text-lg">
              <span class="text-muted-foreground">
                {Enum.find_index(@steps, &(&1 == @step)) + 1} / {length(@steps)}
              </span>
              <h1 class="text-lg font-semibold uppercase">
                <%= if @step == Enum.at(@steps, -1) do %>
                  Last step
                <% else %>
                  Get started
                <% end %>
              </h1>
            </div>

            <div class="mb-4">
              {main_content(assigns)}
            </div>
          </div>
        </div>
        <div class="h-screen w-1/3 overflow-y-auto border-l border-border bg-background px-6 py-4">
          {sidebar_content(assigns)}
        </div>
      </div>
    </div>
    """
  end

  defp sidebar_content(assigns) do
    ~H"""
    <h2 class="mb-4 text-lg font-semibold uppercase">
      Recently Completed Bounties
    </h2>
    <%= if @transactions == [] do %>
      <p class="text-muted-foreground">No completed bounties available</p>
    <% else %>
      <%= for transaction <- @transactions do %>
        <div class="mb-4 rounded-lg border border-border bg-card p-4">
          <div class="flex gap-4">
            <div class="flex-1">
              <div class="mb-2 font-mono text-2xl font-extrabold text-success">
                {Money.to_string!(transaction.bounty.amount)}
              </div>
              <div class="mb-1 text-sm text-muted-foreground">
                {transaction.bounty.ticket.repository.user.provider_login}/{transaction.bounty.ticket.repository.name}#{transaction.bounty.ticket.number}
              </div>
              <div class="font-medium">
                {transaction.bounty.ticket.title}
              </div>
              <div class="mt-1 text-xs text-muted-foreground">
                {Algora.Util.time_ago(transaction.succeeded_at)}
              </div>
            </div>

            <div class="flex w-32 flex-col items-center border-l border-border pl-4">
              <h3 class="mb-3 text-xs font-medium uppercase text-muted-foreground">
                Awarded to
              </h3>
              <img
                src={transaction.user.avatar_url}
                class="mb-2 h-16 w-16 rounded-full"
                alt={transaction.user.name}
              />
              <div class="text-center text-sm font-medium">
                {transaction.user.name}
                <div>
                  {Algora.Misc.CountryEmojis.get(transaction.user.country, "🌎")}
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    <% end %>
    """
  end

  def main_content(%{step: :info} = assigns) do
    ~H"""
    <div class="space-y-8">
      <.form for={@info_form} phx-submit="submit_info" class="space-y-8">
        <div>
          <h2 class="mb-2 text-4xl font-semibold">
            What is your tech stack?
          </h2>
          <p class="text-muted-foreground">Select the technologies you work with</p>

          <.TechStack
            class="mt-4"
            tech={get_field(@info_form.source, :tech_stack) || []}
            socket={@socket}
            form="info_form"
          />

          <.error :for={msg <- @info_form[:tech_stack].errors |> Enum.map(&translate_error(&1))}>
            {msg}
          </.error>
        </div>

        <div class="mt-8">
          <h2 class="mb-2 text-4xl font-semibold">
            What are you looking to do?
          </h2>
          <p class="text-muted-foreground">Select all that apply</p>

          <div class="mt-2 -ml-4">
            <%= for {value, label, description, icon} <- InfoForm.intentions_options() do %>
              <label class="flex cursor-pointer items-center gap-3 rounded-lg p-4 hover:bg-muted">
                <.input
                  field={@info_form[:intentions]}
                  type="checkbox"
                  value={value}
                  checked={value in (get_field(@info_form.source, :intentions) || [])}
                  class="h-10 w-10 rounded border-input bg-background text-primary focus:ring-primary focus:ring-offset-background"
                  multiple
                />
                <div class="flex-1">
                  <div class="flex items-center gap-2">
                    <.icon name={icon} class="h-5 w-5 text-muted-foreground" />
                    <span class="font-medium">{label}</span>
                  </div>
                  <p class="mt-0.5 text-sm text-muted-foreground">
                    {description}
                  </p>
                </div>
              </label>
            <% end %>
          </div>

          <.error :for={msg <- @info_form[:intentions].errors |> Enum.map(&translate_error(&1))}>
            {msg}
          </.error>
        </div>

        <div class="flex justify-end">
          <.button type="submit">
            Next <.icon name="tabler-arrow-right" class="ml-2 size-4" />
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  def main_content(%{step: :oauth} = assigns) do
    ~H"""
    <div class="space-y-8">
      <div>
        <h2 class="mb-2 text-4xl font-semibold">
          Connect your GitHub account
        </h2>
        <p class="mb-6 text-muted-foreground">
          Sign in with GitHub to join our developer community and start earning bounties.
        </p>

        <p class="text-sm text-muted-foreground/75">
          By continuing, you agree to Algora's
          <.link href="/terms" class="text-primary hover:underline">Terms of Service</.link>
          and <.link href="/privacy" class="text-primary hover:underline">Privacy Policy</.link>.
        </p>
      </div>
      <div class="flex justify-between">
        <.button phx-click="prev_step" variant="secondary">
          Previous
        </.button>
        <.button href={Algora.Github.authorize_url()} rel="noopener" class="inline-flex items-center">
          <Logos.github class="mr-2 h-5 w-5" /> Sign in with GitHub
        </.button>
      </div>
    </div>
    """
  end

  def handle_event("prev_step", _, socket) do
    current_step_index = Enum.find_index(socket.assigns.steps, &(&1 == socket.assigns.step))
    prev_step = Enum.at(socket.assigns.steps, current_step_index - 1)
    {:noreply, assign(socket, :step, prev_step)}
  end

  def handle_event("tech_stack_changed", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("submit_info", %{"info_form" => params}, socket) do
    dbg(params)

    tech_stack =
      Jason.decode!(params["tech_stack"]) ++
        case String.trim(params["tech_stack_input"]) do
          "" -> []
          tech_stack_input -> String.split(tech_stack_input, ",")
        end

    changeset =
      %InfoForm{}
      |> InfoForm.changeset(%{tech_stack: tech_stack, intentions: params["intentions"]})
      |> Map.put(:action, :validate)

    case changeset do
      %{valid?: true} ->
        {:noreply,
         socket
         |> assign(:info_form, to_form(changeset))
         |> assign(step: :oauth)}

      %{valid?: false} ->
        {:noreply, assign(socket, info_form: to_form(changeset))}
    end
  end
end
