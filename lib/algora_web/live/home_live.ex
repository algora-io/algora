defmodule AlgoraWeb.HomeLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import Ecto.Query
  import Phoenix.LiveView.TagEngine
  import Tails, only: [classes: 1]

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias AlgoraWeb.Components.Wordmarks

  @impl true
  def mount(%{"country_code" => country_code}, _session, socket) do
    Gettext.put_locale(AlgoraWeb.Gettext, Algora.Util.locale_from_country_code(country_code))

    stats = [
      %{label: "Paid Out", value: Money.to_string!(get_total_paid_out())},
      %{label: "Completed Bounties", value: number_to_delimited(get_completed_bounties_count())},
      %{label: "Contributors", value: number_to_delimited(get_contributors_count())},
      %{label: "Countries", value: number_to_delimited(get_countries_count())}
    ]

    {:ok,
     socket
     |> assign(:featured_devs, Accounts.list_featured_developers(country_code))
     |> assign(:stats, stats)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gradient-to-br from-primary/5 to-muted/20">
      <header class="absolute inset-x-0 top-0 z-50">
        <nav
          class="mx-auto flex max-w-7xl items-center justify-between p-6 lg:px-8"
          aria-label="Global"
        >
          <div class="flex lg:flex-1">
            <.wordmark class="h-8 w-auto text-foreground" />
          </div>
          <!-- Mobile menu button -->
          <div class="flex lg:hidden">
            <button
              type="button"
              class="rounded-md p-2.5 text-muted-foreground hover:text-foreground"
              phx-click={JS.show(to: "#mobile-menu")}
            >
              <span class="sr-only">Open main menu</span>
              <.icon name="tabler-menu" class="h-6 w-6" />
            </button>
          </div>
          <!-- Desktop nav -->
          <div class="hidden lg:flex lg:gap-x-12">
            <.link
              href={AlgoraWeb.Constants.get(:docs_url)}
              class="text-sm/6 font-semibold text-muted-foreground hover:text-foreground"
            >
              Docs
            </.link>
            <.link
              href={AlgoraWeb.Constants.get(:blog_url)}
              class="text-sm/6 font-semibold text-muted-foreground hover:text-foreground"
            >
              Blog
            </.link>
            <.link
              navigate={~p"/pricing"}
              class="text-sm/6 font-semibold text-muted-foreground hover:text-foreground"
            >
              Pricing
            </.link>
            <.link
              href={AlgoraWeb.Constants.get(:github_url)}
              class="text-sm/6 font-semibold text-muted-foreground hover:text-foreground"
            >
              GitHub
            </.link>
          </div>

          <div class="hidden lg:flex lg:flex-1 lg:justify-end">
            <.button navigate={~p"/auth/login"} variant="subtle">
              Sign in
            </.button>
          </div>
        </nav>
        <!-- Mobile menu -->
        <div id="mobile-menu" class="lg:hidden hidden" role="dialog" aria-modal="true">
          <div class="fixed inset-0 z-50"></div>
          <div class="fixed inset-y-0 right-0 z-50 w-full overflow-y-auto bg-background px-6 py-6 sm:max-w-sm sm:ring-1 sm:ring-border">
            <!-- Mobile menu content -->
            <div class="flex items-center justify-between">
              <.wordmark class="h-8 w-auto text-foreground" />
              <button
                type="button"
                class="rounded-md p-2.5 text-muted-foreground hover:text-foreground"
                phx-click={JS.hide(to: "#mobile-menu")}
              >
                <span class="sr-only">Close menu</span>
                <.icon name="tabler-x" class="h-6 w-6" />
              </button>
            </div>

            <div class="mt-6 flow-root">
              <div class="-my-6 divide-y divide-border">
                <div class="space-y-2 py-6">
                  <.link
                    href={AlgoraWeb.Constants.get(:docs_url)}
                    class="-mx-3 block rounded-lg px-3 py-2 text-base/7 font-semibold text-muted-foreground hover:bg-muted"
                  >
                    Docs
                  </.link>
                  <.link
                    href={AlgoraWeb.Constants.get(:blog_url)}
                    class="-mx-3 block rounded-lg px-3 py-2 text-base/7 font-semibold text-muted-foreground hover:bg-muted"
                  >
                    Blog
                  </.link>
                  <.link
                    navigate={~p"/pricing"}
                    class="-mx-3 block rounded-lg px-3 py-2 text-base/7 font-semibold text-muted-foreground hover:bg-muted"
                  >
                    Pricing
                  </.link>
                  <.link
                    href={AlgoraWeb.Constants.get(:github_url)}
                    class="-mx-3 block rounded-lg px-3 py-2 text-base/7 font-semibold text-muted-foreground hover:bg-muted"
                  >
                    GitHub
                  </.link>
                </div>
                <div class="py-6">
                  <.link
                    navigate={~p"/auth/login"}
                    class="-mx-3 block rounded-lg px-3 py-2.5 text-base/7 font-semibold text-muted-foreground hover:bg-muted"
                  >
                    Sign in
                  </.link>
                </div>
              </div>
            </div>
          </div>
        </div>
      </header>

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
              <div class="mt-14 flex justify-start sm:justify-center gap-8 lg:justify-start lg:mt-0 lg:pl-0">
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
          <!-- New Footer -->
          <footer class="border-t">
            <div class="mx-auto max-w-7xl px-6 py-12 md:flex md:items-center md:justify-between lg:px-8">
              <div class="flex justify-center space-x-6 md:order-2">
                <.link
                  href={AlgoraWeb.Constants.get(:twitter_url)}
                  class="text-muted-foreground hover:text-foreground"
                >
                  <span class="sr-only">Twitter</span>
                  <.icon name="tabler-brand-twitter" class="h-6 w-6" />
                </.link>
                <.link
                  href={AlgoraWeb.Constants.get(:github_url)}
                  class="text-muted-foreground hover:text-foreground"
                >
                  <span class="sr-only">GitHub</span>
                  <.icon name="tabler-brand-github" class="h-6 w-6" />
                </.link>
                <.link
                  href={AlgoraWeb.Constants.get(:discord_url)}
                  class="text-muted-foreground hover:text-foreground"
                >
                  <span class="sr-only">Discord</span>
                  <.icon name="tabler-brand-discord" class="h-6 w-6" />
                </.link>
              </div>
              <div class="mt-8 md:order-1 md:mt-0">
                <p class="text-center text-sm leading-5 text-muted-foreground">
                  &copy; {DateTime.utc_now().year} Algora, Public Benefit Corporation
                </p>
              </div>
            </div>
          </footer>
        </div>
      </main>
    </div>
    """
  end

  def dev_card(assigns) do
    ~H"""
    <div class="relative">
      <img
        src={@dev.avatar_url}
        alt={@dev.name}
        class="aspect-square w-full rounded-xl rounded-b-none bg-muted object-cover shadow-lg ring-1 ring-border"
      />
      <div class="font-display mt-1 rounded-xl rounded-t-none bg-card/50 p-3 text-sm ring-1 ring-border backdrop-blur-sm">
        <div class="font-semibold text-foreground">{@dev.name} {@dev.flag}</div>
        <div class="mt-0.5 text-xs font-medium text-foreground">{@dev.bio}</div>
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
    Repo.one(
      from t in Transaction,
        where: t.type == :credit and t.status == :succeeded,
        select: sum(t.net_amount)
    ) || Money.new(0, :USD)
  end

  defp get_completed_bounties_count do
    Repo.one(
      from t in Transaction,
        where: t.type == :credit and t.status == :succeeded and not is_nil(t.bounty_id),
        select: count(fragment("DISTINCT ?", t.bounty_id))
    ) || 0
  end

  defp get_contributors_count do
    Repo.one(
      from t in Transaction,
        where: t.type == :credit and t.status == :succeeded,
        select: count(fragment("DISTINCT ?", t.user_id))
    ) || 0
  end

  defp get_countries_count do
    Repo.one(
      from u in User,
        join: t in Transaction,
        on: t.user_id == u.id,
        where: t.type == :credit and t.status == :succeeded,
        where: not is_nil(u.country) and u.country != "",
        select: count(fragment("DISTINCT ?", u.country))
    ) || 0
  end

  def logo_cloud(assigns) do
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

  defp number_to_delimited(number), do: Number.Delimit.number_to_delimited(number, precision: 0)
end
