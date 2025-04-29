defmodule AlgoraWeb.BountiesLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

  import AlgoraWeb.Components.Bounties
  import AlgoraWeb.Components.ModalVideo
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Bounties
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Workspace
  alias AlgoraWeb.Data.PlatformStats
  alias AlgoraWeb.Forms.BountyForm
  alias AlgoraWeb.Forms.ContractForm
  alias AlgoraWeb.Forms.RepoForm
  alias AlgoraWeb.Forms.TipForm

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
  def handle_params(%{"tech" => tech}, _uri, socket) when is_binary(tech) do
    selected_techs = tech |> String.split(",") |> Enum.reject(&(&1 == "")) |> Enum.map(&String.downcase/1)
    valid_techs = Enum.map(socket.assigns.techs, fn {tech, _} -> String.downcase(tech) end)
    # Only keep valid techs that exist in the available tech list
    selected_techs = Enum.filter(selected_techs, &(&1 in valid_techs))

    query_opts =
      if selected_techs == [] do
        Keyword.delete(socket.assigns.query_opts, :tech_stack)
      else
        Keyword.put(socket.assigns.query_opts, :tech_stack, selected_techs)
      end

    {:noreply,
     socket
     |> assign(:page_title, "#{Enum.map_join(selected_techs, "/", &String.capitalize/1)} Bounties")
     |> assign(:selected_techs, selected_techs)
     |> assign(:query_opts, query_opts)
     |> assign_bounties()}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Bounties")
     |> assign(:selected_techs, [])
     |> assign(:query_opts, Keyword.delete(socket.assigns.query_opts, :tech_stack))
     |> assign_bounties()}
  end

  @impl true
  def mount(%{"tech" => tech}, _session, socket) when is_binary(tech) do
    if connected?(socket) do
      Bounties.subscribe()
    end

    # Parse selected techs from URL params and ensure lowercase
    selected_techs =
      tech
      |> String.split(",")
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&String.downcase/1)

    query_opts =
      [
        status: :open,
        limit: page_size(),
        current_user: socket.assigns[:current_user]
      ] ++
        if socket.assigns[:current_user] do
          [amount_gt: Money.new(:USD, 100)]
        else
          [amount_gt: Money.new(:USD, 500)]
        end

    techs = Bounties.list_tech(query_opts)

    # Only keep valid techs that exist in the available tech list (case insensitive)
    valid_techs = Enum.map(techs, fn {tech, _} -> String.downcase(tech) end)
    selected_techs = Enum.filter(selected_techs, &(&1 in valid_techs))

    query_opts = if selected_techs == [], do: query_opts, else: Keyword.put(query_opts, :tech_stack, selected_techs)

    {:ok,
     socket
     |> assign(:techs, techs)
     |> assign(:selected_techs, selected_techs)
     |> assign(:query_opts, query_opts)
     |> assign_bounties()
     |> assign_misc()}
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Bounties.subscribe()
    end

    query_opts =
      [
        status: :open,
        limit: page_size(),
        current_user: socket.assigns[:current_user]
      ] ++
        if socket.assigns[:current_user] do
          [amount_gt: Money.new(:USD, 100)]
        else
          [amount_gt: Money.new(:USD, 500)]
        end

    techs = Bounties.list_tech(query_opts)

    {:ok,
     socket
     |> assign(:techs, techs)
     |> assign(:selected_techs, [])
     |> assign(:query_opts, query_opts)
     |> assign_bounties()
     |> assign_misc()}
  end

  def assign_misc(socket) do
    total_contributors = get_contributors_count()
    total_countries = get_countries_count()

    stats = [
      %{label: "Paid Out", value: format_money(get_total_paid_out())},
      %{label: "Completed Bounties", value: format_number(get_completed_bounties_count())},
      %{label: "Contributors", value: format_number(total_contributors)},
      %{label: "Countries", value: format_number(total_countries)}
    ]

    featured_collabs = list_featured_collabs()

    socket
    |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
    |> assign(:contract_form, to_form(ContractForm.changeset(%ContractForm{}, %{})))
    |> assign(:tip_form, to_form(TipForm.changeset(%TipForm{}, %{})))
    |> assign(:repo_form, to_form(RepoForm.changeset(%RepoForm{}, %{})))
    |> assign(:stats, stats)
    |> assign(:featured_collabs, featured_collabs)
    |> assign(:plans1, AlgoraWeb.PricingLive.get_plans1())
    |> assign(:total_contributors, total_contributors)
    |> assign(:total_countries, total_countries)
    |> assign(:selected_developer, nil)
    |> assign(:share_drawer_type, nil)
    |> assign(:show_share_drawer, false)
  end

  defp list_featured_collabs do
    developers =
      case Algora.Settings.get_featured_collabs() do
        handles when is_list(handles) and handles != [] ->
          developers = Accounts.list_developers(handles: handles)
          # Sort developers to match handles order
          Enum.sort_by(developers, fn dev ->
            Enum.find_index(handles, &(&1 == dev.provider_login))
          end)

        _ ->
          Accounts.list_developers(limit: 5)
      end

    Enum.map(developers, fn user -> %{user: user, projects: Accounts.list_contributed_projects(user, limit: 2)} end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-6 p-4 md:p-6 lg:px-8">
      <.section title="Bounties" subtitle="Open bounties for you">
        <div class="mb-4 flex sm:flex-wrap gap-2 whitespace-nowrap overflow-x-auto scrollbar-thin">
          <%= for {tech, count} <- @techs do %>
            <div phx-click="toggle_tech" phx-value-tech={tech} class="cursor-pointer">
              <.badge
                variant={if String.downcase(tech) in @selected_techs, do: "success", else: "default"}
                class={
                  if String.downcase(tech) in @selected_techs,
                    do: "hover:bg-success/5 transition-colors",
                    else: "hover:bg-accent/80 transition-colors"
                }
              >
                {tech} ({count})
              </.badge>
            </div>
          <% end %>
        </div>
        <%= if Enum.empty?(@bounties) do %>
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
          <div id="bounties-container" phx-hook="InfiniteScroll">
            <.bounties bounties={@bounties} />
            <div :if={@has_more_bounties} class="flex justify-center mt-4" data-load-more-indicator>
              <div class="animate-pulse text-muted-foreground">
                <.icon name="tabler-loader" class="h-6 w-6 animate-spin" />
              </div>
            </div>
          </div>
        <% end %>
      </.section>

      <section class="relative isolate">
        <div class="relative isolate -z-10 py-[35vw] sm:py-[25vw]">
          <div class="z-20 absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 transform">
            <div class="relative scale-[300%] sm:scale-[150%] opacity-75">
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
                <.icon
                  name="github"
                  class="size-5 sm:size-10 absolute left-2 sm:left-3 top-2 sm:top-3 text-muted-foreground/50"
                />
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
                      to: "ring-success"
                    )
                  }
                >
                  <.card
                    data-org-feature-card={feature.src}
                    class={
                      classes([
                        "ring-1 ring-transparent hover:ring-success transition-all rounded-xl",
                        if(index == 0, do: "ring-success")
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
            <div class="aspect-[1200/630] rounded-xl overflow-hidden w-full relative">
              <%= for {feature, index} <- org_features() |> Enum.with_index() do %>
                <img
                  data-org-feature-img={feature.src}
                  src={feature.src}
                  alt={feature.title}
                  loading="lazy"
                  class={
                    classes([
                      "w-full h-full object-contain absolute opacity-0 transition-all",
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
              <div class="mt-4 aspect-[1200/630] rounded-xl overflow-hidden w-full relative">
                <img
                  src={feature.src}
                  alt={feature.title}
                  loading="lazy"
                  class="w-full h-full object-contain"
                />
              </div>
            </div>
          <% end %>
        </div>
      </section>

      <section class="relative py-16 sm:py-40">
        <div class="mb-4 text-center text-3xl sm:text-6xl">🌎</div>
        <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-5xl text-center mb-2 sm:mb-4">
          Join {@total_contributors} contributors
          <span class="block sm:inline">from {@total_countries} countries</span>
        </h2>

        <p class="text-center font-medium text-base text-muted-foreground sm:text-xl mb-12 mx-auto">
        </p>

        <div class="max-w-7xl mx-auto px-6 lg:px-8">
          <.contributors featured_collabs={@featured_collabs} />
        </div>
      </section>

      <section class="relative py-16 sm:py-40">
        <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-5xl text-center mb-2 sm:mb-4">
          <span class="text-emerald-400">Get paid for open source</span>
          <span class="block sm:inline">and freelance work</span>
        </h2>
        <p class="text-center font-medium text-base text-muted-foreground sm:text-xl mb-12 mx-auto">
          Work on your own schedule, anywhere in the world
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
                      to: "ring-success"
                    )
                  }
                >
                  <.card
                    data-user-feature-card={feature.src}
                    class={
                      classes([
                        "ring-1 ring-transparent hover:ring-success transition-all rounded-xl",
                        if(index == 0, do: "ring-success")
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
            <div class="aspect-[1200/630] rounded-xl overflow-hidden w-full relative">
              <%= for {feature, index} <- user_features() |> Enum.with_index() do %>
                <img
                  data-user-feature-img={feature.src}
                  src={feature.src}
                  alt={feature.title}
                  loading="lazy"
                  class={
                    classes([
                      "w-full h-full object-cover absolute inset-0 opacity-0 transition-all",
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
              <div class="mt-4 aspect-[1200/630] rounded-xl overflow-hidden w-full relative">
                <img
                  src={feature.src}
                  alt={feature.title}
                  loading="lazy"
                  class="w-full h-full object-contain"
                />
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
            <div class="relative scale-[300%] sm:scale-[150%]">
              <div class="opacity-50 [transform:perspective(4101px)_rotateX(51deg)_rotateY(-13deg)_rotateZ(40deg)]">
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
          <div class="z-20 absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-center text-foreground font-bold font-display text-2xl md:text-3xl space-y-2 md:space-y-6">
            <div>github.com/your/repo</div>
            <div class="flex justify-center items-center gap-4 text-emerald-400">
              <.icon
                name="tabler-arrow-narrow-down animate-bounce"
                class="h-12 w-12 sm:h-8 sm:w-8 md:h-12 md:w-12 text-current"
              />
            </div>
            <div>algora.io/your/repo</div>
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
                <.icon
                  name="github"
                  class="size-5 sm:size-10 absolute left-2 sm:left-3 top-2 sm:top-3 text-muted-foreground/50"
                />
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
              class={if !Algora.Stargazer.count(), do: "pointer-events-none opacity-75"}
              href={AlgoraWeb.Constants.get(:github_repo_url)}
              variant="secondary"
            >
              <.icon name="github" class="size-4 mr-2 -ml-1" /> View source code
            </.button>
          </div>
        </div>
      </section>
    </div>
    {share_drawer(assigns)}
    <.modal_video_dialog />
    """
  end

  @impl true
  def handle_info(:bounties_updated, socket) do
    {:noreply, assign_bounties(socket)}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    %{bounties: bounties} = socket.assigns

    more_bounties =
      Bounties.list_bounties(
        Keyword.put(socket.assigns.query_opts, :before, %{
          inserted_at: List.last(bounties).inserted_at,
          id: List.last(bounties).id
        })
      )

    {:noreply,
     socket
     |> assign(:bounties, bounties ++ more_bounties)
     |> assign(:has_more_bounties, length(more_bounties) >= page_size())}
  end

  @impl true
  def handle_event("toggle_tech", %{"tech" => tech}, socket) do
    tech = String.downcase(tech)

    selected_techs =
      if tech in socket.assigns.selected_techs do
        List.delete(socket.assigns.selected_techs, tech)
      else
        [tech | socket.assigns.selected_techs]
      end

    query_opts =
      if selected_techs == [] do
        Keyword.delete(socket.assigns.query_opts, :tech_stack)
      else
        Keyword.put(socket.assigns.query_opts, :tech_stack, selected_techs)
      end

    # Update the URL with selected techs
    path = if selected_techs == [], do: ~p"/bounties", else: ~p"/bounties/#{Enum.join(selected_techs, ",")}"

    {:noreply,
     socket
     |> push_patch(to: path)
     |> assign(:selected_techs, selected_techs)
     |> assign(:query_opts, query_opts)
     |> assign_bounties()}
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

  @impl true
  def handle_event("close_share_drawer", _params, socket) do
    {:noreply, assign(socket, :show_share_drawer, false)}
  end

  @impl true
  def handle_event("share_opportunity", %{"user_id" => user_id, "type" => type}, socket) do
    collab = Enum.find(socket.assigns.featured_collabs, &(&1.user.id == user_id))

    case collab do
      nil ->
        {:noreply, socket}

      collab ->
        {:noreply,
         socket
         |> assign(:selected_developer, collab.user)
         |> assign(:share_drawer_type, type)
         |> assign(:show_share_drawer, true)}
    end
  end

  defp assign_bounties(socket) do
    bounties = Bounties.list_bounties(socket.assigns.query_opts)

    socket
    |> assign(:bounties, bounties)
    |> assign(:has_more_bounties, length(bounties) >= page_size())
  end

  defp page_size, do: 10

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

  defp org_features do
    [
      %{
        title: "GitHub bounties",
        description: "Add USD rewards on issues and pay on-merge",
        src: ~p"/images/screenshots/bounty-to-hire-merged.png"
      },
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
        title: "Transaction history",
        description: "View all payments and export summaries",
        src: ~p"/images/screenshots/org-transactions.png"
      },
      # %{
      #   title: "Pool bounties together",
      #   description: "Pool bounties together to reward contributors",
      #   src: ~p"/images/screenshots/pool-bounties.png"
      # }
      %{
        title: "Global payouts",
        description: "Streamline payouts, compliance and 1099s",
        src: ~p"/images/screenshots/global-payments.png"
      }
    ]
  end

  defp user_features do
    [
      %{
        title: "Bounties & contracts",
        description: "Work on new projects and grow your career",
        src: ~p"/images/screenshots/user-dashboard.png"
      },
      %{
        title: "Your new resume",
        description: "Showcase your open source contributions",
        src: ~p"/images/screenshots/profile.png"
      },
      %{
        title: "Embed on your site",
        description: "Let anyone share a bounty/contract with you",
        src: ~p"/images/screenshots/embed-profile.png"
      },
      %{
        title: "Payment history",
        description: "Monitor your earnings in real-time",
        src: ~p"/images/screenshots/user-transactions.png"
      }
    ]
  end

  defp contributors(assigns) do
    ~H"""
    <div class="relative w-full flex flex-col gap-8">
      <%= for collab <- @featured_collabs do %>
        <.collab_card collab={collab} />
      <% end %>
    </div>
    """
  end

  defp collab_card(assigns) do
    ~H"""
    <div class="group/collab relative flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4 sm:gap-8 border bg-card rounded-xl text-card-foreground shadow p-6 ring-1 ring-transparent transition-all duration-500 hover:ring-1 hover:ring-success">
      <div class="xl:basis-[35%]">
        <div class="flex items-center gap-4">
          <.link navigate={User.url(@collab.user)}>
            <.avatar class="h-20 w-20 rounded-full">
              <.avatar_image src={@collab.user.avatar_url} alt={@collab.user.name} loading="lazy" />
              <.avatar_fallback class="rounded-lg">
                {Algora.Util.initials(@collab.user.name)}
              </.avatar_fallback>
            </.avatar>
          </.link>

          <div>
            <div class="flex items-center gap-4 text-foreground">
              <.link
                navigate={User.url(@collab.user)}
                class="text-lg sm:text-xl font-semibold truncate"
              >
                {@collab.user.name} {Algora.Misc.CountryEmojis.get(@collab.user.country)}
              </.link>
            </div>
            <div
              :if={@collab.user.provider_meta}
              class="pt-0.5 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground sm:text-sm"
            >
              <.link
                :if={@collab.user.provider_login}
                href={"https://github.com/#{@collab.user.provider_login}"}
                target="_blank"
                class="flex items-center gap-1 hover:underline"
              >
                <.icon name="github" class="shrink-0 h-4 w-4" />
                <span class="line-clamp-1">{@collab.user.provider_login}</span>
              </.link>
              <.link
                :if={@collab.user.provider_meta["twitter_handle"]}
                href={"https://x.com/#{@collab.user.provider_meta["twitter_handle"]}"}
                target="_blank"
                class="flex items-center gap-1 hover:underline"
              >
                <.icon name="tabler-brand-x" class="shrink-0 h-4 w-4" />
                <span class="line-clamp-1">{@collab.user.provider_meta["twitter_handle"]}</span>
              </.link>
            </div>
            <div class="pt-2 flex items-center gap-2">
              <%= for tech <- @collab.user.tech_stack |> Enum.reject(& &1 in ["HTML", "MDX", "Dockerfile"]) |> Enum.take(3) do %>
                <.badge variant="outline">{tech}</.badge>
              <% end %>
            </div>
          </div>
        </div>
      </div>

      <div class="pt-4 xl:flex-col gap-4 xl:basis-[15%] xl:ml-auto transition-opacity duration-500 hidden lg:flex lg:opacity-0 group-hover/collab:opacity-100">
        <.button
          phx-click="share_opportunity"
          phx-value-user_id={@collab.user.id}
          phx-value-type="bounty"
          variant="none"
          class="group bg-card text-foreground transition-colors duration-75 hover:bg-blue-800/10 hover:text-blue-300 hover:drop-shadow-[0_1px_5px_#60a5fa80] focus:bg-blue-800/10 focus:text-blue-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#60a5fa80] border border-white/50 hover:border-blue-400/50 focus:border-blue-400/50"
        >
          <.icon name="tabler-diamond" class="size-4 text-current mr-2 -ml-1" /> Bounty
        </.button>
        <.button
          phx-click="share_opportunity"
          phx-value-user_id={@collab.user.id}
          phx-value-type="contract"
          variant="none"
          class="group bg-card text-foreground transition-colors duration-75 hover:bg-emerald-800/10 hover:text-emerald-300 hover:drop-shadow-[0_1px_5px_#34d39980] focus:bg-emerald-800/10 focus:text-emerald-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#34d39980] border border-white/50 hover:border-emerald-400/50 focus:border-emerald-400/50"
        >
          <.icon name="tabler-contract" class="size-4 text-current mr-2 -ml-1" /> Contract
        </.button>
      </div>

      <div class="pt-4 xl:pt-0 xl:pl-8 xl:basis-[50%] xl:border-l xl:border-border">
        <div class="flex items-center gap-1 text-sm sm:text-base text-foreground font-medium">
          <div>
            Completed
            <span class="font-semibold font-display">
              {@collab.user.transactions_count}
              {ngettext(
                "bounty",
                "bounties",
                @collab.user.transactions_count
              )}
            </span>
            <span class="font-semibold font-display">
              {ngettext(
                "in %{count} project",
                "across %{count} projects",
                @collab.user.contributed_projects_count
              )}
            </span>
          </div>
          <span class="ml-auto font-semibold text-lg font-display text-success">
            +{Money.to_string!(@collab.user.total_earned)}
          </span>
        </div>
        <div class="pt-4 flex flex-col sm:flex-row sm:flex-wrap 2xl:flex-nowrap gap-4 xl:gap-8">
          <%= for {project, total_earned} <- @collab.projects |> Enum.take(2) do %>
            <.link
              navigate={User.url(project)}
              class="flex flex-1 items-center gap-2 sm:gap-4 text-sm rounded-lg"
            >
              <.avatar class="h-10 w-10 rounded-lg saturate-0">
                <.avatar_image src={project.avatar_url} alt={project.name} loading="lazy" />
                <.avatar_fallback class="rounded-lg">
                  {Algora.Util.initials(project.name)}
                </.avatar_fallback>
              </.avatar>
              <div class="flex flex-col">
                <div class="text-base font-medium text-muted-foreground">
                  {project.name}
                </div>

                <div class="flex items-center gap-2 whitespace-nowrap">
                  <div class="text-sm text-muted-foreground font-display font-semibold">
                    <.icon name="tabler-star-filled" class="size-4 text-amber-400 mr-1" />{Algora.Util.format_number_compact(
                      project.stargazers_count
                    )}
                  </div>
                  <div class="text-sm text-muted-foreground">
                    <span class="text-foreground font-display font-semibold">
                      {total_earned}
                    </span>
                    awarded
                  </div>
                </div>
              </div>
            </.link>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp share_drawer_header(%{share_drawer_type: "contract"} = assigns) do
    ~H"""
    <.drawer_header>
      <.drawer_title>Offer Contract</.drawer_title>
      <.drawer_description>
        {@selected_developer.name} will be notified and can accept or decline. You can auto-renew or cancel the contract at the end of each period.
      </.drawer_description>
    </.drawer_header>
    """
  end

  defp share_drawer_header(%{share_drawer_type: "bounty"} = assigns) do
    ~H"""
    <.drawer_header>
      <.drawer_title>Share Bounty</.drawer_title>
      <.drawer_description>
        Share a bounty opportunity with {@selected_developer.name}. They will be notified and can choose to work on it.
      </.drawer_description>
    </.drawer_header>
    """
  end

  defp share_drawer_header(%{share_drawer_type: "tip"} = assigns) do
    ~H"""
    <.drawer_header>
      <.drawer_title>Send Tip</.drawer_title>
      <.drawer_description>
        Send a tip to {@selected_developer.name} to show appreciation for their contributions.
      </.drawer_description>
    </.drawer_header>
    """
  end

  defp share_drawer_content(%{share_drawer_type: "contract"} = assigns) do
    ~H"""
    <.form for={@contract_form} phx-submit="create_contract">
      <.card>
        <.card_header>
          <.card_title>Contract Details</.card_title>
        </.card_header>
        <.card_content class="pt-0 flex flex-col">
          <div class="space-y-4">
            <.input
              label="Hourly Rate"
              icon="tabler-currency-dollar"
              field={@contract_form[:hourly_rate]}
            />
            <.input label="Hours per Week" field={@contract_form[:hours_per_week]} />
          </div>
          <div class="pt-8 ml-auto flex gap-4">
            <.button variant="secondary" phx-click="close_share_drawer" type="button">
              Cancel
            </.button>
            <.button type="submit">
              Send Contract Offer <.icon name="tabler-arrow-right" class="-mr-1 ml-2 h-4 w-4" />
            </.button>
          </div>
        </.card_content>
      </.card>
    </.form>
    """
  end

  defp share_drawer_content(%{share_drawer_type: "bounty"} = assigns) do
    ~H"""
    <.form for={@bounty_form} phx-submit="create_bounty">
      <.card>
        <.card_header>
          <.card_title>Bounty Details</.card_title>
        </.card_header>
        <.card_content class="pt-0 flex flex-col">
          <div class="space-y-4">
            <.input type="hidden" name="bounty_form[visibility]" value="exclusive" />
            <.input
              type="hidden"
              name="bounty_form[shared_with][]"
              value={
                case @selected_developer do
                  %{handle: nil, provider_id: provider_id} -> [to_string(provider_id)]
                  %{id: id} -> [id]
                end
              }
            />
            <.input
              label="URL"
              field={@bounty_form[:url]}
              placeholder="https://github.com/owner/repo/issues/123"
            />
            <.input label="Amount" icon="tabler-currency-dollar" field={@bounty_form[:amount]} />
          </div>
          <div class="pt-8 ml-auto flex gap-4">
            <.button variant="secondary" phx-click="close_share_drawer" type="button">
              Cancel
            </.button>
            <.button type="submit">
              Share Bounty <.icon name="tabler-arrow-right" class="-mr-1 ml-2 h-4 w-4" />
            </.button>
          </div>
        </.card_content>
      </.card>
    </.form>
    """
  end

  defp share_drawer_content(%{share_drawer_type: "tip"} = assigns) do
    ~H"""
    <.form for={@tip_form} phx-submit="create_tip">
      <.card>
        <.card_header>
          <.card_title>Tip Details</.card_title>
        </.card_header>
        <.card_content class="pt-0 flex flex-col">
          <div class="space-y-4">
            <input
              type="hidden"
              name="tip_form[github_handle]"
              value={@selected_developer.provider_login}
            />
            <.input label="Amount" icon="tabler-currency-dollar" field={@tip_form[:amount]} />
            <.input
              label="URL"
              field={@tip_form[:url]}
              placeholder="https://github.com/owner/repo/issues/123"
              helptext="We'll add a comment to the issue to notify the developer."
            />
          </div>
          <div class="pt-8 ml-auto flex gap-4">
            <.button variant="secondary" phx-click="close_share_drawer" type="button">
              Cancel
            </.button>
            <.button type="submit">
              Send Tip <.icon name="tabler-arrow-right" class="-mr-1 ml-2 h-4 w-4" />
            </.button>
          </div>
        </.card_content>
      </.card>
    </.form>
    """
  end

  defp share_drawer_developer_info(assigns) do
    ~H"""
    <.card>
      <.card_header>
        <.card_title>Developer</.card_title>
      </.card_header>
      <.card_content class="pt-0">
        <div class="flex items-start gap-4">
          <.avatar class="h-20 w-20 rounded-full">
            <.avatar_image src={@selected_developer.avatar_url} alt={@selected_developer.name} />
            <.avatar_fallback class="rounded-lg">
              {Algora.Util.initials(@selected_developer.name)}
            </.avatar_fallback>
          </.avatar>

          <div>
            <div class="flex items-center gap-1 text-base text-foreground">
              <span class="font-semibold">{@selected_developer.name}</span>
              {Algora.Misc.CountryEmojis.get(@selected_developer.country)}
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
                <.icon name="github" class="h-4 w-4" />
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
              <div :if={@selected_developer.provider_meta["location"]} class="flex items-center gap-1">
                <.icon name="tabler-map-pin" class="h-4 w-4" />
                <span class="whitespace-nowrap">
                  {@selected_developer.provider_meta["location"]}
                </span>
              </div>
              <div :if={@selected_developer.provider_meta["company"]} class="flex items-center gap-1">
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
    """
  end

  defp share_drawer(assigns) do
    ~H"""
    <.drawer show={@show_share_drawer} direction="bottom" on_cancel="close_share_drawer">
      <.share_drawer_header
        :if={@selected_developer}
        selected_developer={@selected_developer}
        share_drawer_type={@share_drawer_type}
      />
      <.drawer_content :if={@selected_developer} class="mt-4">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
          <.share_drawer_developer_info selected_developer={@selected_developer} />
          <div class="relative">
            <div class="absolute inset-0 z-10 bg-background/50" />
            <div class="pointer-events-none">
              <.share_drawer_content
                :if={@selected_developer}
                selected_developer={@selected_developer}
                share_drawer_type={@share_drawer_type}
                bounty_form={@bounty_form}
                tip_form={@tip_form}
                contract_form={@contract_form}
              />
            </div>
            <.alert
              variant="default"
              class="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 z-20 w-auto flex flex-col items-center justify-center gap-2 text-center"
            >
              <.alert_title>Let's get you started</.alert_title>
              <.alert_description>
                Sign up to create a {@share_drawer_type} with {@selected_developer.name}.
              </.alert_description>
              <.button href={~p"/onboarding/org"} type="button" variant="subtle" class="mt-4">
                Get started
              </.button>
            </.alert>
          </div>
        </div>
      </.drawer_content>
    </.drawer>
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
end
