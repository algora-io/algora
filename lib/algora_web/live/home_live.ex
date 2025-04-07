defmodule AlgoraWeb.HomeLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

  import AlgoraWeb.Components.ModalVideo
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Workspace
  alias AlgoraWeb.Components.Footer
  alias AlgoraWeb.Components.Header
  alias AlgoraWeb.Components.Logos
  alias AlgoraWeb.Data.PlatformStats

  require Logger

  defmodule RepoForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :url, :string
    end

    def changeset(form, attrs) do
      form
      |> cast(attrs, [:url])
      |> validate_required([:url])
    end
  end

  @impl true
  def mount(%{"country_code" => country_code} = params, _session, socket) do
    Gettext.put_locale(AlgoraWeb.Gettext, Algora.Util.locale_from_country_code(country_code))

    stats = [
      %{label: "Paid Out", value: format_money(get_total_paid_out())},
      %{label: "Completed Bounties", value: format_number(get_completed_bounties_count())},
      %{label: "Contributors", value: format_number(get_contributors_count())},
      %{label: "Countries", value: format_number(get_countries_count())}
    ]

    {:ok,
     socket
     |> assign(:page_title, "Algora - The open source Upwork for engineers")
     |> assign(:page_image, "#{AlgoraWeb.Endpoint.url()}/images/og/home.png")
     |> assign(:screenshot?, not is_nil(params["screenshot"]))
     |> assign(:featured_devs, Accounts.list_featured_developers(country_code))
     |> assign(:stats, stats)
     |> assign(:repo_form, to_form(RepoForm.changeset(%RepoForm{}, %{})))
     |> assign(:plans1, AlgoraWeb.PricingLive.get_plans1())
     |> assign(:plans2, AlgoraWeb.PricingLive.get_plans2())}
  end

  defp org_features do
    [
      %{
        title: "GitHub bounties",
        description: "Add USD rewards on issues and pay on-merge",
        src: ~p"/images/screenshots/bounty-to-hire-merged.png"
      },
      # %{
      #   title: "Match with top developers",
      #   description: "Connect with developers who have relevant open source experience",
      #   src: ~p"/images/screenshots/org-matches.png"
      # },
      %{
        title: "Contract work",
        description: "Collaborate flexibly, hourly or fixed rate",
        src: ~p"/images/screenshots/share-contract.png"
      },
      %{
        title: "Automated payments",
        description: "Reward on auto-pilot as PRs are merged",
        src: ~p"/images/screenshots/autopay-on-merge.png"
      },
      %{
        title: "Payment history",
        description: "View all payments and export summaries",
        src: ~p"/images/screenshots/org-transactions.png"
      },
      # %{
      #   title: "Pool bounties together",
      #   description: "Pool bounties together to reward contributors",
      #   src: ~p"/images/screenshots/pool-bounties.png"
      # }
      %{
        title: "Global payments",
        description: "Compliant payments to #{Algora.PSP.ConnectCountries.count()} countries",
        src: ~p"/images/screenshots/global-payments.png"
      }
    ]
  end

  defp user_features do
    [
      %{
        title: "Find work",
        description: "Browse open bounties and contracts",
        src: ~p"/images/screenshots/user-dashboard.png"
      },
      %{
        title: "Developer profile",
        description: "Showcase your open source contributions",
        src: ~p"/images/screenshots/profile.png"
      },
      %{
        title: "Payment history",
        description: "Monitor your earnings in real-time",
        src: ~p"/images/screenshots/user-transactions.png"
      }
    ]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @screenshot? do %>
        <div class="-mt-24" />
      <% else %>
        <Header.header />
      <% end %>

      <main class="bg-black relative overflow-hidden">
        <section class="relative isolate min-h-[100svh] bg-gradient-to-b from-background to-black">
          <div class="mx-auto max-w-7xl pt-24 pb-12 xl:pt-20">
            <div class="mx-auto lg:mx-0 lg:flex lg:max-w-none lg:items-center">
              <div class="px-6 lg:px-8 lg:pr-0 xl:pb-20 relative w-full lg:max-w-xl lg:shrink-0 xl:max-w-3xl 2xl:max-w-3xl">
                <h1 class="font-display text-3xl sm:text-4xl md:text-5xl xl:text-7xl font-semibold tracking-tight text-foreground">
                  The open source Upwork for engineers
                </h1>
                <p class="mt-4 sm:mt-8 text-base sm:text-lg xl:text-2xl/8 font-medium text-muted-foreground sm:max-w-md lg:max-w-none">
                  Discover GitHub bounties, contract work and jobs.<br class="hidden sm:block" />
                  Hire the top 1% open source developers.
                </p>
                <div class="mt-6 sm:mt-10 flex gap-4">
                  <.button
                    navigate={~p"/onboarding/org"}
                    class="h-10 sm:h-14 rounded-md px-8 sm:px-12 text-sm sm:text-xl"
                  >
                    Companies
                  </.button>
                  <.button
                    navigate={~p"/onboarding/dev"}
                    variant="secondary"
                    class="h-10 sm:h-14 rounded-md px-8 sm:px-12 text-sm sm:text-xl"
                  >
                    Developers
                  </.button>
                </div>
              </div>
              <!-- Featured devs -->
              <div class={
                classes([
                  "mt-8 sm:mt-14 flex justify-start md:justify-center gap-4 sm:gap-8 lg:justify-start lg:mt-0 lg:pl-0",
                  "overflow-x-auto scrollbar-thin lg:overflow-x-visible px-6 lg:px-8"
                ])
              }>
                <%= if length(@featured_devs) > 0 do %>
                  <div class="ml-auto w-28 min-[500px]:w-40 sm:w-56 lg:w-44 flex-none space-y-6 sm:space-y-8 pt-16 sm:pt-32 sm:ml-0 lg:order-last lg:pt-36 xl:order-none xl:pt-80">
                    <.dev_card dev={List.first(@featured_devs)} />
                  </div>
                  <div class="flex flex-col mr-auto w-28 min-[500px]:w-40 sm:w-56 lg:w-44 flex-none space-y-6 sm:space-y-8 sm:mr-0 lg:pt-36">
                    <%= if length(@featured_devs) >= 3 do %>
                      <%= for dev <- Enum.slice(@featured_devs, 1..2) do %>
                        <.dev_card dev={dev} />
                      <% end %>
                    <% end %>
                  </div>
                  <div class="flex flex-col w-28 min-[500px]:w-40 sm:w-56 lg:w-44 flex-none space-y-6 sm:space-y-8 pt-16 sm:pt-32 lg:pt-0">
                    <%= for dev <- Enum.slice(@featured_devs, 3..4) do %>
                      <.dev_card dev={dev} />
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </section>

        <section class="relative isolate">
          <div class="relative isolate -z-10 py-[35vw] sm:py-[25vw]">
            <div class="z-20 absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 transform">
              <div class="scale-[300%] sm:scale-[150%] opacity-75">
                <div class="[transform:perspective(4101px)_rotateX(51deg)_rotateY(-13deg)_rotateZ(40deg)]">
                  <img
                    alt="Algora dashboard"
                    width="1200"
                    height="630"
                    loading="lazy"
                    class="border border-border bg-muted mix-blend-overlay [box-shadow:0px_80px_60px_0px_rgba(0,0,0,0.35),0px_35px_28px_0px_rgba(0,0,0,0.25),0px_18px_15px_0px_rgba(0,0,0,0.20),0px_10px_8px_0px_rgba(0,0,0,0.17),0px_5px_4px_0px_rgba(0,0,0,0.14),0px_2px_2px_0px_rgba(0,0,0,0.10)]"
                    style="color:transparent"
                    src={~p"/images/screenshots/org-home.png"}
                  />
                </div>
              </div>
            </div>
            <div class="z-30 relative mx-auto max-w-7xl px-6 lg:px-8">
              <.glow class="absolute opacity-25 xl:opacity-75 top-[-320px] md:top-[-480px] xl:right-[120px] -z-[10]" />

              <.form
                for={@repo_form}
                phx-submit="submit_repo"
                class="mt-6 sm:mt-10 w-full max-w-lg xl:max-w-2xl mx-auto"
              >
                <div class="relative">
                  <.input
                    field={@repo_form[:url]}
                    placeholder="github.com/your/repo"
                    class={
                      classes([
                        "w-full h-10 sm:h-16 text-sm sm:text-lg xl:text-2xl pl-8 sm:pl-[3.75rem] pr-24 sm:pr-48 ring-2 ring-emerald-500 font-display rounded-lg sm:rounded-xl",
                        @repo_form[:url].errors != [] && "ring-destructive"
                      ])
                    }
                  />
                  <Logos.github class="size-5 sm:size-10 absolute left-2 sm:left-3 top-2 sm:top-3 text-muted-foreground/50" />
                  <.button
                    type="submit"
                    class="absolute right-2 top-1.5 sm:top-2 bottom-1.5 sm:bottom-2 px-2 sm:px-8 h-7 sm:h-[3rem] text-sm sm:text-xl sm:font-semibold drop-shadow-[0_1px_5px_#34d39980] rounded-lg sm:rounded-xl"
                  >
                    Let's try this
                  </.button>
                </div>
              </.form>
            </div>
          </div>
        </section>

        <section class="relative py-16 sm:py-40">
          <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-5xl text-center mb-2 sm:mb-4">
            Everything you need to
            <span class="text-emerald-400 block sm:inline">reward your contributors</span>
          </h2>
          <p class="text-center font-medium text-base text-muted-foreground sm:text-xl mb-12 mx-auto">
            Build your product and team in one place
          </p>
          <div class="hidden lg:grid lg:grid-cols-4 items-center lg:gap-8 lg:mx-auto lg:px-8">
            <div class="col-span-1">
              <div class="flex flex-col gap-8">
                <%= for {feature, index} <- org_features() |> Enum.with_index() do %>
                  <div
                    class="cursor-pointer"
                    phx-click={
                      %JS{}
                      |> AlgoraWeb.Util.transition("data-org-feature-img", feature.src,
                        from: "opacity-0",
                        to: "opacity-100"
                      )
                      |> AlgoraWeb.Util.transition("data-org-feature-card", feature.src,
                        from: "ring-transparent",
                        to: "ring-foreground/30"
                      )
                    }
                  >
                    <.card
                      data-org-feature-card={feature.src}
                      class={
                        classes([
                          "ring-1 ring-transparent transition-all rounded-xl",
                          if(index == 0, do: "ring-foreground/30")
                        ])
                      }
                    >
                      <.card_content class="p-4">
                        <div class="text-2xl font-bold text-foreground">
                          {feature.title}
                        </div>
                        <div class="text-sm text-muted-foreground pt-2">
                          {feature.description}
                        </div>
                      </.card_content>
                    </.card>
                  </div>
                <% end %>
              </div>
            </div>
            <div class="col-span-3">
              <div class="aspect-[1200/630] w-full relative">
                <%= for {feature, index} <- org_features() |> Enum.with_index() do %>
                  <img
                    data-org-feature-img={feature.src}
                    src={feature.src}
                    alt={feature.title}
                    class={
                      classes([
                        "w-full h-full object-contain absolute inset-0 opacity-0 transition-all rounded-xl",
                        if(index == 0, do: "opacity-100")
                      ])
                    }
                  />
                <% end %>
              </div>
            </div>
          </div>
          <div class="lg:hidden space-y-16 px-4 sm:px-6">
            <%= for feature <- org_features() do %>
              <div>
                <div class="text-xl font-bold text-foreground">
                  {feature.title}
                </div>
                <div class="pt-1 text-sm text-muted-foreground">
                  {feature.description}
                </div>
                <div class="mt-4 aspect-[1200/630] w-full relative overflow-hidden">
                  <img src={feature.src} alt={feature.title} class="w-full h-full object-contain" />
                </div>
              </div>
            <% end %>
          </div>
        </section>

        <section class="relative py-16 sm:py-40">
          <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-5xl text-center mb-2 sm:mb-4">
            Loved by developers and companies
          </h2>
          <div class="pt-12 max-w-7xl mx-auto px-6 lg:px-8">
            <.contributors />
          </div>
        </section>

        <section class="relative py-16 sm:py-40">
          <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-5xl text-center mb-2 sm:mb-4">
            Everything you need to
            <span class="text-emerald-400 block sm:inline">contribute and get rewarded</span>
          </h2>
          <p class="text-center font-medium text-base text-muted-foreground sm:text-xl mb-12 mx-auto">
            Find new collaborators, solve bounties and complete contract work
          </p>
          <div class="hidden lg:grid lg:grid-cols-4 items-center lg:gap-8 lg:mx-auto lg:px-8">
            <div class="col-span-1">
              <div class="flex flex-col gap-8">
                <%= for {feature, index} <- user_features() |> Enum.with_index() do %>
                  <div
                    class="cursor-pointer"
                    phx-click={
                      %JS{}
                      |> AlgoraWeb.Util.transition("data-user-feature-img", feature.src,
                        from: "opacity-0",
                        to: "opacity-100"
                      )
                      |> AlgoraWeb.Util.transition("data-user-feature-card", feature.src,
                        from: "ring-transparent",
                        to: "ring-foreground/30"
                      )
                    }
                  >
                    <.card
                      data-user-feature-card={feature.src}
                      class={
                        classes([
                          "ring-1 ring-transparent transition-all rounded-xl",
                          if(index == 0, do: "ring-foreground/30")
                        ])
                      }
                    >
                      <.card_content class="p-4">
                        <div class="text-2xl font-bold text-foreground">
                          {feature.title}
                        </div>
                        <div class="text-sm text-muted-foreground pt-2">
                          {feature.description}
                        </div>
                      </.card_content>
                    </.card>
                  </div>
                <% end %>
              </div>
            </div>
            <div class="col-span-3">
              <div class="aspect-[1200/630] w-full relative">
                <%= for {feature, index} <- user_features() |> Enum.with_index() do %>
                  <img
                    data-user-feature-img={feature.src}
                    src={feature.src}
                    alt={feature.title}
                    class={
                      classes([
                        "w-full h-full object-cover absolute inset-0 opacity-0 transition-all rounded-xl",
                        if(index == 0, do: "opacity-100")
                      ])
                    }
                  />
                <% end %>
              </div>
            </div>
          </div>
          <div class="lg:hidden space-y-16 px-4 sm:px-6">
            <%= for feature <- user_features() do %>
              <div>
                <div class="text-xl font-bold text-foreground">
                  {feature.title}
                </div>
                <div class="pt-1 text-sm text-muted-foreground">
                  {feature.description}
                </div>
                <div class="mt-4 aspect-[1200/630] w-full relative overflow-hidden">
                  <img src={feature.src} alt={feature.title} class="w-full h-full object-contain" />
                </div>
              </div>
            <% end %>
          </div>
        </section>

        <section class="relative isolate py-16 sm:py-40 z-10">
          <div class="mx-auto px-6 lg:px-8">
            <div class="relative z-10 pb-4 xl:py-16">
              <div class="mx-auto max-w-7xl sm:text-center">
                <div class="mx-auto max-w-3xl space-y-2 lg:max-w-none">
                  <h2 class="font-display text-2xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-2 sm:mb-4">
                    Simple, transparent pricing
                  </h2>
                  <p class="text-center font-medium text-base text-muted-foreground sm:text-xl mb-12 mx-auto">
                    For individuals, OSS communities, and open/closed source companies
                  </p>
                </div>
              </div>
            </div>

            <div class="mx-auto lg:max-w-[95rem] mb-8 mt-8">
              <div class="flex items-start gap-4">
                <div class="flex-1">
                  <h3 class="text-2xl font-semibold text-foreground mb-2">
                    <div class="flex items-center gap-2">
                      <.icon name="tabler-wallet" class="h-6 w-6 text-emerald-400" /> Payments
                    </div>
                  </h3>
                  <p class="text-base text-foreground-light">
                    Fund GitHub issues with USD rewards and pay when work is merged. Set up contracts for ongoing development work. Simple, outcome-based payments.
                  </p>
                </div>
              </div>
            </div>

            <div class="mx-auto grid grid-cols-1 gap-4 lg:gap-8 lg:max-w-[95rem] lg:grid-cols-2">
              <%= for plan <- @plans1 do %>
                <AlgoraWeb.PricingLive.pricing_card1 plan={plan} plans={@plans1} />
              <% end %>
            </div>
          </div>
        </section>

        <section class="relative isolate">
          <div class="relative isolate -z-10 py-[35vw] sm:py-[25vw]">
            <div class="z-20 absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 transform">
              <div class="scale-[300%] sm:scale-[150%] opacity-75">
                <div class="[transform:perspective(4101px)_rotateX(51deg)_rotateY(-13deg)_rotateZ(40deg)]">
                  <img
                    alt="Algora dashboard"
                    width="1200"
                    height="630"
                    loading="lazy"
                    class="border border-border bg-muted mix-blend-overlay [box-shadow:0px_80px_60px_0px_rgba(0,0,0,0.35),0px_35px_28px_0px_rgba(0,0,0,0.25),0px_18px_15px_0px_rgba(0,0,0,0.20),0px_10px_8px_0px_rgba(0,0,0,0.17),0px_5px_4px_0px_rgba(0,0,0,0.14),0px_2px_2px_0px_rgba(0,0,0,0.10)]"
                    style="color:transparent"
                    src={~p"/images/screenshots/org-dashboard.png"}
                  />
                </div>
              </div>
            </div>
            <div class="z-30 relative mx-auto max-w-7xl px-6 lg:px-8">
              <.glow class="absolute opacity-25 xl:opacity-75 top-[-320px] md:top-[-480px] xl:right-[120px] -z-[10]" />

              <.form
                for={@repo_form}
                phx-submit="submit_repo"
                class="mt-6 sm:mt-10 w-full max-w-lg xl:max-w-2xl mx-auto hidden"
              >
                <div class="relative">
                  <.input
                    field={@repo_form[:url]}
                    placeholder="github.com/your/repo"
                    class={
                      classes([
                        "w-full h-10 sm:h-16 text-sm sm:text-lg xl:text-2xl pl-8 sm:pl-[3.75rem] pr-24 sm:pr-48 ring-2 ring-emerald-500 font-display rounded-lg sm:rounded-xl",
                        @repo_form[:url].errors != [] && "ring-destructive"
                      ])
                    }
                  />
                  <Logos.github class="size-5 sm:size-10 absolute left-2 sm:left-3 top-2 sm:top-3 text-muted-foreground/50" />
                  <.button
                    type="submit"
                    class="absolute right-2 top-1.5 sm:top-2 bottom-1.5 sm:bottom-2 px-2 sm:px-8 h-7 sm:h-[3rem] text-sm sm:text-xl sm:font-semibold drop-shadow-[0_1px_5px_#34d39980] rounded-lg sm:rounded-xl"
                  >
                    Get Started
                  </.button>
                </div>
              </.form>
            </div>
          </div>
        </section>

        <section class="relative isolate py-16 sm:py-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="mb-8 text-3xl font-bold text-card-foreground text-center">
              <span class="text-muted-foreground">The open source</span>
              <span class="block sm:inline">Upwork for engineers</span>
            </h2>
            <div class="flex justify-center gap-4">
              <.button navigate={~p"/auth/signup"}>
                Get started
              </.button>
              <.button
                class="pointer-events-none opacity-75"
                href={AlgoraWeb.Constants.get(:github_repo_url)}
                variant="secondary"
              >
                <.icon name="github" class="size-4 mr-2 -ml-1" /> View source code
              </.button>
            </div>
          </div>
        </section>

        <div class="relative isolate overflow-hidden bg-gradient-to-br from-black to-background">
          <Footer.footer />
          <div class="mx-auto max-w-2xl px-6 pb-4 text-center text-[0.6rem] text-muted-foreground/50">
            Upwork® is a registered trademark of Upwork Global Inc. Algora is not affiliated with, sponsored by, or endorsed by Upwork Global Inc, mmmkay?
          </div>
        </div>
      </main>
    </div>

    <.modal_video_dialog />
    """
  end

  @impl true
  def handle_event("submit_repo", %{"repo_form" => params}, socket) do
    changeset =
      %RepoForm{}
      |> RepoForm.changeset(params)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      url = get_field(changeset, :url)

      case Algora.Util.parse_github_url(url) do
        {:ok, {repo_owner, repo_name}} ->
          token = Algora.Admin.token()

          case Workspace.ensure_repository(token, repo_owner, repo_name) do
            {:ok, _repo} ->
              {:noreply, push_navigate(socket, to: ~p"/go/#{repo_owner}/#{repo_name}")}

            {:error, reason} ->
              Logger.error("Failed to create repository: #{inspect(reason)}")
              {:noreply, assign(socket, :repo_form, to_form(add_error(changeset, :url, "Repository not found")))}
          end

        {:error, message} ->
          {:noreply, assign(socket, :repo_form, to_form(add_error(changeset, :url, message)))}
      end
    else
      {:noreply, assign(socket, :repo_form, to_form(changeset))}
    end
  end

  defp dev_card(assigns) do
    ~H"""
    <.link navigate={User.url(@dev)} target="_blank" class="relative">
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
    </.link>
    """
  end

  defp get_total_paid_out do
    subtotal =
      Repo.one(
        from(t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          select: sum(t.net_amount)
        )
      ) || Money.new(0, :USD)

    subtotal |> Money.add!(PlatformStats.get().extra_paid_out) |> Money.round(currency_digits: 0)
  end

  defp get_completed_bounties_count do
    bounties_subtotal =
      Repo.one(
        from(t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          where: not is_nil(t.bounty_id),
          select: count(fragment("DISTINCT (?, ?)", t.bounty_id, t.user_id))
        )
      ) || 0

    tips_subtotal =
      Repo.one(
        from(t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          where: not is_nil(t.tip_id),
          select: count(fragment("DISTINCT (?, ?)", t.tip_id, t.user_id))
        )
      ) || 0

    bounties_subtotal + tips_subtotal + PlatformStats.get().extra_completed_bounties
  end

  defp get_contributors_count do
    subtotal =
      Repo.one(
        from(t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          select: count(fragment("DISTINCT ?", t.user_id))
        )
      ) || 0

    subtotal + PlatformStats.get().extra_contributors
  end

  defp get_countries_count do
    Repo.one(
      from(u in User,
        join: t in Transaction,
        on: t.user_id == u.id,
        where: t.type == :credit,
        where: t.status == :succeeded,
        where: not is_nil(t.linked_transaction_id),
        where: not is_nil(u.country) and u.country != "",
        select: count(fragment("DISTINCT ?", u.country))
      )
    ) || 0
  end

  defp format_money(money), do: money |> Money.round(currency_digits: 0) |> Money.to_string!(no_fraction_if_integer: true)

  defp format_number(number), do: Number.Delimit.number_to_delimited(number, precision: 0)

  defp glow(assigns) do
    ~H"""
    <%!-- "absolute top-[-320px] md:top-[-480px] xl:right-[120px] -z-[10]" --%>
    <div class={@class}>
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="472"
        height="638"
        viewBox="0 0 472 638"
        fill="none"
        class="scale-[2]"
      >
        <g opacity="0.4">
          <g style="mix-blend-mode:lighten" filter="url(#filter0_f_825_3716)">
            <ellipse
              cx="184.597"
              cy="353.647"
              rx="16.3892"
              ry="146.673"
              transform="rotate(15.0538 184.597 353.647)"
              fill="url(#paint0_linear_825_3716)"
              fill-opacity="0.5"
            >
            </ellipse>
          </g>
          <g style="mix-blend-mode:color-dodge" filter="url(#filter1_f_825_3716)">
            <ellipse
              cx="237.5"
              cy="343.125"
              rx="13.25"
              ry="146.625"
              fill="url(#paint1_linear_825_3716)"
              fill-opacity="0.5"
            >
            </ellipse>
          </g>
          <g style="mix-blend-mode:lighten" filter="url(#filter2_f_825_3716)">
            <ellipse
              cx="289.17"
              cy="378.792"
              rx="11.1897"
              ry="190.642"
              transform="rotate(-15 289.17 378.792)"
              fill="url(#paint2_linear_825_3716)"
              fill-opacity="0.5"
            >
            </ellipse>
          </g>
          <g style="mix-blend-mode:lighten" filter="url(#filter3_f_825_3716)">
            <ellipse
              cx="263.208"
              cy="281.902"
              rx="11.1897"
              ry="90.3336"
              transform="rotate(-15 263.208 281.902)"
              fill="url(#paint3_linear_825_3716)"
              fill-opacity="0.5"
            >
            </ellipse>
          </g>
          <g style="mix-blend-mode:lighten" filter="url(#filter4_f_825_3716)">
            <ellipse
              cx="235.875"
              cy="402.5"
              rx="11.125"
              ry="190.75"
              fill="url(#paint4_linear_825_3716)"
              fill-opacity="0.5"
            >
            </ellipse>
          </g>
          <g style="mix-blend-mode:lighten" filter="url(#filter5_f_825_3716)">
            <ellipse
              cx="235.75"
              cy="290.25"
              rx="160.75"
              ry="93.75"
              fill="url(#paint5_linear_825_3716)"
              fill-opacity="0.5"
            >
            </ellipse>
          </g>
          <g style="mix-blend-mode:lighten" filter="url(#filter6_f_825_3716)">
            <ellipse
              cx="235.75"
              cy="244.25"
              rx="80.25"
              ry="47.75"
              fill="url(#paint6_linear_825_3716)"
              fill-opacity="0.5"
            >
            </ellipse>
          </g>
          <g style="mix-blend-mode:lighten" filter="url(#filter7_f_825_3716)">
            <ellipse
              cx="235.75"
              cy="247.875"
              rx="67.5"
              ry="40.125"
              fill="url(#paint7_linear_825_3716)"
              fill-opacity="0.5"
            >
            </ellipse>
          </g>
        </g>
        <mask id="path-9-inside-1_825_3716" fill="white">
          <path d="M204 161H212V593H204V161Z"></path>
        </mask>
        <path
          d="M211.5 161V593H212.5V161H211.5ZM204.5 593V161H203.5V593H204.5Z"
          fill="url(#paint8_angular_825_3716)"
          fill-opacity="0.5"
          mask="url(#path-9-inside-1_825_3716)"
        >
        </path>
        <mask id="path-11-inside-2_825_3716" fill="white">
          <path d="M180 51H188V483H180V51Z"></path>
        </mask>
        <path
          d="M187.5 51V483H188.5V51H187.5ZM180.5 483V51H179.5V483H180.5Z"
          fill="url(#paint9_angular_825_3716)"
          fill-opacity="0.2"
          mask="url(#path-11-inside-2_825_3716)"
        >
        </path>
        <mask id="path-13-inside-3_825_3716" fill="white">
          <path d="M228 101H236V533H228V101Z"></path>
        </mask>
        <path
          d="M235.5 101V533H236.5V101H235.5ZM228.5 533V101H227.5V533H228.5Z"
          fill="url(#paint10_angular_825_3716)"
          fill-opacity="0.3"
          mask="url(#path-13-inside-3_825_3716)"
        >
        </path>
        <mask id="path-15-inside-4_825_3716" fill="white">
          <path d="M252 191H260V623H252V191Z"></path>
        </mask>
        <path
          d="M259.5 191V623H260.5V191H259.5ZM252.5 623V191H251.5V623H252.5Z"
          fill="url(#paint11_angular_825_3716)"
          fill-opacity="0.8"
          mask="url(#path-15-inside-4_825_3716)"
        >
        </path>
        <mask id="path-17-inside-5_825_3716" fill="white">
          <path d="M276 1H284V433H276V1Z"></path>
        </mask>
        <path
          d="M283.5 1V433H284.5V1H283.5ZM276.5 433V1H275.5V433H276.5Z"
          fill="url(#paint12_angular_825_3716)"
          fill-opacity="0.1"
          mask="url(#path-17-inside-5_825_3716)"
        >
        </path>
        <defs>
          <filter
            id="filter0_f_825_3716"
            x="98.835"
            y="167.442"
            width="171.524"
            height="372.409"
            filterUnits="userSpaceOnUse"
            color-interpolation-filters="sRGB"
          >
            <feFlood flood-opacity="0" result="BackgroundImageFix"></feFlood>
            <feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape">
            </feBlend>
            <feGaussianBlur stdDeviation="22.25" result="effect1_foregroundBlur_825_3716">
            </feGaussianBlur>
          </filter>
          <filter
            id="filter1_f_825_3716"
            x="179.75"
            y="152"
            width="115.5"
            height="382.25"
            filterUnits="userSpaceOnUse"
            color-interpolation-filters="sRGB"
          >
            <feFlood flood-opacity="0" result="BackgroundImageFix"></feFlood>
            <feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape">
            </feBlend>
            <feGaussianBlur stdDeviation="22.25" result="effect1_foregroundBlur_825_3716">
            </feGaussianBlur>
          </filter>
          <filter
            id="filter2_f_825_3716"
            x="194.147"
            y="150.123"
            width="190.045"
            height="457.338"
            filterUnits="userSpaceOnUse"
            color-interpolation-filters="sRGB"
          >
            <feFlood flood-opacity="0" result="BackgroundImageFix"></feFlood>
            <feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape">
            </feBlend>
            <feGaussianBlur stdDeviation="22.25" result="effect1_foregroundBlur_825_3716">
            </feGaussianBlur>
          </filter>
          <filter
            id="filter3_f_825_3716"
            x="192.944"
            y="150.097"
            width="140.527"
            height="263.609"
            filterUnits="userSpaceOnUse"
            color-interpolation-filters="sRGB"
          >
            <feFlood flood-opacity="0" result="BackgroundImageFix"></feFlood>
            <feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape">
            </feBlend>
            <feGaussianBlur stdDeviation="22.25" result="effect1_foregroundBlur_825_3716">
            </feGaussianBlur>
          </filter>
          <filter
            id="filter4_f_825_3716"
            x="180.25"
            y="167.25"
            width="111.25"
            height="470.5"
            filterUnits="userSpaceOnUse"
            color-interpolation-filters="sRGB"
          >
            <feFlood flood-opacity="0" result="BackgroundImageFix"></feFlood>
            <feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape">
            </feBlend>
            <feGaussianBlur stdDeviation="22.25" result="effect1_foregroundBlur_825_3716">
            </feGaussianBlur>
          </filter>
          <filter
            id="filter5_f_825_3716"
            x="7.62939e-06"
            y="121.5"
            width="471.5"
            height="337.5"
            filterUnits="userSpaceOnUse"
            color-interpolation-filters="sRGB"
          >
            <feFlood flood-opacity="0" result="BackgroundImageFix"></feFlood>
            <feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape">
            </feBlend>
            <feGaussianBlur stdDeviation="37.5" result="effect1_foregroundBlur_825_3716">
            </feGaussianBlur>
          </filter>
          <filter
            id="filter6_f_825_3716"
            x="80.5"
            y="121.5"
            width="310.5"
            height="245.5"
            filterUnits="userSpaceOnUse"
            color-interpolation-filters="sRGB"
          >
            <feFlood flood-opacity="0" result="BackgroundImageFix"></feFlood>
            <feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape">
            </feBlend>
            <feGaussianBlur stdDeviation="37.5" result="effect1_foregroundBlur_825_3716">
            </feGaussianBlur>
          </filter>
          <filter
            id="filter7_f_825_3716"
            x="93.25"
            y="132.75"
            width="285"
            height="230.25"
            filterUnits="userSpaceOnUse"
            color-interpolation-filters="sRGB"
          >
            <feFlood flood-opacity="0" result="BackgroundImageFix"></feFlood>
            <feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape">
            </feBlend>
            <feGaussianBlur stdDeviation="37.5" result="effect1_foregroundBlur_825_3716">
            </feGaussianBlur>
          </filter>
          <linearGradient
            id="paint0_linear_825_3716"
            x1="184.597"
            y1="206.974"
            x2="184.597"
            y2="500.319"
            gradientUnits="userSpaceOnUse"
          >
            <stop stop-color="white"></stop>
            <stop offset="1" stop-color="white" stop-opacity="0"></stop>
          </linearGradient>
          <linearGradient
            id="paint1_linear_825_3716"
            x1="237.5"
            y1="196.5"
            x2="237.5"
            y2="489.75"
            gradientUnits="userSpaceOnUse"
          >
            <stop stop-color="white"></stop>
            <stop offset="1" stop-color="white" stop-opacity="0"></stop>
          </linearGradient>
          <linearGradient
            id="paint2_linear_825_3716"
            x1="289.17"
            y1="188.151"
            x2="289.17"
            y2="569.434"
            gradientUnits="userSpaceOnUse"
          >
            <stop stop-color="white"></stop>
            <stop offset="1" stop-color="white" stop-opacity="0"></stop>
          </linearGradient>
          <linearGradient
            id="paint3_linear_825_3716"
            x1="263.208"
            y1="191.568"
            x2="263.208"
            y2="372.236"
            gradientUnits="userSpaceOnUse"
          >
            <stop stop-color="white"></stop>
            <stop offset="1" stop-color="white" stop-opacity="0"></stop>
          </linearGradient>
          <linearGradient
            id="paint4_linear_825_3716"
            x1="235.875"
            y1="211.75"
            x2="235.875"
            y2="593.251"
            gradientUnits="userSpaceOnUse"
          >
            <stop stop-color="white"></stop>
            <stop offset="1" stop-color="white" stop-opacity="0"></stop>
          </linearGradient>
          <linearGradient
            id="paint5_linear_825_3716"
            x1="235.75"
            y1="196.5"
            x2="235.75"
            y2="384.001"
            gradientUnits="userSpaceOnUse"
          >
            <stop stop-color="white"></stop>
            <stop offset="1" stop-color="white" stop-opacity="0"></stop>
          </linearGradient>
          <linearGradient
            id="paint6_linear_825_3716"
            x1="235.75"
            y1="196.5"
            x2="235.75"
            y2="292"
            gradientUnits="userSpaceOnUse"
          >
            <stop stop-color="white"></stop>
            <stop offset="1" stop-color="white" stop-opacity="0"></stop>
          </linearGradient>
          <linearGradient
            id="paint7_linear_825_3716"
            x1="235.75"
            y1="207.75"
            x2="235.75"
            y2="288"
            gradientUnits="userSpaceOnUse"
          >
            <stop stop-color="white"></stop>
            <stop offset="1" stop-color="white" stop-opacity="0"></stop>
          </linearGradient>
          <radialGradient
            id="paint8_angular_825_3716"
            cx="0"
            cy="0"
            r="1"
            gradientUnits="userSpaceOnUse"
            gradientTransform="translate(208 481) scale(32 185)"
          >
            <stop stop-color="white"></stop>
            <stop offset="0.0001" stop-color="white" stop-opacity="0"></stop>
            <stop offset="0.784842" stop-color="white" stop-opacity="0"></stop>
          </radialGradient>
          <radialGradient
            id="paint9_angular_825_3716"
            cx="0"
            cy="0"
            r="1"
            gradientUnits="userSpaceOnUse"
            gradientTransform="translate(184 371) scale(32 185)"
          >
            <stop stop-color="white"></stop>
            <stop offset="0.0001" stop-color="white" stop-opacity="0"></stop>
            <stop offset="0.784842" stop-color="white" stop-opacity="0"></stop>
          </radialGradient>
          <radialGradient
            id="paint10_angular_825_3716"
            cx="0"
            cy="0"
            r="1"
            gradientUnits="userSpaceOnUse"
            gradientTransform="translate(232 421) scale(32 185)"
          >
            <stop stop-color="white"></stop>
            <stop offset="0.0001" stop-color="white" stop-opacity="0"></stop>
            <stop offset="0.784842" stop-color="white" stop-opacity="0"></stop>
          </radialGradient>
          <radialGradient
            id="paint11_angular_825_3716"
            cx="0"
            cy="0"
            r="1"
            gradientUnits="userSpaceOnUse"
            gradientTransform="translate(256 511) scale(32 185)"
          >
            <stop stop-color="white"></stop>
            <stop offset="0.0001" stop-color="white" stop-opacity="0"></stop>
            <stop offset="0.784842" stop-color="white" stop-opacity="0"></stop>
          </radialGradient>
          <radialGradient
            id="paint12_angular_825_3716"
            cx="0"
            cy="0"
            r="1"
            gradientUnits="userSpaceOnUse"
            gradientTransform="translate(280 321) scale(32 185)"
          >
            <stop stop-color="white"></stop>
            <stop offset="0.0001" stop-color="white" stop-opacity="0"></stop>
            <stop offset="0.784842" stop-color="white" stop-opacity="0"></stop>
          </radialGradient>
        </defs>
      </svg>
    </div>
    """
  end

  defp contributors(assigns) do
    ~H"""
    <div class="relative w-full flex flex-col gap-8">
      <div class="relative flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4 sm:gap-8 border bg-card rounded-xl text-card-foreground shadow p-6">
        <div class="xl:basis-[28.5714286%]">
          <div class="flex items-center gap-4">
            <a
              href="http://localhost:4000/@/ghostdogpr"
              data-phx-link="redirect"
              data-phx-link-state="push"
            >
              <div class="relative rounded-full shrink-0 overflow-hidden w-16 h-16">
                <img
                  id="avatar-image-GDQe_sWEWq2wbkzB"
                  src="https://algora-console.fly.storage.tigris.dev/avatars/ghostdogpr.jpg"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Pierre Ricadat"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  PI
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
            </a>
            <!-- </Phoenix.Component.link> -->

            <div>
              <div class="flex items-center gap-4 text-foreground">
                <a
                  href="http://localhost:4000/@/ghostdogpr"
                  data-phx-link="redirect"
                  data-phx-link-state="push"
                  class="text-lg sm:text-xl font-semibold hover:underline truncate"
                >
                  Pierre Ricadat 🇰🇷
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
              <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground sm:text-sm">
                <a
                  href="https://github.com/ghostdogpr"
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <svg
                    class="shrink-0 h-4 w-4"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path d="M12 0C5.37017 0 0 5.50708 0 12.306C0 17.745 3.44015 22.3532 8.20626 23.9849C8.80295 24.0982 9.02394 23.7205 9.02394 23.3881C9.02394 23.0935 9.01657 22.3229 9.00921 21.2956C5.67219 22.0359 4.96501 19.6487 4.96501 19.6487C4.41989 18.2285 3.63168 17.8508 3.63168 17.8508C2.54144 17.0878 3.71271 17.1029 3.71271 17.1029C4.91344 17.1936 5.55433 18.372 5.55433 18.372C6.62247 20.2531 8.36096 19.7092 9.04604 19.3919C9.15654 18.5987 9.46593 18.0548 9.80479 17.745C7.13812 17.4353 4.33886 16.3777 4.33886 11.6638C4.33886 10.3192 4.80295 9.2238 5.57643 8.36261C5.4512 8.05288 5.03867 6.79887 5.69429 5.1067C5.69429 5.1067 6.7035 4.77432 8.99447 6.36827C9.95212 6.09632 10.9761 5.96034 12 5.95279C13.0166 5.95279 14.0479 6.09632 15.0055 6.36827C17.2965 4.77432 18.3057 5.1067 18.3057 5.1067C18.9613 6.79887 18.5488 8.05288 18.4236 8.36261C19.1897 9.2238 19.6538 10.3192 19.6538 11.6638C19.6538 16.3928 16.8471 17.4278 14.1731 17.7375C14.6004 18.1152 14.9908 18.8706 14.9908 20.0189C14.9908 21.6657 14.9761 22.9877 14.9761 23.3957C14.9761 23.728 15.1897 24.1058 15.8011 23.9849C20.5672 22.3532 24 17.745 24 12.3135C24 5.50708 18.6298 0 12 0Z">
                    </path>
                  </svg>
                  <!-- </AlgoraWeb.Components.Logos.github> -->
                  <span class="line-clamp-1">ghostdogpr</span>
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
            </div>
          </div>
        </div>

        <div class="flex xl:flex-col gap-2 xl:basis-[14.2857143%] xl:ml-auto">
          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-blue-400/50 hover:bg-blue-800/10 hover:text-blue-300 hover:drop-shadow-[0_1px_5px_#60a5fa80] focus:border-blue-400/50 focus:bg-blue-800/10 focus:text-blue-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#60a5fa80] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="bounty"
            phx-value-user_id="clv1r9yxx0000l60g8kgd10fo"
          >
            <span class="tabler-diamond size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Bounty

          </button>

          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-emerald-400/50 hover:bg-emerald-800/10 hover:text-emerald-300 hover:drop-shadow-[0_1px_5px_#34d39980] focus:border-emerald-400/50 focus:bg-emerald-800/10 focus:text-emerald-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#34d39980] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="contract"
            phx-value-user_id="clv1r9yxx0000l60g8kgd10fo"
          >
            <span class="tabler-contract size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Contract

          </button>
        </div>

        <div class="pt-2 xl:pt-0 xl:pl-8 xl:basis-[57.1428571%] xl:border-l xl:border-border">
          <div class="text-sm sm:text-base text-foreground font-medium">
            Completed
            <span class="font-semibold font-display">
              2
              bounties
            </span>
            <span class="font-semibold font-display">
              across 2 projects
            </span>
            <span class="font-semibold font-display">
              ($1,750)
            </span>
          </div>
          <div class="pt-4 flex flex-col sm:flex-row sm:flex-wrap 2xl:flex-nowrap gap-4 xl:gap-8">
            <a
              href="http://localhost:4000/org/ZIO"
              data-phx-link="redirect"
              data-phx-link-state="push"
              class="flex flex-1 items-center gap-2 sm:gap-4 text-sm rounded-lg"
            >
              <div class="relative rounded-lg shrink-0 overflow-hidden bg-gradient-to-br brightness-75 saturate-0 w-10 h-10">
                <img
                  id="avatar-image-GDQe_sWM7JSwbk0B"
                  src="https://app.algora.io/asset/storage/v1/object/public/images/org/ZIO-logo.png"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="ZIO"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  ZI
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
              <div class="flex flex-col">
                <div class="text-base font-medium text-muted-foreground">
                  ZIO
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <span class="tabler-star-filled size-4 text-amber-400 mr-1"></span>
                    <!-- </AlgoraWeb.CoreComponents.icon> -->4.2K
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-emerald-400 font-display font-semibold">
                      $1,250
                    </span>
                    awarded
                  </div>
                </div>
              </div>
            </a>
            <!-- </Phoenix.Component.link> -->

            <a
              href="http://localhost:4000/org/getkyo"
              data-phx-link="redirect"
              data-phx-link-state="push"
              class="flex flex-1 items-center gap-2 sm:gap-4 text-sm rounded-lg"
            >
              <div class="relative rounded-lg shrink-0 overflow-hidden bg-gradient-to-br brightness-75 saturate-0 w-10 h-10">
                <img
                  id="avatar-image-GDQe_sWOoZ-wbk1B"
                  src="https://avatars.githubusercontent.com/u/128566993?v=4"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Kyo"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  KY
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
              <div class="flex flex-col">
                <div class="text-base font-medium text-muted-foreground">
                  Kyo
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <span class="tabler-star-filled size-4 text-amber-400 mr-1"></span>
                    <!-- </AlgoraWeb.CoreComponents.icon> -->628
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-emerald-400 font-display font-semibold">
                      $500
                    </span>
                    awarded
                  </div>
                </div>
              </div>
            </a>
            <!-- </Phoenix.Component.link> -->

          </div>
        </div>
      </div>
      <!-- </AlgoraWeb.Org.DashboardLive.match_card> -->

      <div class="relative flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4 sm:gap-8 border bg-card rounded-xl text-card-foreground shadow p-6">
        <div class="xl:basis-[28.5714286%]">
          <div class="flex items-center gap-4">
            <a
              href="http://localhost:4000/@/pablf"
              data-phx-link="redirect"
              data-phx-link-state="push"
            >
              <div class="relative rounded-full shrink-0 overflow-hidden w-16 h-16">
                <img
                  id="avatar-image-GDQe_sWQsCWwbk2B"
                  src="https://algora-console.fly.storage.tigris.dev/avatars/pablf.png"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Pablo Femenía"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  PA
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
            </a>
            <!-- </Phoenix.Component.link> -->

            <div>
              <div class="flex items-center gap-4 text-foreground">
                <a
                  href="http://localhost:4000/@/pablf"
                  data-phx-link="redirect"
                  data-phx-link-state="push"
                  class="text-lg sm:text-xl font-semibold hover:underline truncate"
                >
                  Pablo Femenía 🇪🇸
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
              <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground sm:text-sm">
                <a
                  href="https://github.com/pablf"
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <svg
                    class="shrink-0 h-4 w-4"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path d="M12 0C5.37017 0 0 5.50708 0 12.306C0 17.745 3.44015 22.3532 8.20626 23.9849C8.80295 24.0982 9.02394 23.7205 9.02394 23.3881C9.02394 23.0935 9.01657 22.3229 9.00921 21.2956C5.67219 22.0359 4.96501 19.6487 4.96501 19.6487C4.41989 18.2285 3.63168 17.8508 3.63168 17.8508C2.54144 17.0878 3.71271 17.1029 3.71271 17.1029C4.91344 17.1936 5.55433 18.372 5.55433 18.372C6.62247 20.2531 8.36096 19.7092 9.04604 19.3919C9.15654 18.5987 9.46593 18.0548 9.80479 17.745C7.13812 17.4353 4.33886 16.3777 4.33886 11.6638C4.33886 10.3192 4.80295 9.2238 5.57643 8.36261C5.4512 8.05288 5.03867 6.79887 5.69429 5.1067C5.69429 5.1067 6.7035 4.77432 8.99447 6.36827C9.95212 6.09632 10.9761 5.96034 12 5.95279C13.0166 5.95279 14.0479 6.09632 15.0055 6.36827C17.2965 4.77432 18.3057 5.1067 18.3057 5.1067C18.9613 6.79887 18.5488 8.05288 18.4236 8.36261C19.1897 9.2238 19.6538 10.3192 19.6538 11.6638C19.6538 16.3928 16.8471 17.4278 14.1731 17.7375C14.6004 18.1152 14.9908 18.8706 14.9908 20.0189C14.9908 21.6657 14.9761 22.9877 14.9761 23.3957C14.9761 23.728 15.1897 24.1058 15.8011 23.9849C20.5672 22.3532 24 17.745 24 12.3135C24 5.50708 18.6298 0 12 0Z">
                    </path>
                  </svg>
                  <!-- </AlgoraWeb.Components.Logos.github> -->
                  <span class="line-clamp-1">pablf</span>
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
            </div>
          </div>
        </div>

        <div class="flex xl:flex-col gap-2 xl:basis-[14.2857143%] xl:ml-auto">
          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-blue-400/50 hover:bg-blue-800/10 hover:text-blue-300 hover:drop-shadow-[0_1px_5px_#60a5fa80] focus:border-blue-400/50 focus:bg-blue-800/10 focus:text-blue-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#60a5fa80] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="bounty"
            phx-value-user_id="clhqz0nwc000amf0fjkpapthz"
          >
            <span class="tabler-diamond size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Bounty

          </button>

          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-emerald-400/50 hover:bg-emerald-800/10 hover:text-emerald-300 hover:drop-shadow-[0_1px_5px_#34d39980] focus:border-emerald-400/50 focus:bg-emerald-800/10 focus:text-emerald-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#34d39980] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="contract"
            phx-value-user_id="clhqz0nwc000amf0fjkpapthz"
          >
            <span class="tabler-contract size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Contract

          </button>
        </div>

        <div class="pt-2 xl:pt-0 xl:pl-8 xl:basis-[57.1428571%] xl:border-l xl:border-border">
          <div class="text-sm sm:text-base text-foreground font-medium">
            Completed
            <span class="font-semibold font-display">
              34
              bounties
            </span>
            <span class="font-semibold font-display">
              across 4 projects
            </span>
            <span class="font-semibold font-display">
              ($9,050)
            </span>
          </div>
          <div class="pt-4 flex flex-col sm:flex-row sm:flex-wrap 2xl:flex-nowrap gap-4 xl:gap-8">
            <a
              href="http://localhost:4000/org/ZIO"
              data-phx-link="redirect"
              data-phx-link-state="push"
              class="flex flex-1 items-center gap-2 sm:gap-4 text-sm rounded-lg"
            >
              <div class="relative rounded-lg shrink-0 overflow-hidden bg-gradient-to-br brightness-75 saturate-0 w-10 h-10">
                <img
                  id="avatar-image-GDQe_sWYAFewbk3B"
                  src="https://app.algora.io/asset/storage/v1/object/public/images/org/ZIO-logo.png"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="ZIO"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  ZI
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
              <div class="flex flex-col">
                <div class="text-base font-medium text-muted-foreground">
                  ZIO
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <span class="tabler-star-filled size-4 text-amber-400 mr-1"></span>
                    <!-- </AlgoraWeb.CoreComponents.icon> -->4.2K
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-emerald-400 font-display font-semibold">
                      $7,700
                    </span>
                    awarded
                  </div>
                </div>
              </div>
            </a>
            <!-- </Phoenix.Component.link> -->

            <a
              href="http://localhost:4000/org/getkyo"
              data-phx-link="redirect"
              data-phx-link-state="push"
              class="flex flex-1 items-center gap-2 sm:gap-4 text-sm rounded-lg"
            >
              <div class="relative rounded-lg shrink-0 overflow-hidden bg-gradient-to-br brightness-75 saturate-0 w-10 h-10">
                <img
                  id="avatar-image-GDQe_sWa53-wbk4B"
                  src="https://avatars.githubusercontent.com/u/128566993?v=4"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Kyo"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  KY
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
              <div class="flex flex-col">
                <div class="text-base font-medium text-muted-foreground">
                  Kyo
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <span class="tabler-star-filled size-4 text-amber-400 mr-1"></span>
                    <!-- </AlgoraWeb.CoreComponents.icon> -->628
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-emerald-400 font-display font-semibold">
                      $500
                    </span>
                    awarded
                  </div>
                </div>
              </div>
            </a>
            <!-- </Phoenix.Component.link> -->

          </div>
        </div>
      </div>
      <!-- </AlgoraWeb.Org.DashboardLive.match_card> -->

      <div class="relative flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4 sm:gap-8 border bg-card rounded-xl text-card-foreground shadow p-6">
        <div class="xl:basis-[28.5714286%]">
          <div class="flex items-center gap-4">
            <a
              href="http://localhost:4000/@/melkstam"
              data-phx-link="redirect"
              data-phx-link-state="push"
            >
              <div class="relative rounded-full shrink-0 overflow-hidden w-16 h-16">
                <img
                  id="avatar-image-GDQe_sWcmLKwbk5B"
                  src="https://algora-console.fly.storage.tigris.dev/avatars/melkstam.png"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Vilhelm Melkstam"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  VI
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
            </a>
            <!-- </Phoenix.Component.link> -->

            <div>
              <div class="flex items-center gap-4 text-foreground">
                <a
                  href="http://localhost:4000/@/melkstam"
                  data-phx-link="redirect"
                  data-phx-link-state="push"
                  class="text-lg sm:text-xl font-semibold hover:underline truncate"
                >
                  Vilhelm Melkstam 🇸🇪
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
              <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground sm:text-sm">
                <a
                  href="https://github.com/melkstam"
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <svg
                    class="shrink-0 h-4 w-4"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path d="M12 0C5.37017 0 0 5.50708 0 12.306C0 17.745 3.44015 22.3532 8.20626 23.9849C8.80295 24.0982 9.02394 23.7205 9.02394 23.3881C9.02394 23.0935 9.01657 22.3229 9.00921 21.2956C5.67219 22.0359 4.96501 19.6487 4.96501 19.6487C4.41989 18.2285 3.63168 17.8508 3.63168 17.8508C2.54144 17.0878 3.71271 17.1029 3.71271 17.1029C4.91344 17.1936 5.55433 18.372 5.55433 18.372C6.62247 20.2531 8.36096 19.7092 9.04604 19.3919C9.15654 18.5987 9.46593 18.0548 9.80479 17.745C7.13812 17.4353 4.33886 16.3777 4.33886 11.6638C4.33886 10.3192 4.80295 9.2238 5.57643 8.36261C5.4512 8.05288 5.03867 6.79887 5.69429 5.1067C5.69429 5.1067 6.7035 4.77432 8.99447 6.36827C9.95212 6.09632 10.9761 5.96034 12 5.95279C13.0166 5.95279 14.0479 6.09632 15.0055 6.36827C17.2965 4.77432 18.3057 5.1067 18.3057 5.1067C18.9613 6.79887 18.5488 8.05288 18.4236 8.36261C19.1897 9.2238 19.6538 10.3192 19.6538 11.6638C19.6538 16.3928 16.8471 17.4278 14.1731 17.7375C14.6004 18.1152 14.9908 18.8706 14.9908 20.0189C14.9908 21.6657 14.9761 22.9877 14.9761 23.3957C14.9761 23.728 15.1897 24.1058 15.8011 23.9849C20.5672 22.3532 24 17.745 24 12.3135C24 5.50708 18.6298 0 12 0Z">
                    </path>
                  </svg>
                  <!-- </AlgoraWeb.Components.Logos.github> -->
                  <span class="line-clamp-1">melkstam</span>
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
            </div>
          </div>
        </div>

        <div class="flex xl:flex-col gap-2 xl:basis-[14.2857143%] xl:ml-auto">
          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-blue-400/50 hover:bg-blue-800/10 hover:text-blue-300 hover:drop-shadow-[0_1px_5px_#60a5fa80] focus:border-blue-400/50 focus:bg-blue-800/10 focus:text-blue-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#60a5fa80] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="bounty"
            phx-value-user_id="cm84w1on40002jo0362h4d9vl"
          >
            <span class="tabler-diamond size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Bounty

          </button>

          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-emerald-400/50 hover:bg-emerald-800/10 hover:text-emerald-300 hover:drop-shadow-[0_1px_5px_#34d39980] focus:border-emerald-400/50 focus:bg-emerald-800/10 focus:text-emerald-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#34d39980] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="contract"
            phx-value-user_id="cm84w1on40002jo0362h4d9vl"
          >
            <span class="tabler-contract size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Contract

          </button>
        </div>

        <div class="pt-2 xl:pt-0 xl:pl-8 xl:basis-[57.1428571%] xl:border-l xl:border-border">
          <div class="text-sm sm:text-base text-foreground font-medium">
            Completed
            <span class="font-semibold font-display">
              1
              bounty
            </span>
            <span class="font-semibold font-display">
              in 1 project
            </span>
            <span class="font-semibold font-display">
              ($1,000)
            </span>
          </div>
          <div class="pt-4 flex flex-col sm:flex-row sm:flex-wrap 2xl:flex-nowrap gap-4 xl:gap-8">
            <a
              href="http://localhost:4000/org/encoredev"
              data-phx-link="redirect"
              data-phx-link-state="push"
              class="flex flex-1 items-center gap-2 sm:gap-4 text-sm rounded-lg"
            >
              <div class="relative rounded-lg shrink-0 overflow-hidden bg-gradient-to-br brightness-75 saturate-0 w-10 h-10">
                <img
                  id="avatar-image-GDQe_sWkH1qwbk6B"
                  src="https://avatars.githubusercontent.com/u/50438175?v=4"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Encore"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  EN
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
              <div class="flex flex-col">
                <div class="text-base font-medium text-muted-foreground">
                  Encore
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <span class="tabler-star-filled size-4 text-amber-400 mr-1"></span>
                    <!-- </AlgoraWeb.CoreComponents.icon> -->272
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-emerald-400 font-display font-semibold">
                      $1,000
                    </span>
                    awarded
                  </div>
                </div>
              </div>
            </a>
            <!-- </Phoenix.Component.link> -->

          </div>
        </div>
      </div>
      <!-- </AlgoraWeb.Org.DashboardLive.match_card> -->

      <div class="relative flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4 sm:gap-8 border bg-card rounded-xl text-card-foreground shadow p-6">
        <div class="xl:basis-[28.5714286%]">
          <div class="flex items-center gap-4">
            <a
              href="http://localhost:4000/@/itsparser"
              data-phx-link="redirect"
              data-phx-link-state="push"
            >
              <div class="relative rounded-full shrink-0 overflow-hidden w-16 h-16">
                <img
                  id="avatar-image-GDQe_sWmLTWwbk7B"
                  src="https://algora-console.fly.storage.tigris.dev/avatars/itsparser.png"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Vasanth K."
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  VA
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
            </a>
            <!-- </Phoenix.Component.link> -->

            <div>
              <div class="flex items-center gap-4 text-foreground">
                <a
                  href="http://localhost:4000/@/itsparser"
                  data-phx-link="redirect"
                  data-phx-link-state="push"
                  class="text-lg sm:text-xl font-semibold hover:underline truncate"
                >
                  Vasanth K. 🇮🇳
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
              <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground sm:text-sm">
                <a
                  href="https://github.com/itsparser"
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <svg
                    class="shrink-0 h-4 w-4"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path d="M12 0C5.37017 0 0 5.50708 0 12.306C0 17.745 3.44015 22.3532 8.20626 23.9849C8.80295 24.0982 9.02394 23.7205 9.02394 23.3881C9.02394 23.0935 9.01657 22.3229 9.00921 21.2956C5.67219 22.0359 4.96501 19.6487 4.96501 19.6487C4.41989 18.2285 3.63168 17.8508 3.63168 17.8508C2.54144 17.0878 3.71271 17.1029 3.71271 17.1029C4.91344 17.1936 5.55433 18.372 5.55433 18.372C6.62247 20.2531 8.36096 19.7092 9.04604 19.3919C9.15654 18.5987 9.46593 18.0548 9.80479 17.745C7.13812 17.4353 4.33886 16.3777 4.33886 11.6638C4.33886 10.3192 4.80295 9.2238 5.57643 8.36261C5.4512 8.05288 5.03867 6.79887 5.69429 5.1067C5.69429 5.1067 6.7035 4.77432 8.99447 6.36827C9.95212 6.09632 10.9761 5.96034 12 5.95279C13.0166 5.95279 14.0479 6.09632 15.0055 6.36827C17.2965 4.77432 18.3057 5.1067 18.3057 5.1067C18.9613 6.79887 18.5488 8.05288 18.4236 8.36261C19.1897 9.2238 19.6538 10.3192 19.6538 11.6638C19.6538 16.3928 16.8471 17.4278 14.1731 17.7375C14.6004 18.1152 14.9908 18.8706 14.9908 20.0189C14.9908 21.6657 14.9761 22.9877 14.9761 23.3957C14.9761 23.728 15.1897 24.1058 15.8011 23.9849C20.5672 22.3532 24 17.745 24 12.3135C24 5.50708 18.6298 0 12 0Z">
                    </path>
                  </svg>
                  <!-- </AlgoraWeb.Components.Logos.github> -->
                  <span class="line-clamp-1">itsparser</span>
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
            </div>
          </div>
        </div>

        <div class="flex xl:flex-col gap-2 xl:basis-[14.2857143%] xl:ml-auto">
          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-blue-400/50 hover:bg-blue-800/10 hover:text-blue-300 hover:drop-shadow-[0_1px_5px_#60a5fa80] focus:border-blue-400/50 focus:bg-blue-800/10 focus:text-blue-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#60a5fa80] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="bounty"
            phx-value-user_id="cm4v33kc50000kz03dymiv698"
          >
            <span class="tabler-diamond size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Bounty

          </button>

          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-emerald-400/50 hover:bg-emerald-800/10 hover:text-emerald-300 hover:drop-shadow-[0_1px_5px_#34d39980] focus:border-emerald-400/50 focus:bg-emerald-800/10 focus:text-emerald-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#34d39980] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="contract"
            phx-value-user_id="cm4v33kc50000kz03dymiv698"
          >
            <span class="tabler-contract size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Contract

          </button>
        </div>

        <div class="pt-2 xl:pt-0 xl:pl-8 xl:basis-[57.1428571%] xl:border-l xl:border-border">
          <div class="text-sm sm:text-base text-foreground font-medium">
            Completed
            <span class="font-semibold font-display">
              1
              bounty
            </span>
            <span class="font-semibold font-display">
              in 1 project
            </span>
            <span class="font-semibold font-display">
              ($10,000)
            </span>
          </div>
          <div class="pt-4 flex flex-col sm:flex-row sm:flex-wrap 2xl:flex-nowrap gap-4 xl:gap-8">
            <a
              href="http://localhost:4000/org/golemcloud"
              data-phx-link="redirect"
              data-phx-link-state="push"
              class="flex flex-1 items-center gap-2 sm:gap-4 text-sm rounded-lg"
            >
              <div class="relative rounded-lg shrink-0 overflow-hidden bg-gradient-to-br brightness-75 saturate-0 w-10 h-10">
                <img
                  id="avatar-image-GDQe_sWtsHiwbk8B"
                  src="https://avatars.githubusercontent.com/u/133607167?s=200&amp;v=4"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Golem Cloud"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  GO
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
              <div class="flex flex-col">
                <div class="text-base font-medium text-muted-foreground">
                  Golem Cloud
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <span class="tabler-star-filled size-4 text-amber-400 mr-1"></span>
                    <!-- </AlgoraWeb.CoreComponents.icon> -->738
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-emerald-400 font-display font-semibold">
                      $10,000
                    </span>
                    awarded
                  </div>
                </div>
              </div>
            </a>
            <!-- </Phoenix.Component.link> -->

          </div>
        </div>
      </div>
      <!-- </AlgoraWeb.Org.DashboardLive.match_card> -->

      <div class="relative flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4 sm:gap-8 border bg-card rounded-xl text-card-foreground shadow p-6">
        <div class="xl:basis-[28.5714286%]">
          <div class="flex items-center gap-4">
            <a
              href="http://localhost:4000/@/mehulmathur16"
              data-phx-link="redirect"
              data-phx-link-state="push"
            >
              <div class="relative rounded-full shrink-0 overflow-hidden w-16 h-16">
                <img
                  id="avatar-image-GDQe_sWvsIuwbk9B"
                  src="https://avatars.githubusercontent.com/u/64700961?v=4"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Mehul Mathur"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  ME
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
            </a>
            <!-- </Phoenix.Component.link> -->

            <div>
              <div class="flex items-center gap-4 text-foreground">
                <a
                  href="http://localhost:4000/@/mehulmathur16"
                  data-phx-link="redirect"
                  data-phx-link-state="push"
                  class="text-lg sm:text-xl font-semibold hover:underline truncate"
                >
                  Mehul Mathur 🇮🇳
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
              <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground sm:text-sm">
                <a
                  href="https://github.com/mehulmathur16"
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <svg
                    class="shrink-0 h-4 w-4"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path d="M12 0C5.37017 0 0 5.50708 0 12.306C0 17.745 3.44015 22.3532 8.20626 23.9849C8.80295 24.0982 9.02394 23.7205 9.02394 23.3881C9.02394 23.0935 9.01657 22.3229 9.00921 21.2956C5.67219 22.0359 4.96501 19.6487 4.96501 19.6487C4.41989 18.2285 3.63168 17.8508 3.63168 17.8508C2.54144 17.0878 3.71271 17.1029 3.71271 17.1029C4.91344 17.1936 5.55433 18.372 5.55433 18.372C6.62247 20.2531 8.36096 19.7092 9.04604 19.3919C9.15654 18.5987 9.46593 18.0548 9.80479 17.745C7.13812 17.4353 4.33886 16.3777 4.33886 11.6638C4.33886 10.3192 4.80295 9.2238 5.57643 8.36261C5.4512 8.05288 5.03867 6.79887 5.69429 5.1067C5.69429 5.1067 6.7035 4.77432 8.99447 6.36827C9.95212 6.09632 10.9761 5.96034 12 5.95279C13.0166 5.95279 14.0479 6.09632 15.0055 6.36827C17.2965 4.77432 18.3057 5.1067 18.3057 5.1067C18.9613 6.79887 18.5488 8.05288 18.4236 8.36261C19.1897 9.2238 19.6538 10.3192 19.6538 11.6638C19.6538 16.3928 16.8471 17.4278 14.1731 17.7375C14.6004 18.1152 14.9908 18.8706 14.9908 20.0189C14.9908 21.6657 14.9761 22.9877 14.9761 23.3957C14.9761 23.728 15.1897 24.1058 15.8011 23.9849C20.5672 22.3532 24 17.745 24 12.3135C24 5.50708 18.6298 0 12 0Z">
                    </path>
                  </svg>
                  <!-- </AlgoraWeb.Components.Logos.github> -->
                  <span class="line-clamp-1">mehulmathur16</span>
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
            </div>
          </div>
        </div>

        <div class="flex xl:flex-col gap-2 xl:basis-[14.2857143%] xl:ml-auto">
          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-blue-400/50 hover:bg-blue-800/10 hover:text-blue-300 hover:drop-shadow-[0_1px_5px_#60a5fa80] focus:border-blue-400/50 focus:bg-blue-800/10 focus:text-blue-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#60a5fa80] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="bounty"
            phx-value-user_id="clrlrbv720000l90f8qzmtqc9"
          >
            <span class="tabler-diamond size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Bounty

          </button>

          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-emerald-400/50 hover:bg-emerald-800/10 hover:text-emerald-300 hover:drop-shadow-[0_1px_5px_#34d39980] focus:border-emerald-400/50 focus:bg-emerald-800/10 focus:text-emerald-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#34d39980] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="contract"
            phx-value-user_id="clrlrbv720000l90f8qzmtqc9"
          >
            <span class="tabler-contract size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Contract

          </button>
        </div>

        <div class="pt-2 xl:pt-0 xl:pl-8 xl:basis-[57.1428571%] xl:border-l xl:border-border">
          <div class="text-sm sm:text-base text-foreground font-medium">
            Completed
            <span class="font-semibold font-display">
              37
              bounties
            </span>
            <span class="font-semibold font-display">
              across 7 projects
            </span>
            <span class="font-semibold font-display">
              ($3,050)
            </span>
          </div>
          <div class="pt-4 flex flex-col sm:flex-row sm:flex-wrap 2xl:flex-nowrap gap-4 xl:gap-8">
            <a
              href="http://localhost:4000/org/tailcallhq"
              data-phx-link="redirect"
              data-phx-link-state="push"
              class="flex flex-1 items-center gap-2 sm:gap-4 text-sm rounded-lg"
            >
              <div class="relative rounded-lg shrink-0 overflow-hidden bg-gradient-to-br brightness-75 saturate-0 w-10 h-10">
                <img
                  id="avatar-image-GDQe_sW3Njqwbk-B"
                  src="https://app.algora.io/asset/storage/v1/object/public/images/org/cli0b0kdt0000mh0fngt4r4bk-1741007407053"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Tailcall Inc."
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  TA
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
              <div class="flex flex-col">
                <div class="text-base font-medium text-muted-foreground">
                  Tailcall Inc.
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <span class="tabler-star-filled size-4 text-amber-400 mr-1"></span>
                    <!-- </AlgoraWeb.CoreComponents.icon> -->1.4K
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-emerald-400 font-display font-semibold">
                      $1,760
                    </span>
                    awarded
                  </div>
                </div>
              </div>
            </a>
            <!-- </Phoenix.Component.link> -->

            <a
              href="http://localhost:4000/org/spaceandtimelabs"
              data-phx-link="redirect"
              data-phx-link-state="push"
              class="flex flex-1 items-center gap-2 sm:gap-4 text-sm rounded-lg"
            >
              <div class="relative rounded-lg shrink-0 overflow-hidden bg-gradient-to-br brightness-75 saturate-0 w-10 h-10">
                <img
                  id="avatar-image-GDQe_sW5Jq2wbk_B"
                  src="https://avatars.githubusercontent.com/u/101605166?v=4"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Space and Time"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  SP
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
              <div class="flex flex-col">
                <div class="text-base font-medium text-muted-foreground">
                  Space and Time
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <span class="tabler-star-filled size-4 text-amber-400 mr-1"></span>
                    <!-- </AlgoraWeb.CoreComponents.icon> -->5.6K
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-emerald-400 font-display font-semibold">
                      $600
                    </span>
                    awarded
                  </div>
                </div>
              </div>
            </a>
            <!-- </Phoenix.Component.link> -->

          </div>
        </div>
      </div>
      <!-- </AlgoraWeb.Org.DashboardLive.match_card> -->

      <div class="relative flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4 sm:gap-8 border bg-card rounded-xl text-card-foreground shadow p-6">
        <div class="xl:basis-[28.5714286%]">
          <div class="flex items-center gap-4">
            <a
              href="http://localhost:4000/@/adamgfraser"
              data-phx-link="redirect"
              data-phx-link-state="push"
            >
              <div class="relative rounded-full shrink-0 overflow-hidden w-16 h-16">
                <img
                  id="avatar-image-GDQe_sW64n2wblAB"
                  src="https://avatars.githubusercontent.com/u/20825463?v=4"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Adam Fraser"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  AD
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
            </a>
            <!-- </Phoenix.Component.link> -->

            <div>
              <div class="flex items-center gap-4 text-foreground">
                <a
                  href="http://localhost:4000/@/adamgfraser"
                  data-phx-link="redirect"
                  data-phx-link-state="push"
                  class="text-lg sm:text-xl font-semibold hover:underline truncate"
                >
                  Adam Fraser 🇺🇸
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
              <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground sm:text-sm">
                <a
                  href="https://github.com/adamgfraser"
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <svg
                    class="shrink-0 h-4 w-4"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path d="M12 0C5.37017 0 0 5.50708 0 12.306C0 17.745 3.44015 22.3532 8.20626 23.9849C8.80295 24.0982 9.02394 23.7205 9.02394 23.3881C9.02394 23.0935 9.01657 22.3229 9.00921 21.2956C5.67219 22.0359 4.96501 19.6487 4.96501 19.6487C4.41989 18.2285 3.63168 17.8508 3.63168 17.8508C2.54144 17.0878 3.71271 17.1029 3.71271 17.1029C4.91344 17.1936 5.55433 18.372 5.55433 18.372C6.62247 20.2531 8.36096 19.7092 9.04604 19.3919C9.15654 18.5987 9.46593 18.0548 9.80479 17.745C7.13812 17.4353 4.33886 16.3777 4.33886 11.6638C4.33886 10.3192 4.80295 9.2238 5.57643 8.36261C5.4512 8.05288 5.03867 6.79887 5.69429 5.1067C5.69429 5.1067 6.7035 4.77432 8.99447 6.36827C9.95212 6.09632 10.9761 5.96034 12 5.95279C13.0166 5.95279 14.0479 6.09632 15.0055 6.36827C17.2965 4.77432 18.3057 5.1067 18.3057 5.1067C18.9613 6.79887 18.5488 8.05288 18.4236 8.36261C19.1897 9.2238 19.6538 10.3192 19.6538 11.6638C19.6538 16.3928 16.8471 17.4278 14.1731 17.7375C14.6004 18.1152 14.9908 18.8706 14.9908 20.0189C14.9908 21.6657 14.9761 22.9877 14.9761 23.3957C14.9761 23.728 15.1897 24.1058 15.8011 23.9849C20.5672 22.3532 24 17.745 24 12.3135C24 5.50708 18.6298 0 12 0Z">
                    </path>
                  </svg>
                  <!-- </AlgoraWeb.Components.Logos.github> -->
                  <span class="line-clamp-1">adamgfraser</span>
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
            </div>
          </div>
        </div>

        <div class="flex xl:flex-col gap-2 xl:basis-[14.2857143%] xl:ml-auto">
          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-blue-400/50 hover:bg-blue-800/10 hover:text-blue-300 hover:drop-shadow-[0_1px_5px_#60a5fa80] focus:border-blue-400/50 focus:bg-blue-800/10 focus:text-blue-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#60a5fa80] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="bounty"
            phx-value-user_id="clgxc4nos0000jt0fygp77a9x"
          >
            <span class="tabler-diamond size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Bounty

          </button>

          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-emerald-400/50 hover:bg-emerald-800/10 hover:text-emerald-300 hover:drop-shadow-[0_1px_5px_#34d39980] focus:border-emerald-400/50 focus:bg-emerald-800/10 focus:text-emerald-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#34d39980] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="contract"
            phx-value-user_id="clgxc4nos0000jt0fygp77a9x"
          >
            <span class="tabler-contract size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Contract

          </button>
        </div>

        <div class="pt-2 xl:pt-0 xl:pl-8 xl:basis-[57.1428571%] xl:border-l xl:border-border">
          <div class="text-sm sm:text-base text-foreground font-medium">
            Completed
            <span class="font-semibold font-display">
              17
              bounties
            </span>
            <span class="font-semibold font-display">
              across 2 projects
            </span>
            <span class="font-semibold font-display">
              ($5,300)
            </span>
          </div>
          <div class="pt-4 flex flex-col sm:flex-row sm:flex-wrap 2xl:flex-nowrap gap-4 xl:gap-8">
            <a
              href="http://localhost:4000/org/ZIO"
              data-phx-link="redirect"
              data-phx-link-state="push"
              class="flex flex-1 items-center gap-2 sm:gap-4 text-sm rounded-lg"
            >
              <div class="relative rounded-lg shrink-0 overflow-hidden bg-gradient-to-br brightness-75 saturate-0 w-10 h-10">
                <img
                  id="avatar-image-GDQe_sXCYxSwblBB"
                  src="https://app.algora.io/asset/storage/v1/object/public/images/org/ZIO-logo.png"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="ZIO"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  ZI
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
              <div class="flex flex-col">
                <div class="text-base font-medium text-muted-foreground">
                  ZIO
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <span class="tabler-star-filled size-4 text-amber-400 mr-1"></span>
                    <!-- </AlgoraWeb.CoreComponents.icon> -->4.2K
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-emerald-400 font-display font-semibold">
                      $4,975
                    </span>
                    awarded
                  </div>
                </div>
              </div>
            </a>
            <!-- </Phoenix.Component.link> -->

            <a
              href="https://github.com/zio-archive"
              data-phx-link="redirect"
              data-phx-link-state="push"
              class="flex flex-1 items-center gap-2 sm:gap-4 text-sm rounded-lg"
            >
              <div class="relative rounded-lg shrink-0 overflow-hidden bg-gradient-to-br brightness-75 saturate-0 w-10 h-10">
                <img
                  id="avatar-image-GDQe_sXD9V2wblCB"
                  src="https://avatars.githubusercontent.com/u/194811391?v=4"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="zio-archive"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  ZI
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
              <div class="flex flex-col">
                <div class="text-base font-medium text-muted-foreground">
                  zio-archive
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <span class="tabler-star-filled size-4 text-amber-400 mr-1"></span>
                    <!-- </AlgoraWeb.CoreComponents.icon> -->0
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-emerald-400 font-display font-semibold">
                      $325
                    </span>
                    awarded
                  </div>
                </div>
              </div>
            </a>
            <!-- </Phoenix.Component.link> -->

          </div>
        </div>
      </div>
      <!-- </AlgoraWeb.Org.DashboardLive.match_card> -->

      <div class="relative flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4 sm:gap-8 border bg-card rounded-xl text-card-foreground shadow p-6">
        <div class="xl:basis-[28.5714286%]">
          <div class="flex items-center gap-4">
            <a
              href="http://localhost:4000/@/gerred"
              data-phx-link="redirect"
              data-phx-link-state="push"
            >
              <div class="relative rounded-full shrink-0 overflow-hidden w-16 h-16">
                <img
                  id="avatar-image-GDQe_sXF6g6wblDB"
                  src="https://algora-console.fly.storage.tigris.dev/avatars/gerred.png"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Gerred Dillon"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  GE
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
            </a>
            <!-- </Phoenix.Component.link> -->

            <div>
              <div class="flex items-center gap-4 text-foreground">
                <a
                  href="http://localhost:4000/@/gerred"
                  data-phx-link="redirect"
                  data-phx-link-state="push"
                  class="text-lg sm:text-xl font-semibold hover:underline truncate"
                >
                  Gerred Dillon 🇺🇸
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
              <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground sm:text-sm">
                <a
                  href="https://github.com/gerred"
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <svg
                    class="shrink-0 h-4 w-4"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path d="M12 0C5.37017 0 0 5.50708 0 12.306C0 17.745 3.44015 22.3532 8.20626 23.9849C8.80295 24.0982 9.02394 23.7205 9.02394 23.3881C9.02394 23.0935 9.01657 22.3229 9.00921 21.2956C5.67219 22.0359 4.96501 19.6487 4.96501 19.6487C4.41989 18.2285 3.63168 17.8508 3.63168 17.8508C2.54144 17.0878 3.71271 17.1029 3.71271 17.1029C4.91344 17.1936 5.55433 18.372 5.55433 18.372C6.62247 20.2531 8.36096 19.7092 9.04604 19.3919C9.15654 18.5987 9.46593 18.0548 9.80479 17.745C7.13812 17.4353 4.33886 16.3777 4.33886 11.6638C4.33886 10.3192 4.80295 9.2238 5.57643 8.36261C5.4512 8.05288 5.03867 6.79887 5.69429 5.1067C5.69429 5.1067 6.7035 4.77432 8.99447 6.36827C9.95212 6.09632 10.9761 5.96034 12 5.95279C13.0166 5.95279 14.0479 6.09632 15.0055 6.36827C17.2965 4.77432 18.3057 5.1067 18.3057 5.1067C18.9613 6.79887 18.5488 8.05288 18.4236 8.36261C19.1897 9.2238 19.6538 10.3192 19.6538 11.6638C19.6538 16.3928 16.8471 17.4278 14.1731 17.7375C14.6004 18.1152 14.9908 18.8706 14.9908 20.0189C14.9908 21.6657 14.9761 22.9877 14.9761 23.3957C14.9761 23.728 15.1897 24.1058 15.8011 23.9849C20.5672 22.3532 24 17.745 24 12.3135C24 5.50708 18.6298 0 12 0Z">
                    </path>
                  </svg>
                  <!-- </AlgoraWeb.Components.Logos.github> -->
                  <span class="line-clamp-1">gerred</span>
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
            </div>
          </div>
        </div>

        <div class="flex xl:flex-col gap-2 xl:basis-[14.2857143%] xl:ml-auto">
          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-blue-400/50 hover:bg-blue-800/10 hover:text-blue-300 hover:drop-shadow-[0_1px_5px_#60a5fa80] focus:border-blue-400/50 focus:bg-blue-800/10 focus:text-blue-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#60a5fa80] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="bounty"
            phx-value-user_id="cm5fkrufe0000mw03aryl2im0"
          >
            <span class="tabler-diamond size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Bounty

          </button>

          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-emerald-400/50 hover:bg-emerald-800/10 hover:text-emerald-300 hover:drop-shadow-[0_1px_5px_#34d39980] focus:border-emerald-400/50 focus:bg-emerald-800/10 focus:text-emerald-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#34d39980] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="contract"
            phx-value-user_id="cm5fkrufe0000mw03aryl2im0"
          >
            <span class="tabler-contract size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Contract

          </button>
        </div>

        <div class="pt-2 xl:pt-0 xl:pl-8 xl:basis-[57.1428571%] xl:border-l xl:border-border">
          <div class="text-sm sm:text-base text-foreground font-medium">
            Completed
            <span class="font-semibold font-display">
              1
              bounty
            </span>
            <span class="font-semibold font-display">
              in 1 project
            </span>
            <span class="font-semibold font-display">
              ($2,000)
            </span>
          </div>
          <div class="pt-4 flex flex-col sm:flex-row sm:flex-wrap 2xl:flex-nowrap gap-4 xl:gap-8">
            <a
              href="http://localhost:4000/org/trieve"
              data-phx-link="redirect"
              data-phx-link-state="push"
              class="flex flex-1 items-center gap-2 sm:gap-4 text-sm rounded-lg"
            >
              <div class="relative rounded-lg shrink-0 overflow-hidden bg-gradient-to-br brightness-75 saturate-0 w-10 h-10">
                <img
                  id="avatar-image-GDQe_sXNpQOwblEB"
                  src="https://app.algora.io/asset/storage/v1/object/public/images/org/clmjr82fr0007mi0f3skac022-1720036458247"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Trieve (YC W24)"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  TR
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
              <div class="flex flex-col">
                <div class="text-base font-medium text-muted-foreground">
                  Trieve (YC W24)
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <span class="tabler-star-filled size-4 text-amber-400 mr-1"></span>
                    <!-- </AlgoraWeb.CoreComponents.icon> -->2.0K
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-emerald-400 font-display font-semibold">
                      $2,000
                    </span>
                    awarded
                  </div>
                </div>
              </div>
            </a>
            <!-- </Phoenix.Component.link> -->

          </div>
        </div>
      </div>
      <!-- </AlgoraWeb.Org.DashboardLive.match_card> -->

      <div class="relative flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4 sm:gap-8 border bg-card rounded-xl text-card-foreground shadow p-6">
        <div class="xl:basis-[28.5714286%]">
          <div class="flex items-center gap-4">
            <a
              href="http://localhost:4000/@/JoshAntBrown"
              data-phx-link="redirect"
              data-phx-link-state="push"
            >
              <div class="relative rounded-full shrink-0 overflow-hidden w-16 h-16">
                <img
                  id="avatar-image-GDQe_sXPvo6wblFB"
                  src="https://avatars.githubusercontent.com/u/1793797?v=4"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Josh Brown"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  JO
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
            </a>
            <!-- </Phoenix.Component.link> -->

            <div>
              <div class="flex items-center gap-4 text-foreground">
                <a
                  href="http://localhost:4000/@/JoshAntBrown"
                  data-phx-link="redirect"
                  data-phx-link-state="push"
                  class="text-lg sm:text-xl font-semibold hover:underline truncate"
                >
                  Josh Brown 🇬🇧
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
              <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground sm:text-sm">
                <a
                  href="https://github.com/JoshAntBrown"
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <svg
                    class="shrink-0 h-4 w-4"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path d="M12 0C5.37017 0 0 5.50708 0 12.306C0 17.745 3.44015 22.3532 8.20626 23.9849C8.80295 24.0982 9.02394 23.7205 9.02394 23.3881C9.02394 23.0935 9.01657 22.3229 9.00921 21.2956C5.67219 22.0359 4.96501 19.6487 4.96501 19.6487C4.41989 18.2285 3.63168 17.8508 3.63168 17.8508C2.54144 17.0878 3.71271 17.1029 3.71271 17.1029C4.91344 17.1936 5.55433 18.372 5.55433 18.372C6.62247 20.2531 8.36096 19.7092 9.04604 19.3919C9.15654 18.5987 9.46593 18.0548 9.80479 17.745C7.13812 17.4353 4.33886 16.3777 4.33886 11.6638C4.33886 10.3192 4.80295 9.2238 5.57643 8.36261C5.4512 8.05288 5.03867 6.79887 5.69429 5.1067C5.69429 5.1067 6.7035 4.77432 8.99447 6.36827C9.95212 6.09632 10.9761 5.96034 12 5.95279C13.0166 5.95279 14.0479 6.09632 15.0055 6.36827C17.2965 4.77432 18.3057 5.1067 18.3057 5.1067C18.9613 6.79887 18.5488 8.05288 18.4236 8.36261C19.1897 9.2238 19.6538 10.3192 19.6538 11.6638C19.6538 16.3928 16.8471 17.4278 14.1731 17.7375C14.6004 18.1152 14.9908 18.8706 14.9908 20.0189C14.9908 21.6657 14.9761 22.9877 14.9761 23.3957C14.9761 23.728 15.1897 24.1058 15.8011 23.9849C20.5672 22.3532 24 17.745 24 12.3135C24 5.50708 18.6298 0 12 0Z">
                    </path>
                  </svg>
                  <!-- </AlgoraWeb.Components.Logos.github> -->
                  <span class="line-clamp-1">JoshAntBrown</span>
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
            </div>
          </div>
        </div>

        <div class="flex xl:flex-col gap-2 xl:basis-[14.2857143%] xl:ml-auto">
          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-blue-400/50 hover:bg-blue-800/10 hover:text-blue-300 hover:drop-shadow-[0_1px_5px_#60a5fa80] focus:border-blue-400/50 focus:bg-blue-800/10 focus:text-blue-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#60a5fa80] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="bounty"
            phx-value-user_id="clsdprvym000al70f76whovr4"
          >
            <span class="tabler-diamond size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Bounty

          </button>

          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-emerald-400/50 hover:bg-emerald-800/10 hover:text-emerald-300 hover:drop-shadow-[0_1px_5px_#34d39980] focus:border-emerald-400/50 focus:bg-emerald-800/10 focus:text-emerald-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#34d39980] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="contract"
            phx-value-user_id="clsdprvym000al70f76whovr4"
          >
            <span class="tabler-contract size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Contract

          </button>
        </div>

        <div class="pt-2 xl:pt-0 xl:pl-8 xl:basis-[57.1428571%] xl:border-l xl:border-border">
          <div class="text-sm sm:text-base text-foreground font-medium">
            Completed
            <span class="font-semibold font-display">
              16
              bounties
            </span>
            <span class="font-semibold font-display">
              in 1 project
            </span>
            <span class="font-semibold font-display">
              ($2,575)
            </span>
          </div>
          <div class="pt-4 flex flex-col sm:flex-row sm:flex-wrap 2xl:flex-nowrap gap-4 xl:gap-8">
            <a
              href="http://localhost:4000/org/maybe-finance"
              data-phx-link="redirect"
              data-phx-link-state="push"
              class="flex flex-1 items-center gap-2 sm:gap-4 text-sm rounded-lg"
            >
              <div class="relative rounded-lg shrink-0 overflow-hidden bg-gradient-to-br brightness-75 saturate-0 w-10 h-10">
                <img
                  id="avatar-image-GDQe_sXXNMmwblGB"
                  src="https://app.algora.io/asset/storage/v1/object/public/images/org/clr89x8os000ejs0f00fmkc76-1704921066094"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Maybe"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  MA
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
              <div class="flex flex-col">
                <div class="text-base font-medium text-muted-foreground">
                  Maybe
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <span class="tabler-star-filled size-4 text-amber-400 mr-1"></span>
                    <!-- </AlgoraWeb.CoreComponents.icon> -->42.6K
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-emerald-400 font-display font-semibold">
                      $2,575
                    </span>
                    awarded
                  </div>
                </div>
              </div>
            </a>
            <!-- </Phoenix.Component.link> -->

          </div>
        </div>
      </div>
      <!-- </AlgoraWeb.Org.DashboardLive.match_card> -->

      <div class="relative flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4 sm:gap-8 border bg-card rounded-xl text-card-foreground shadow p-6">
        <div class="xl:basis-[28.5714286%]">
          <div class="flex items-center gap-4">
            <a
              href="http://localhost:4000/@/rjackson"
              data-phx-link="redirect"
              data-phx-link-state="push"
            >
              <div class="relative rounded-full shrink-0 overflow-hidden w-16 h-16">
                <img
                  id="avatar-image-GDQe_sXZMEuwblHB"
                  src="https://avatars.githubusercontent.com/u/602850?v=4"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Rob Jackson"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  RO
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
            </a>
            <!-- </Phoenix.Component.link> -->

            <div>
              <div class="flex items-center gap-4 text-foreground">
                <a
                  href="http://localhost:4000/@/rjackson"
                  data-phx-link="redirect"
                  data-phx-link-state="push"
                  class="text-lg sm:text-xl font-semibold hover:underline truncate"
                >
                  Rob Jackson 🇬🇧
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
              <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground sm:text-sm">
                <a
                  href="https://github.com/rjackson"
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <svg
                    class="shrink-0 h-4 w-4"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path d="M12 0C5.37017 0 0 5.50708 0 12.306C0 17.745 3.44015 22.3532 8.20626 23.9849C8.80295 24.0982 9.02394 23.7205 9.02394 23.3881C9.02394 23.0935 9.01657 22.3229 9.00921 21.2956C5.67219 22.0359 4.96501 19.6487 4.96501 19.6487C4.41989 18.2285 3.63168 17.8508 3.63168 17.8508C2.54144 17.0878 3.71271 17.1029 3.71271 17.1029C4.91344 17.1936 5.55433 18.372 5.55433 18.372C6.62247 20.2531 8.36096 19.7092 9.04604 19.3919C9.15654 18.5987 9.46593 18.0548 9.80479 17.745C7.13812 17.4353 4.33886 16.3777 4.33886 11.6638C4.33886 10.3192 4.80295 9.2238 5.57643 8.36261C5.4512 8.05288 5.03867 6.79887 5.69429 5.1067C5.69429 5.1067 6.7035 4.77432 8.99447 6.36827C9.95212 6.09632 10.9761 5.96034 12 5.95279C13.0166 5.95279 14.0479 6.09632 15.0055 6.36827C17.2965 4.77432 18.3057 5.1067 18.3057 5.1067C18.9613 6.79887 18.5488 8.05288 18.4236 8.36261C19.1897 9.2238 19.6538 10.3192 19.6538 11.6638C19.6538 16.3928 16.8471 17.4278 14.1731 17.7375C14.6004 18.1152 14.9908 18.8706 14.9908 20.0189C14.9908 21.6657 14.9761 22.9877 14.9761 23.3957C14.9761 23.728 15.1897 24.1058 15.8011 23.9849C20.5672 22.3532 24 17.745 24 12.3135C24 5.50708 18.6298 0 12 0Z">
                    </path>
                  </svg>
                  <!-- </AlgoraWeb.Components.Logos.github> -->
                  <span class="line-clamp-1">rjackson</span>
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
            </div>
          </div>
        </div>

        <div class="flex xl:flex-col gap-2 xl:basis-[14.2857143%] xl:ml-auto">
          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-blue-400/50 hover:bg-blue-800/10 hover:text-blue-300 hover:drop-shadow-[0_1px_5px_#60a5fa80] focus:border-blue-400/50 focus:bg-blue-800/10 focus:text-blue-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#60a5fa80] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="bounty"
            phx-value-user_id="clgtz4g9m000aml0fpofbqegp"
          >
            <span class="tabler-diamond size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Bounty

          </button>

          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-emerald-400/50 hover:bg-emerald-800/10 hover:text-emerald-300 hover:drop-shadow-[0_1px_5px_#34d39980] focus:border-emerald-400/50 focus:bg-emerald-800/10 focus:text-emerald-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#34d39980] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="contract"
            phx-value-user_id="clgtz4g9m000aml0fpofbqegp"
          >
            <span class="tabler-contract size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Contract

          </button>
        </div>

        <div class="pt-2 xl:pt-0 xl:pl-8 xl:basis-[57.1428571%] xl:border-l xl:border-border">
          <div class="text-sm sm:text-base text-foreground font-medium">
            Completed
            <span class="font-semibold font-display">
              25
              bounties
            </span>
            <span class="font-semibold font-display">
              across 5 projects
            </span>
            <span class="font-semibold font-display">
              ($1,649)
            </span>
          </div>
          <div class="pt-4 flex flex-col sm:flex-row sm:flex-wrap 2xl:flex-nowrap gap-4 xl:gap-8">
            <a
              href="http://localhost:4000/org/cal"
              data-phx-link="redirect"
              data-phx-link-state="push"
              class="flex flex-1 items-center gap-2 sm:gap-4 text-sm rounded-lg"
            >
              <div class="relative rounded-lg shrink-0 overflow-hidden bg-gradient-to-br brightness-75 saturate-0 w-10 h-10">
                <img
                  id="avatar-image-GDQe_sXgjbqwblIB"
                  src="https://avatars.githubusercontent.com/u/79145102?s=200&amp;v=4"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Cal.com, Inc."
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  CA
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
              <div class="flex flex-col">
                <div class="text-base font-medium text-muted-foreground">
                  Cal.com, Inc.
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <span class="tabler-star-filled size-4 text-amber-400 mr-1"></span>
                    <!-- </AlgoraWeb.CoreComponents.icon> -->35.4K
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-emerald-400 font-display font-semibold">
                      $704
                    </span>
                    awarded
                  </div>
                </div>
              </div>
            </a>
            <!-- </Phoenix.Component.link> -->

            <a
              href="http://localhost:4000/org/remotion"
              data-phx-link="redirect"
              data-phx-link-state="push"
              class="flex flex-1 items-center gap-2 sm:gap-4 text-sm rounded-lg"
            >
              <div class="relative rounded-lg shrink-0 overflow-hidden bg-gradient-to-br brightness-75 saturate-0 w-10 h-10">
                <img
                  id="avatar-image-GDQe_sXia4mwblJB"
                  src="https://app.algora.io/asset/storage/v1/object/public/images/org/remotion.png?t=2023-04-02T14%3A56%3A20.474Z"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Remotion"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  RE
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
              <div class="flex flex-col">
                <div class="text-base font-medium text-muted-foreground">
                  Remotion
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <span class="tabler-star-filled size-4 text-amber-400 mr-1"></span>
                    <!-- </AlgoraWeb.CoreComponents.icon> -->21.8K
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-emerald-400 font-display font-semibold">
                      $435
                    </span>
                    awarded
                  </div>
                </div>
              </div>
            </a>
            <!-- </Phoenix.Component.link> -->

          </div>
        </div>
      </div>
      <!-- </AlgoraWeb.Org.DashboardLive.match_card> -->

      <div class="relative flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4 sm:gap-8 border bg-card rounded-xl text-card-foreground shadow p-6">
        <div class="xl:basis-[28.5714286%]">
          <div class="flex items-center gap-4">
            <a
              href="http://localhost:4000/@/Myestery"
              data-phx-link="redirect"
              data-phx-link-state="push"
            >
              <div class="relative rounded-full shrink-0 overflow-hidden w-16 h-16">
                <img
                  id="avatar-image-GDQe_sXkGqqwblKB"
                  src="https://avatars.githubusercontent.com/u/49923152?v=4"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Johnpaul Chiwetelu"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  JO
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
            </a>
            <!-- </Phoenix.Component.link> -->

            <div>
              <div class="flex items-center gap-4 text-foreground">
                <a
                  href="http://localhost:4000/@/Myestery"
                  data-phx-link="redirect"
                  data-phx-link-state="push"
                  class="text-lg sm:text-xl font-semibold hover:underline truncate"
                >
                  Johnpaul Chiwetelu 🇳🇬
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
              <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground sm:text-sm">
                <a
                  href="https://github.com/Myestery"
                  target="_blank"
                  class="flex items-center gap-1 hover:underline"
                >
                  <svg
                    class="shrink-0 h-4 w-4"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    xmlns="http://www.w3.org/2000/svg"
                  >
                    <path d="M12 0C5.37017 0 0 5.50708 0 12.306C0 17.745 3.44015 22.3532 8.20626 23.9849C8.80295 24.0982 9.02394 23.7205 9.02394 23.3881C9.02394 23.0935 9.01657 22.3229 9.00921 21.2956C5.67219 22.0359 4.96501 19.6487 4.96501 19.6487C4.41989 18.2285 3.63168 17.8508 3.63168 17.8508C2.54144 17.0878 3.71271 17.1029 3.71271 17.1029C4.91344 17.1936 5.55433 18.372 5.55433 18.372C6.62247 20.2531 8.36096 19.7092 9.04604 19.3919C9.15654 18.5987 9.46593 18.0548 9.80479 17.745C7.13812 17.4353 4.33886 16.3777 4.33886 11.6638C4.33886 10.3192 4.80295 9.2238 5.57643 8.36261C5.4512 8.05288 5.03867 6.79887 5.69429 5.1067C5.69429 5.1067 6.7035 4.77432 8.99447 6.36827C9.95212 6.09632 10.9761 5.96034 12 5.95279C13.0166 5.95279 14.0479 6.09632 15.0055 6.36827C17.2965 4.77432 18.3057 5.1067 18.3057 5.1067C18.9613 6.79887 18.5488 8.05288 18.4236 8.36261C19.1897 9.2238 19.6538 10.3192 19.6538 11.6638C19.6538 16.3928 16.8471 17.4278 14.1731 17.7375C14.6004 18.1152 14.9908 18.8706 14.9908 20.0189C14.9908 21.6657 14.9761 22.9877 14.9761 23.3957C14.9761 23.728 15.1897 24.1058 15.8011 23.9849C20.5672 22.3532 24 17.745 24 12.3135C24 5.50708 18.6298 0 12 0Z">
                    </path>
                  </svg>
                  <!-- </AlgoraWeb.Components.Logos.github> -->
                  <span class="line-clamp-1">Myestery</span>
                </a>
                <!-- </Phoenix.Component.link> -->

              </div>
            </div>
          </div>
        </div>

        <div class="flex xl:flex-col gap-2 xl:basis-[14.2857143%] xl:ml-auto">
          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-blue-400/50 hover:bg-blue-800/10 hover:text-blue-300 hover:drop-shadow-[0_1px_5px_#60a5fa80] focus:border-blue-400/50 focus:bg-blue-800/10 focus:text-blue-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#60a5fa80] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="bounty"
            phx-value-user_id="cly6lduqn000cl6097jiobynl"
          >
            <span class="tabler-diamond size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Bounty

          </button>

          <button
            class="inline-flex px-4 py-2 rounded-lg border-white/50 bg-card text-foreground transition-colors whitespace-nowrap items-center justify-center font-medium duration-75 text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 disabled:opacity-75 hover:border-emerald-400/50 hover:bg-emerald-800/10 hover:text-emerald-300 hover:drop-shadow-[0_1px_5px_#34d39980] focus:border-emerald-400/50 focus:bg-emerald-800/10 focus:text-emerald-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#34d39980] border group phx-submit-loading:opacity-75"
            phx-click="share_opportunity"
            phx-value-type="contract"
            phx-value-user_id="cly6lduqn000cl6097jiobynl"
          >
            <span class="tabler-contract size-4 text-current mr-2 -ml-1"></span>
            <!-- </AlgoraWeb.CoreComponents.icon> --> Contract

          </button>
        </div>

        <div class="pt-2 xl:pt-0 xl:pl-8 xl:basis-[57.1428571%] xl:border-l xl:border-border">
          <div class="text-sm sm:text-base text-foreground font-medium">
            Completed
            <span class="font-semibold font-display">
              3
              bounties
            </span>
            <span class="font-semibold font-display">
              across 3 projects
            </span>
            <span class="font-semibold font-display">
              ($1,500)
            </span>
          </div>
          <div class="pt-4 flex flex-col sm:flex-row sm:flex-wrap 2xl:flex-nowrap gap-4 xl:gap-8">
            <a
              href="http://localhost:4000/org/golemcloud"
              data-phx-link="redirect"
              data-phx-link-state="push"
              class="flex flex-1 items-center gap-2 sm:gap-4 text-sm rounded-lg"
            >
              <div class="relative rounded-lg shrink-0 overflow-hidden bg-gradient-to-br brightness-75 saturate-0 w-10 h-10">
                <img
                  id="avatar-image-GDQe_sXr9tmwblLB"
                  src="https://avatars.githubusercontent.com/u/133607167?s=200&amp;v=4"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Golem Cloud"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  GO
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
              <div class="flex flex-col">
                <div class="text-base font-medium text-muted-foreground">
                  Golem Cloud
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <span class="tabler-star-filled size-4 text-amber-400 mr-1"></span>
                    <!-- </AlgoraWeb.CoreComponents.icon> -->738
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-emerald-400 font-display font-semibold">
                      $1,000
                    </span>
                    awarded
                  </div>
                </div>
              </div>
            </a>
            <!-- </Phoenix.Component.link> -->

            <a
              href="http://localhost:4000/org/remotion"
              data-phx-link="redirect"
              data-phx-link-state="push"
              class="flex flex-1 items-center gap-2 sm:gap-4 text-sm rounded-lg"
            >
              <div class="relative rounded-lg shrink-0 overflow-hidden bg-gradient-to-br brightness-75 saturate-0 w-10 h-10">
                <img
                  id="avatar-image-GDQe_sXtibGwblMB"
                  src="https://app.algora.io/asset/storage/v1/object/public/images/org/remotion.png?t=2023-04-02T14%3A56%3A20.474Z"
                  class="bg-muted aspect-square w-full h-full"
                  phx-hook="AvatarImage"
                  alt="Remotion"
                />
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_image> -->
                <span class="flex rounded-lg bg-muted items-center justify-center w-full h-full">
                  RE
                </span>
                <!-- </AlgoraWeb.Components.UI.Avatar.avatar_fallback> -->

              </div>
              <!-- </AlgoraWeb.Components.UI.Avatar.avatar> -->
              <div class="flex flex-col">
                <div class="text-base font-medium text-muted-foreground">
                  Remotion
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <span class="tabler-star-filled size-4 text-amber-400 mr-1"></span>
                    <!-- </AlgoraWeb.CoreComponents.icon> -->21.8K
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-emerald-400 font-display font-semibold">
                      $250
                    </span>
                    awarded
                  </div>
                </div>
              </div>
            </a>
            <!-- </Phoenix.Component.link> -->

          </div>
        </div>
      </div>
      <!-- </AlgoraWeb.Org.DashboardLive.match_card> -->

    </div>
    """
  end
end
