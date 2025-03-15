defmodule AlgoraWeb.HomeLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import Ecto.Changeset
  import Ecto.Query
  import Phoenix.LiveView.TagEngine
  import Tails, only: [classes: 1]

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Bounties
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias AlgoraWeb.Components.Footer
  alias AlgoraWeb.Components.Header
  alias AlgoraWeb.Components.Wordmarks
  alias AlgoraWeb.Data.PlatformStats
  alias AlgoraWeb.Forms.BountyForm
  alias AlgoraWeb.Forms.TipForm

  @impl true
  def mount(%{"country_code" => country_code}, _session, socket) do
    Gettext.put_locale(AlgoraWeb.Gettext, Algora.Util.locale_from_country_code(country_code))

    stats = [
      %{label: "Paid Out", value: format_money(get_total_paid_out())},
      %{label: "Completed Bounties", value: format_number(get_completed_bounties_count())},
      %{label: "Contributors", value: format_number(get_contributors_count())},
      %{label: "Countries", value: format_number(get_countries_count())}
    ]

    {:ok,
     socket
     |> assign(:featured_devs, Accounts.list_featured_developers(country_code))
     |> assign(:stats, stats)
     |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
     |> assign(:tip_form, to_form(TipForm.changeset(%TipForm{}, %{})))
     |> assign(:pending_action, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gradient-to-br from-primary/5 to-muted/20">
      <Header.header />

      <main>
        <div class="relative isolate overflow-hidden min-h-screen">
          <!-- Background pattern -->
          <div
            class="absolute inset-x-0 -top-40 -z-10 transform overflow-hidden blur-3xl sm:-top-80"
            aria-hidden="true"
          >
            <div
              class="left-[calc(50%-11rem)] aspect-[1155/678] w-[36.125rem] rotate-[30deg] relative -translate-x-1/2 bg-gradient-to-tr from-primary to-secondary opacity-20 sm:left-[calc(50%-30rem)] sm:w-[72.1875rem]"
              style="clip-path: polygon(74.1% 44.1%, 100% 61.6%, 97.5% 26.9%, 85.5% 0.1%, 80.7% 2%, 72.5% 32.5%, 60.2% 62.4%, 52.4% 68.1%, 47.5% 58.3%, 45.2% 34.5%, 27.5% 76.7%, 0.1% 64.9%, 17.9% 100%, 27.6% 76.8%, 76.1% 97.7%, 74.1% 44.1%)"
            >
            </div>
          </div>

          <div class="[mask-image:radial-gradient(32rem_32rem_at_center,white,transparent)] absolute inset-x-0 -z-10 h-screen w-full stroke-border">
            <defs>
              <pattern
                id="grid-pattern"
                width="200"
                height="200"
                x="50%"
                y="-1"
                patternUnits="userSpaceOnUse"
              >
                <path d="M.5 200V.5H200" fill="none" />
              </pattern>
            </defs>
            <rect
              width="100%"
              height="100%"
              stroke-width="0"
              fill="url(#grid-pattern)"
              opacity="0.25"
            />
          </div>

          <div class="absolute inset-x-0 -z-10 transform overflow-hidden blur-3xl" aria-hidden="true">
            <div
              class="left-[calc(50%+3rem)] aspect-[1155/678] w-[36.125rem] relative -translate-x-1/2 bg-gradient-to-tr from-primary to-secondary opacity-20 sm:left-[calc(50%+36rem)] sm:w-[72.1875rem]"
              style="clip-path: polygon(74.1% 44.1%, 100% 61.6%, 97.5% 26.9%, 85.5% 0.1%, 80.7% 2%, 72.5% 32.5%, 60.2% 62.4%, 52.4% 68.1%, 47.5% 58.3%, 45.2% 34.5%, 27.5% 76.7%, 0.1% 64.9%, 17.9% 100%, 27.6% 76.8%, 76.1% 97.7%, 74.1% 44.1%)"
            >
            </div>
          </div>
          <!-- Hero content -->
          <div class="mx-auto max-w-7xl px-6 pt-24 pb-12 lg:px-8 xl:pt-20 2xl:pt-28">
            <div class="mx-auto gap-x-14 lg:mx-0 lg:flex lg:max-w-none lg:items-center">
              <div class="relative w-full lg:max-w-xl lg:shrink-0 xl:max-w-2xl 2xl:max-w-3xl">
                <h1 class="font-display text-pretty text-5xl font-semibold tracking-tight text-foreground sm:text-7xl">
                  The open source UpWork alternative.
                </h1>
                <p class="mt-8 text-pretty text-lg font-medium text-muted-foreground sm:max-w-md sm:text-xl/8 lg:max-w-none">
                  GitHub bounties, freelancing and full-time jobs.
                </p>
                <!-- CTA buttons -->
                <div class="mt-10 flex flex-col sm:flex-row text-center sm:items-center gap-6">
                  <.button
                    navigate={~p"/onboarding/org"}
                    variant="default"
                    class="px-12 py-8 text-xl font-semibold"
                  >
                    Companies
                  </.button>
                  <.button
                    navigate={~p"/onboarding/dev"}
                    variant="secondary"
                    class="px-12 py-8 text-xl font-semibold"
                  >
                    Developers
                  </.button>
                </div>
                <!-- Stats -->
                <dl class="mt-16 grid grid-cols-2 gap-8 sm:grid-cols-4">
                  <%= for stat <- @stats do %>
                    <div class="flex flex-col gap-y-2">
                      <dt class="text-sm leading-6 text-muted-foreground whitespace-nowrap">
                        {stat.label}
                      </dt>
                      <dd class="font-display text-3xl font-semibold tracking-tight text-foreground">
                        {stat.value}
                      </dd>
                    </div>
                  <% end %>
                </dl>
                <!-- Logos -->
                <div class="mt-16">
                  <h2 class="text-sm font-semibold leading-8 text-foreground">
                    Trusted by the world's most innovative teams
                  </h2>
                  <div class="mt-6 grid grid-cols-3 sm:grid-cols-5 gap-6 -ml-[5%] sm:-ml-[2.5%]">
                    <.logo_cloud />
                  </div>
                </div>
              </div>
              <!-- Featured devs -->
              <div class="mt-14 flex justify-start md:justify-center gap-8 lg:justify-start lg:mt-0 lg:pl-0 overflow-x-auto scrollbar-thin lg:overflow-x-visible">
                <%= if length(@featured_devs) > 0 do %>
                  <div class="ml-auto w-32 min-[500px]:w-40 sm:w-56 lg:w-44 flex-none space-y-8 pt-32 sm:ml-0 lg:order-last lg:pt-36 xl:order-none xl:pt-80">
                    <.dev_card dev={List.first(@featured_devs)} />
                  </div>
                  <div class="mr-auto w-32 min-[500px]:w-40 sm:w-56 lg:w-44 flex-none space-y-8 sm:mr-0 lg:pt-36">
                    <%= if length(@featured_devs) >= 3 do %>
                      <%= for dev <- Enum.slice(@featured_devs, 1..2) do %>
                        <.dev_card dev={dev} />
                      <% end %>
                    <% end %>
                  </div>
                  <div class="w-32 min-[500px]:w-40 sm:w-56 lg:w-44 flex-none space-y-8 pt-32 lg:pt-0">
                    <%= for dev <- Enum.slice(@featured_devs, 3..4) do %>
                      <.dev_card dev={dev} />
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
          <div class="mx-auto max-w-7xl px-6 py-24 sm:py-32 lg:px-8">
            <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-4xl text-center mb-4">
              Fund GitHub Issues
            </h2>
            <p class="text-center font-medium text-base text-muted-foreground mb-8">
              Support open source development with bounties on GitHub issues
            </p>

            <div class="grid grid-cols-1 gap-4 lg:grid-cols-2">
              <a
                href="https://github.com/zed-industries/zed/issues/4440"
                class="relative flex items-center gap-x-4 rounded-xl bg-card/50 p-6 ring-1 ring-border hover:bg-card/70 transition-colors"
              >
                <div class="flex -space-x-4">
                  <img
                    class="h-20 w-20 rounded-full z-0"
                    src="https://github.com/zed-industries.png"
                    alt="Zed"
                  />
                  <img
                    class="h-20 w-20 rounded-full z-10"
                    src="https://github.com/schacon.png"
                    alt="Scott Chacon"
                  />
                </div>
                <div class="text-sm leading-6 flex-1">
                  <div class="text-xl font-semibold text-foreground">Scott Chacon</div>
                  <div class="font-medium text-muted-foreground">GitHub Cofounder</div>
                  <div class="font-medium text-foreground">
                    Funded Vim replace mode in Zed Editor
                  </div>
                </div>
                <div class="font-display text-2xl font-semibold text-success-400">$500</div>
              </a>

              <a
                href="https://github.com/PX4/PX4-Autopilot/issues/22464"
                class="relative flex items-center gap-x-4 rounded-xl bg-card/50 p-6 ring-1 ring-border hover:bg-card/70 transition-colors"
              >
                <img class="h-20 w-20" src="https://github.com/PX4.png" alt="PX4" />
                <div class="text-sm leading-6 flex-1">
                  <div class="text-xl font-semibold text-foreground">PX4 Autopilot</div>
                  <div class="font-medium text-muted-foreground">
                    Open Source Autopilot for Drone Developers
                  </div>
                  <div class="font-medium text-foreground">
                    Community funded collision prevention system
                  </div>
                </div>
                <div class="font-display text-2xl font-semibold text-success-400">$1,000</div>
              </a>
              <a
                href="https://github.com/calcom/cal.com/issues/11953"
                class="relative flex items-center gap-x-4 rounded-xl bg-card/50 p-6 ring-1 ring-border hover:bg-card/70 transition-colors"
              >
                <div class="flex -space-x-4">
                  <img
                    class="h-20 w-20 rounded-full z-0"
                    src="https://github.com/calcom.png"
                    alt="Cal.com"
                  />
                  <img
                    class="h-20 w-20 rounded-full z-10"
                    src="https://github.com/framer.png"
                    alt="Framer"
                  />
                </div>
                <div class="text-sm leading-6 flex-1">
                  <div class="text-xl font-semibold text-foreground">Framer</div>
                  <div class="font-medium text-muted-foreground">Design & Prototyping Tool</div>
                  <div class="font-medium text-foreground">
                    Funded multiple round-robin hosts in Cal.com
                  </div>
                </div>
                <div class="font-display text-2xl font-semibold text-success-400">$500</div>
              </a>
              <a
                href="https://console.algora.io/org/coollabsio"
                class="relative flex items-center gap-x-4 rounded-xl bg-card/50 p-6 ring-1 ring-border hover:bg-card/70 transition-colors"
              >
                <img
                  class="h-20 w-20 rounded-full"
                  src="https://github.com/coollabsio.png"
                  alt="Coolify"
                />
                <div class="text-sm leading-6 flex-1">
                  <div class="text-xl font-semibold text-foreground">Coolify</div>
                  <div class="font-medium text-muted-foreground">Self-Hosted Heroku Alternative</div>
                  <div class="font-medium text-foreground">
                    Community funded features
                  </div>
                </div>
                <div class="font-display text-2xl font-semibold text-success-400">$2,543</div>
              </a>
            </div>

            <div class="max-w-4xl mx-auto mt-12">
              <h2 class="mb-8 text-xl font-bold text-card-foreground text-center">
                <span>Fund any issue</span>
                <span class="block sm:inline text-success">in seconds</span>
              </h2>
              <div class="grid grid-cols-1 gap-4 lg:grid-cols-2">
                <.card class="bg-muted/30">
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
                          placeholder="https://github.com/owner/repo/issues/1337"
                        />
                        <.input
                          label="Amount"
                          icon="tabler-currency-dollar"
                          field={@bounty_form[:amount]}
                        />
                        <div class="flex justify-end gap-4">
                          <.button variant="subtle">Submit</.button>
                        </div>
                      </div>
                    </.simple_form>
                  </.card_content>
                </.card>
                <.card class="bg-muted/30">
                  <.card_header>
                    <div class="flex items-center gap-3">
                      <.icon name="tabler-gift" class="h-8 w-8" />
                      <h2 class="text-2xl font-semibold">Tip a developer</h2>
                    </div>
                  </.card_header>
                  <.card_content>
                    <.simple_form for={@tip_form} phx-submit="create_tip">
                      <div class="flex flex-col gap-6">
                        <.input
                          label="GitHub handle"
                          field={@tip_form[:github_handle]}
                          placeholder="jsmith"
                        />
                        <.input
                          label="Amount"
                          icon="tabler-currency-dollar"
                          field={@tip_form[:amount]}
                        />
                        <div class="flex justify-end gap-4">
                          <.button variant="subtle">Submit</.button>
                        </div>
                      </div>
                    </.simple_form>
                  </.card_content>
                </.card>
              </div>
            </div>
          </div>
          <Footer.footer />
        </div>
      </main>
    </div>
    """
  end

  @impl true
  def handle_event("create_bounty" = event, %{"bounty_form" => params} = unsigned_params, socket) do
    changeset =
      %BountyForm{}
      |> BountyForm.changeset(params)
      |> Map.put(:action, :validate)

    amount = get_field(changeset, :amount)
    ticket_ref = get_field(changeset, :ticket_ref)

    if changeset.valid? do
      if socket.assigns[:current_user] do
        case Bounties.create_bounty(%{
               creator: socket.assigns.current_user,
               owner: socket.assigns.current_user,
               amount: amount,
               ticket_ref: ticket_ref
             }) do
          {:ok, _bounty} ->
            {:noreply,
             socket
             |> put_flash(:info, "Bounty created")
             |> redirect(to: ~p"/")}

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
    else
      {:noreply, assign(socket, :bounty_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("create_tip" = event, %{"tip_form" => params} = unsigned_params, socket) do
    changeset =
      %TipForm{}
      |> TipForm.changeset(params)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      if socket.assigns[:current_user] do
        with {:ok, token} <- Accounts.get_access_token(socket.assigns.current_user),
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
    else
      {:noreply, assign(socket, :tip_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_info({:authenticated, user}, socket) do
    socket = assign(socket, :current_user, user)

    case socket.assigns.pending_action do
      {event, params} ->
        socket = assign(socket, :pending_action, nil)
        handle_event(event, params, socket)

      nil ->
        {:noreply, socket}
    end
  end

  defp dev_card(assigns) do
    ~H"""
    <div class="relative">
      <img
        src={@dev.avatar_url}
        alt={@dev.name}
        class="aspect-square w-full rounded-xl rounded-b-none bg-muted object-cover shadow-lg ring-1 ring-border"
      />
      <div class="font-display mt-1 rounded-xl rounded-t-none bg-card/50 p-3 text-sm ring-1 ring-border backdrop-blur-sm">
        <div class="font-semibold text-foreground">
          {@dev.name} {Algora.Misc.CountryEmojis.get(@dev.country)}
        </div>
        <div class="mt-0.5 text-xs font-medium text-foreground line-clamp-2">{@dev.bio}</div>
        <div class="hidden mt-1 text-sm">
          <div class="-ml-1 flex h-6 flex-wrap gap-1 overflow-hidden p-px text-sm">
            <%= for tech <- @dev.tech_stack do %>
              <span class="rounded-xl bg-muted/50 px-2 py-0.5 text-xs text-muted-foreground ring-1 ring-border">
                {tech}
              </span>
            <% end %>
          </div>
        </div>
        <div class="mt-0.5 text-xs text-muted-foreground">
          <span class="font-medium">Total Earned:</span>
          <span class="text-sm font-bold text-success">
            {Money.to_string!(@dev.total_earned, no_fraction_if_integer: true)}
          </span>
        </div>
      </div>
    </div>
    """
  end

  defp get_total_paid_out do
    subtotal =
      Repo.one(
        from t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          select: sum(t.net_amount)
      ) || Money.new(0, :USD)

    subtotal |> Money.add!(PlatformStats.get().extra_paid_out) |> Money.round(currency_digits: 0)
  end

  defp get_completed_bounties_count do
    bounties_subtotal =
      Repo.one(
        from t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          where: not is_nil(t.bounty_id),
          select: count(fragment("DISTINCT (?, ?)", t.bounty_id, t.user_id))
      ) || 0

    tips_subtotal =
      Repo.one(
        from t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          where: not is_nil(t.tip_id),
          select: count(fragment("DISTINCT (?, ?)", t.tip_id, t.user_id))
      ) || 0

    bounties_subtotal + tips_subtotal + PlatformStats.get().extra_completed_bounties
  end

  defp get_contributors_count do
    subtotal =
      Repo.one(
        from t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          select: count(fragment("DISTINCT ?", t.user_id))
      ) || 0

    subtotal + PlatformStats.get().extra_contributors
  end

  defp get_countries_count do
    Repo.one(
      from u in User,
        join: t in Transaction,
        on: t.user_id == u.id,
        where: t.type == :credit,
        where: t.status == :succeeded,
        where: not is_nil(t.linked_transaction_id),
        where: not is_nil(u.country) and u.country != "",
        select: count(fragment("DISTINCT ?", u.country))
    ) || 0
  end

  defp logo_cloud(assigns) do
    assigns =
      assign(
        assigns,
        :orgs,
        Enum.map(
          [
            %{
              name: "ZIO",
              url: "https://zio.dev",
              args: %{src: ~p"/images/wordmarks/zio.png", class: "mt-4 max-h-10 brightness-0 invert"}
            },
            %{
              name: "Tailcall",
              url: "https://tailcall.run",
              component: &Wordmarks.tailcall/1,
              args: %{class: "max-h-12", fill: "#fff"}
            },
            %{name: "Cal.com", url: "https://cal.com", component: &Wordmarks.calcom/1},
            %{name: "Qdrant", url: "https://qdrant.tech", component: &Wordmarks.qdrant/1, args: %{class: "max-h-9"}},
            %{
              name: "Golem Cloud",
              url: "https://www.golem.cloud",
              component: &Wordmarks.golemcloud/1,
              args: %{class: "max-h-9"}
            },
            %{
              name: "Remotion",
              url: "https://remotion.dev",
              args: %{
                src: "https://algora.io/banners/remotion.png",
                class: "max-h-10 brightness-0 invert sm:hidden"
              }
            }
          ],
          fn org ->
            org
            |> Map.put_new(:args, %{})
            |> update_in([:args, :class], &classes(["max-h-6 w-full object-contain", &1]))
            |> put_in([:args, :alt], org.name)
          end
        )
      )

    ~H"""
    <%= for org <- @orgs do %>
      <div class="flex items-center justify-center">
        <%= if org[:component] do %>
          {component(
            org.component,
            org.args,
            {__ENV__.module, __ENV__.function, __ENV__.file, __ENV__.line}
          )}
        <% else %>
          <img {org.args} />
        <% end %>
      </div>
    <% end %>
    """
  end

  defp format_money(money), do: money |> Money.round(currency_digits: 0) |> Money.to_string!(no_fraction_if_integer: true)

  defp format_number(number), do: Number.Delimit.number_to_delimited(number, precision: 0)
end
