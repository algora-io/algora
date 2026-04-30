defmodule AlgoraWeb.HomeLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

  import AlgoraWeb.Components.ModalVideo
  import Ecto.Changeset

  alias Algora.Accounts
  alias Algora.Bounties
  alias Algora.Jobs
  alias Algora.Matches
  alias Algora.Matches.JobMatch
  alias Algora.Payments
  alias AlgoraWeb.Components.Footer
  alias AlgoraWeb.Components.Header
  alias AlgoraWeb.Data.HomeCache
  alias AlgoraWeb.LocalStore

  require Logger

  defmodule Form do
    @moduledoc false
    use Ecto.Schema

    @primary_key false
    @derive Jason.Encoder
    embedded_schema do
      field :email, :string
      field :job_description, :string
      field :candidate_description, :string
      field :comp_range, :string
      field :location, :string
      field :location_type, :string
      field :hire_type, :string
      field :tech_stack, {:array, :string}
    end

    def changeset(form, attrs \\ %{}) do
      form
      |> Ecto.Changeset.cast(attrs, [
        :email,
        :job_description,
        :candidate_description,
        :comp_range,
        :location,
        :location_type,
        :hire_type,
        :tech_stack
      ])
      |> Ecto.Changeset.validate_required([:email, :job_description])
      |> Ecto.Changeset.validate_format(:email, ~r/@/)
    end
  end

  @impl true
  def mount(params, _session, socket) do
    # Get cached platform stats
    platform_stats = HomeCache.get_platform_stats()

    stats1 = [
      %{label: "Full-time Hires", value: "30+"},
      %{label: "1st Year Retention", value: "100%"},
      %{label: "Time to Interview", value: "<1 wk"}
    ]

    stats2 = [
      %{label: "Countries", value: format_number(platform_stats.total_countries)},
      %{label: "Paid Out", value: format_money(platform_stats.total_paid_out)},
      %{label: "Completed Bounties", value: format_number(platform_stats.completed_bounties_count)}
    ]

    # Get cached jobs and orgs data
    jobs_by_user = HomeCache.get_jobs_by_user()
    orgs_with_stats = HomeCache.get_orgs_with_stats()

    # Load candidate data
    candidate_ids = ["qsQa7KN3Cq4PwGWG", "Y5JrLmNRvL7o3Bes", "EPYrDRS1ojkjqL9w", "Y1LQ896AbtT9Wjj1", "1ErYxMGNt6zTfjKS"]

    candidates_data =
      candidate_ids
      |> Enum.map(&load_candidate_data/1)
      |> Enum.reject(&is_nil/1)

    # Build mixed carousel items: Candidate, Candidate, Job page, Candidate, Candidate, Job page
    carousel_items = build_carousel_items(candidates_data)

    case socket.assigns[:current_user] do
      %{handle: handle} = user when is_binary(handle) ->
        {:ok, redirect(socket, to: AlgoraWeb.UserAuth.signed_in_path(user))}

      _ ->
        socket =
          socket
          |> assign(:page_title, "Algora - Hire the top 1% open source engineers")
          |> assign(:page_title_suffix, "")
          |> assign(:page_image, "#{AlgoraWeb.Endpoint.url()}/images/og/home.png")
          |> assign(:screenshot?, not is_nil(params["screenshot"]))
          |> assign(:stats1, stats1)
          |> assign(:stats2, stats2)
          |> assign(:jobs_by_user, jobs_by_user)
          |> assign(:orgs_with_stats, orgs_with_stats)
          |> assign(:hires, hires())
          |> assign(:tech_stack, [])
          |> assign(:candidates_data, candidates_data)
          |> assign(:carousel_items, carousel_items)
          |> assign(:current_candidate_index, 0)
          |> assign(:liked_ids, [])
          |> assign(:disliked_ids, [])
          |> assign(:form, to_form(Form.changeset(%Form{}, %{tech_stack: []})))
          |> assign_user_applications()
          |> assign_events()
          |> LocalStore.init(key: __MODULE__)

        socket = if connected?(socket), do: LocalStore.subscribe(socket), else: socket
        {:ok, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div
        id="local-state-store"
        phx-hook="LocalStateStore"
        data-storage="localStorage"
        class="hidden"
      >
      </div>
      <%= if @screenshot? do %>
        <div class="-mt-24" />
      <% else %>
        <Header.header class="container fixed top-0 left-0 right-0 z-50 bg-black" />
      <% end %>

      <main class="bg-black relative">
        <%!-- Hero section --%>
        <section class="min-h-screen flex flex-col">
          <div class="flex-1 mx-auto px-6 lg:px-8 flex flex-col items-start justify-center pt-20 lg:pt-24 2xl:pt-32 pb-4 w-full max-w-3xl">
            <%!-- Hero copy (unchanged) --%>
            <h1 class="text-2xl min-[412px]:text-[1.75rem] sm:text-[2.5rem]/[3rem] md:text-[3.5rem]/[4rem] lg:text-[3rem]/[3.5rem] xl:text-[4rem]/[4.5rem] font-black tracking-tight text-foreground font-display">
              Open source <br class="hidden" />
              <span class="text-emerald-400">tech recruiting</span>
            </h1>
            <p class="mt-2 text-[0.9rem]/[1.4rem] min-[412px]:text-base md:text-lg xl:text-lg 2xl:text-xl leading-6 font-medium text-foreground">
              Connecting the most prolific open source maintainers & contributors with their next jobs
            </p>
            <%!--
            <div class="grid grid-cols-3 place-items-center sm:grid-cols-6 gap-4 md:gap-5 lg:gap-0 py-4 w-full">
              <img src="/images/wordmarks/coderabbit.svg" alt="CodeRabbit" class="h-6 md:h-7 transition-all" />
              <img src="/images/wordmarks/asi.svg" alt="Air Space Intelligence" class="h-7 md:h-9 transition-all" />
              <img src="/images/wordmarks/lovable.svg" alt="Lovable" class="h-3 md:h-4 transition-all" />
              <img src="/images/wordmarks/comfy.svg" alt="Comfy" class="h-3.5 md:h-5 transition-all saturate-0" />
              <div class="flex items-center transition-all">
                <img src="/images/wordmarks/firecrawl.svg" alt="Firecrawl" class="h-6 md:h-7" />
                <img src="/images/wordmarks/firecrawl2.svg" alt="Firecrawl2" class="h-3 md:h-4" />
              </div>
              <img src="/images/wordmarks/textql.svg" alt="TextQL" class="h-4 md:h-5 transition-all" />
            </div>
            --%>
            <%!-- Hires: testimonial cards then metrics --%>
            <div class="w-full space-y-6 sm:space-y-8 mt-10 sm:mt-14">
              <%= for hire <- @hires do %>
                <div class="relative">
                  <div class="relative overflow-hidden rounded-xl border-2 border-white/30 shadow-xl shadow-white/10 bg-black">
                    <img
                      src={hire.bg_image}
                      alt=""
                      class="absolute inset-0 size-full object-cover object-top grayscale"
                    />
                    <div
                      class="absolute inset-0 mix-blend-multiply"
                      style={"background-color: #{hire.overlay_color}"}
                    >
                    </div>
                    <div class="absolute inset-0 bg-gradient-to-t from-black/90 via-black/50 to-black/30">
                    </div>
                    <div class="relative p-4 sm:p-5 min-h-[14rem] flex flex-col justify-center">
                      <div class="flex items-center gap-3 mb-3">
                        <img
                          src={hire.person_avatar}
                          alt={hire.person_name}
                          class="size-9 sm:size-10 rounded-full ring-2 ring-white/50 shrink-0"
                        />
                        <.icon name="tabler-arrow-right" class="size-3.5 text-white/80 shrink-0" />
                        <img
                          src={hire.company_avatar}
                          alt={hire.company_name}
                          class="size-9 sm:size-10 rounded-full ring-2 ring-white/50 shrink-0"
                        />
                        <div class="min-w-0">
                          <div class="text-sm font-semibold text-white/90 truncate">
                            {hire.person_name} → {hire.company_name}
                          </div>
                          <div class="text-xs text-white/80">{hire.person_title}</div>
                        </div>
                      </div>
                      <blockquote class="text-sm font-medium text-white/90 leading-relaxed">
                        "{hire.testimonial}"
                      </blockquote>
                      <div class="mt-2 flex items-center gap-2">
                        <span class="text-sm text-white/70 font-medium">
                          {hire.testimonial_author}
                        </span>
                      </div>
                      <div class="mt-3 pt-3 border-t border-white/10 space-y-3">
                        <div class="flex items-center gap-2">
                          <img
                            src={hire.testimonial_logo}
                            alt={hire.company_name}
                            class={["opacity-70", hire.testimonial_logo_class]}
                          />
                          <p class="text-sm text-white/60 truncate">{hire.description}</p>
                        </div>
                        <div class="grid grid-cols-3">
                          <div>
                            <div class="text-lg sm:text-xl font-display font-semibold text-white/90">
                              Series {hire.series}
                            </div>
                            <div class="text-xs text-white/50 mt-0.5">round</div>
                          </div>
                          <div>
                            <%= if hire[:valuation] do %>
                              <div class="text-lg sm:text-xl font-display font-semibold text-white/90">
                                {hire.valuation}
                              </div>
                              <div class="text-xs text-white/50 mt-0.5">valuation</div>
                            <% end %>
                          </div>
                          <div>
                            <div class="text-lg sm:text-xl font-display font-semibold text-white/90">
                              {hire.raised}
                            </div>
                            <div class="text-xs text-white/50 mt-0.5">raised</div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                  <.badge
                    variant="secondary"
                    class="absolute -top-2 -left-2 text-xs px-2 sm:px-3 py-0.5 text-black bg-gradient-to-r from-emerald-400 to-emerald-500 font-semibold shadow-lg"
                  >
                    <.icon name="tabler-star-filled" class="size-3.5 text-black mr-1 -ml-0.5" />
                    New hire!
                  </.badge>
                </div>
              <% end %>
              <%!-- Metrics after hires --%>
              <div class="grid grid-cols-3 gap-6 sm:gap-10 pt-2">
                <%= for stat <- @stats1 do %>
                  <div>
                    <div class="text-3xl sm:text-4xl font-bold font-display text-foreground">
                      {stat.value}
                    </div>
                    <div class="text-xs sm:text-sm text-muted-foreground mt-1">{stat.label}</div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
          <%!-- Scroll arrow --%>
          <div class="flex flex-col items-center gap-1 py-6 sm:py-8">
            <span class="text-xs font-medium text-muted-foreground tracking-widest uppercase">
              Scroll to get started
            </span>
            <div class="mt-2 flex flex-col items-center animate-bounce">
              <.icon name="tabler-chevron-down" class="size-5 text-emerald-400" />
              <.icon name="tabler-chevron-down" class="-mt-2 size-5 text-emerald-400/50" />
            </div>
          </div>
        </section>

        <%!-- Candidate section: tinder-style single card --%>
        <% current_candidate = Enum.at(@candidates_data, @current_candidate_index) %>
        <section
          id="candidate-section"
          phx-hook="TinderSection"
          class="relative min-h-screen px-4 sm:px-6 pt-4 pb-4"
        >
          <%= if current_candidate do %>
            <Algora.Cloud.candidate_card {Map.merge(current_candidate, %{
              anonymize: true,
              # root_class: "h-[calc(100svh-8rem)] max-h-[52rem]",
              tech_stack: [],
              hide_badges?: true,
              hide_scrollbars?: true
            })} />
          <% else %>
            <div class="flex flex-col items-center justify-center min-h-[60vh] gap-4 text-center">
              <.icon name="tabler-check" class="size-12 text-emerald-400" />
              <p class="text-lg font-semibold text-foreground">You've reviewed all candidates</p>
              <p class="text-sm text-muted-foreground">Check back soon for more</p>
            </div>
          <% end %>
        </section>

        <%!--
        View your candidates form (commented out)
        <div class="order-2 lg:sticky lg:top-0 lg:order-2 lg:col-start-2 lg:row-start-1 lg:self-start px-6 lg:px-0 pb-12 lg:pb-8 lg:pt-24 2xl:pt-32 overflow-y-auto lg:max-h-screen scrollbar-thin">
          <div class="text-left">
            <div class="rounded-xl bg-card text-card-foreground shadow-2xl border">
              <div class="p-6 lg:p-8">
                <h2 class="text-2xl lg:text-3xl font-semibold leading-7 text-foreground">
                  View your candidates
                </h2>
                ...
              </div>
            </div>
          </div>
        </div>

        Hire with Confidence section (commented out)
        <section class="relative isolate py-8 sm:py-20">
          <div class="mx-auto px-6 lg:px-8 pt-24 xl:pt-0">
            <h2 class="font-display text-[2rem] font-semibold tracking-tight text-foreground sm:text-6xl sm:mb-4 text-center sm:text-left">
              Hire with Confidence
            </h2>
            ...
          </div>
        </section>
        --%>
      </main>

      <%!-- Tinder action buttons: fixed dock, shown when candidate section is in view --%>
      <div
        id="tinder-buttons"
        phx-update="ignore"
        class="fixed bottom-0 left-0 right-0 z-40 flex items-center justify-center gap-6 px-6 pb-8 pt-5 bg-gradient-to-t from-black via-black/80 to-transparent opacity-0 transition-opacity duration-500 pointer-events-none"
      >
        <button
          class="pointer-events-auto flex flex-col items-center justify-center gap-2 w-36 py-4 rounded-2xl bg-red-950/60 border-2 border-red-500/50 hover:border-red-400 hover:bg-red-900/60 shadow-xl shadow-red-900/40 transition-all active:scale-95"
          phx-click="dislike_candidate"
          aria-label="Skip candidate"
        >
          <.icon name="tabler-x" class="size-8 text-red-400" />
          <span class="text-sm font-semibold text-red-400 tracking-wide">Skip</span>
        </button>
        <button
          class="pointer-events-auto flex flex-col items-center justify-center gap-2 w-36 py-4 rounded-2xl bg-emerald-950/60 border-2 border-emerald-500/50 hover:border-emerald-400 hover:bg-emerald-900/60 shadow-xl shadow-emerald-900/40 transition-all active:scale-95"
          phx-click="like_candidate"
          aria-label="Like candidate"
        >
          <.icon name="tabler-heart" class="size-8 text-emerald-400" />
          <span class="text-sm font-semibold text-emerald-400 tracking-wide">Like</span>
        </button>
      </div>
    </div>

    <%!--
    <div class="relative isolate overflow-hidden bg-gradient-to-br from-black to-background">
      <Footer.footer class="max-w-[88rem]" />
    </div>
    --%>

    <.modal_video_dialog />
    """
  end

  @impl true
  def handle_event("submit", %{"form" => params}, socket) do
    dbg(params)

    tech_stack =
      Jason.decode!(params["tech_stack"] || "[]") ++
        case String.trim(params["tech_stack_input"] || "") do
          "" -> []
          tech_stack_input -> String.split(tech_stack_input, ",")
        end

    params = Map.put(params, "tech_stack", tech_stack)

    case %Form{} |> Form.changeset(params) |> Ecto.Changeset.apply_action(:save) do
      {:ok, data} ->
        Algora.Cloud.create_welcome_task(data)

        {:noreply, put_flash(socket, :info, "Thanks for submitting your JD, you'll hear back soon!")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("tech_stack_changed", %{"tech_stack" => tech_stack}, socket) do
    {:noreply, assign(socket, :tech_stack, tech_stack)}
  end

  @impl true
  def handle_event("restore_settings", token, socket) do
    {:noreply, LocalStore.restore(socket, token)}
  end

  @impl true
  def handle_event("like_candidate", _params, socket) do
    current = Enum.at(socket.assigns.candidates_data, socket.assigns.current_candidate_index)
    user_id = current && current.candidate.match.user.id
    liked_ids = if user_id, do: [user_id | socket.assigns.liked_ids], else: socket.assigns.liked_ids

    socket =
      socket
      |> assign(:current_candidate_index, socket.assigns.current_candidate_index + 1)
      |> LocalStore.assign_cached(:liked_ids, liked_ids)

    {:noreply, socket}
  end

  @impl true
  def handle_event("dislike_candidate", _params, socket) do
    current = Enum.at(socket.assigns.candidates_data, socket.assigns.current_candidate_index)
    user_id = current && current.candidate.match.user.id
    disliked_ids = if user_id, do: [user_id | socket.assigns.disliked_ids], else: socket.assigns.disliked_ids

    socket =
      socket
      |> assign(:current_candidate_index, socket.assigns.current_candidate_index + 1)
      |> LocalStore.assign_cached(:disliked_ids, disliked_ids)

    {:noreply, socket}
  end

  @impl true
  def handle_event("apply_job", %{"job-id" => job_id}, socket) do
    if socket.assigns[:current_user] do
      if Accounts.has_fresh_token?(socket.assigns.current_user) do
        case Jobs.create_application(job_id, socket.assigns.current_user) do
          {:ok, _application} ->
            {:noreply, assign_user_applications(socket)}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to submit application. Please try again.")}
        end
      else
        {:noreply, redirect(socket, external: Algora.Github.authorize_url(%{return_to: "/jobs"}))}
      end
    else
      {:noreply, redirect(socket, external: Algora.Github.authorize_url(%{return_to: "/jobs"}))}
    end
  end

  defp format_money(money), do: money |> Money.round(currency_digits: 0) |> Money.to_string!(no_fraction_if_integer: true)

  defp format_number(number), do: Number.Delimit.number_to_delimited(number, precision: 0)

  defp assign_user_applications(socket) do
    user_applications =
      if socket.assigns[:current_user] do
        Jobs.list_user_applications(socket.assigns.current_user)
      else
        MapSet.new()
      end

    assign(socket, :user_applications, user_applications)
  end

  def event_card(assigns) do
    ~H"""
    <.link
      navigate={@event.link}
      class="group relative flex items-center gap-4 bg-card p-4 md:p-6 rounded-xl border-l-8 transition-all mb-6 z-10 hover:scale-[1.03] border-[color:var(--event-theme-color)] shadow-[0px_0px_3px_var(--event-theme-color-10),_0px_0px_6px_var(--event-theme-color-15),_0px_0px_8px_var(--event-theme-color-20)]"
      style={"--event-theme-color: #{@event.theme_color}; --event-theme-color-05: #ffffff0D; --event-theme-color-08: #ffffff14; --event-theme-color-10: #ffffff1A; --event-theme-color-15: #ffffff26; --event-theme-color-20: #ffffff33;"}
    >
      <div class="size-12 md:size-16 rounded-xl bg-background flex-shrink-0 overflow-hidden">
        <img src={@event.logo} alt={@event.alt} class="w-full h-full object-contain" />
      </div>
      <div class="flex-1">
        <div class="flex items-center gap-2">
          <p class="text-sm md:text-lg font-semibold text-foreground">
            {@event.title}
          </p>
        </div>
        <p class="text-xs md:text-sm text-muted-foreground flex items-center gap-2 mt-1">
          {@event.date}
        </p>
      </div>
      <.icon
        name="tabler-chevron-right"
        class="size-4 md:size-6 text-muted-foreground group-hover:text-[color:var(--event-theme-color)] transition-colors"
      />
    </.link>
    """
  end

  defp hires do
    [
      %{
        special: true,
        company_name: "CodeRabbit",
        company_avatar: "https://avatars.githubusercontent.com/u/132028505?s=200&v=4",
        person_name: "Erfan",
        person_avatar: "https://algora.io/storage/avatars/taisazero.jpeg",
        person_title: "Applied AI Engineer",
        bg_image: "https://algora.io/storage/avatars/coderabbit/sam-hayes-85a0ba25.jpg",
        overlay_color: "rgba(67, 20, 7, 0.6)",
        description: "AI code reviews",
        series: "B",
        raised: "$60M",
        valuation: "$550M",
        testimonial:
          "Within one week of onboarding, we started interviewing qualified candidates who joined CodeRabbit in San Francisco.",
        testimonial_author: "Sam Hayes · Talent Acquisition Lead",
        testimonial_logo: "/images/wordmarks/coderabbit.svg",
        testimonial_logo_class: "h-6"
      },
      %{
        special: true,
        company_name: "ComfyUI",
        company_avatar: "https://avatars.githubusercontent.com/u/166579949?v=4",
        person_name: "Matt",
        person_avatar: "https://algora.io/storage/avatars/MillerMedia.jpeg",
        person_title: "Backend Engineer",
        bg_image: "https://pbs.twimg.com/profile_images/1987431529296109574/37rh5jdP_400x400.jpg",
        overlay_color: "rgba(117, 125, 14, 0.65)",
        description: "Open source OS for creative AI",
        series: "B",
        raised: "$30M",
        valuation: "$500M",
        testimonial:
          "We needed someone who could hit the ground running in an open source-first environment. Algora found us exactly that — a developer already embedded in the ecosystem.",
        testimonial_author: "Robin Huang · Cofounder",
        testimonial_logo: "/images/wordmarks/comfy.svg",
        testimonial_logo_class: "h-4"
      },
      %{
        special: true,
        company_name: "TextQL",
        company_avatar: "https://algora.io/storage/avatars/textql.jpeg",
        person_name: "Christian",
        person_avatar: "https://avatars.githubusercontent.com/u/2482353?v=4",
        person_title: "Member of Technical Staff",
        bg_image:
          "https://media.licdn.com/dms/image/v2/D4E03AQH4x-LiUVr6SA/profile-displayphoto-scale_400_400/B4EZlePKFtKYAg-/0/1758222656365?e=1779321600&v=beta&t=Vw_xCN6uxvuYBQ-tANlL1WmL2l_dcboo2jzKSqqrqF4",
        overlay_color: "rgba(8, 69, 51, 0.75)",
        description: "Agentic analytics for enterprises",
        series: "A",
        raised: "$17M",
        valuation: nil,
        testimonial:
          "Algora's candidates came pre-vetted through their open source contributions. We hired someone we could verify before ever getting on a call.",
        testimonial_author: "Mark Hay · Cofounder & CTO",
        testimonial_logo: "/images/wordmarks/textql.svg",
        testimonial_logo_class: "h-4"
      }
    ]
  end

  defp assign_events(socket) do
    transactions = Payments.list_featured_transactions()
    bounties = Bounties.list_bounties(status: :open, limit: 10, amount_gt: Money.new(:USD, 200))
    jobs_by_user = []
    matches = Matches.list_job_matches_with_assocs()

    ats_events =
      Enum.flat_map(matches, fn match ->
        match
        |> JobMatch.get_application_history()
        |> Enum.filter(fn event -> event["id"] in Algora.Cloud.ats_event_ids() end)
        |> Enum.map(fn event ->
          %{item: %{match: match, event: event}, type: :ats, timestamp: Algora.Util.to_date!(event["enteredStageAt"])}
        end)
      end)

    events =
      transactions
      |> Enum.map(fn tx -> %{item: tx, type: :transaction, timestamp: tx.succeeded_at} end)
      |> Enum.concat(
        jobs_by_user
        |> Enum.flat_map(fn {_user, jobs} -> jobs end)
        |> Enum.map(fn job -> %{item: job, type: :job, timestamp: job.inserted_at} end)
      )
      |> Enum.concat(
        Enum.map(bounties || [], fn bounty ->
          %{item: bounty, type: :bounty, timestamp: bounty.inserted_at}
        end)
      )
      |> Enum.concat(ats_events)
      |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})

    assign(socket, :events, events)
  end

  defp load_candidate_data(match_id) do
    case Matches.get_job_match_by_id(match_id) do
      nil ->
        nil

      match ->
        # Preload the nested job_posting.user association
        match = Algora.Repo.preload(match, job_posting: :user)
        user = match.user

        # Fetch contributions for this user
        contributions = Algora.Workspace.list_user_contributions([user.id], exclude_personal: false, display_all: true)

        contributions_map = %{user.id => contributions}

        # Fetch language contributions for this user
        language_contributions_map =
          [user.id]
          |> Algora.Cloud.list_language_contributions_batch()
          |> transform_language_contributions()

        # Fetch heatmap data for this user
        heatmaps_map =
          [user.id]
          |> Algora.Cloud.list_heatmaps()
          |> Map.new(fn heatmap -> {heatmap.user_id, heatmap.data} end)

        # Build interviews map
        interviews_map = build_interviews_map([match])

        %{
          candidate: %{
            match: match,
            job_posting: match.job_posting,
            job_title: match.job_posting.title || "Software Engineer"
          },
          contributions_map: contributions_map,
          language_contributions_map: language_contributions_map,
          heatmaps_map: heatmaps_map,
          org_badge_data: nil,
          hiring_managers: [],
          interviews_map: interviews_map,
          current_org: match.job_posting.user,
          anonymize: false,
          base_anonymize: false,
          screenshot?: true,
          fullscreen?: false,
          current_user: nil,
          current_user_role: nil,
          tech_stack: match.job_posting.tech_stack || []
        }
    end
  end

  defp transform_language_contributions(contributions_map) do
    # Transform language contributions similar to candidates2_live.ex
    Map.new(contributions_map, fn {user_id, contributions} ->
      transformed =
        contributions
        |> Enum.map(fn contrib ->
          case contrib.language do
            "JavaScript" -> %{contrib | language: "TypeScript"}
            "Jupyter Notebook" -> %{contrib | language: "Python"}
            "Markdown" -> nil
            "MDX" -> nil
            "TeX" -> nil
            "HTML" -> nil
            "CSS" -> nil
            "Sass" -> nil
            "Nunjucks" -> nil
            "Nushell" -> nil
            "reStructuredText" -> nil
            "Nix" -> nil
            "Makefile" -> nil
            "Emacs Lisp" -> nil
            "Mustache" -> nil
            _ -> contrib
          end
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.group_by(& &1.language)
        |> Enum.map(fn {_language, contribs} ->
          # Combine contributions for the same language
          Enum.reduce(contribs, fn contrib, acc ->
            %{
              acc
              | prs: acc.prs + contrib.prs,
                percentage: Decimal.add(acc.percentage, contrib.percentage)
            }
          end)
        end)
        |> Enum.sort_by(& &1.percentage, {:desc, Decimal})

      {user_id, transformed}
    end)
  end

  defp build_interviews_map(matches) do
    # Build interviews map for matches similar to candidates2_live.ex
    import Ecto.Query

    alias Algora.Repo

    user_ids = matches |> Enum.map(& &1.user_id) |> Enum.uniq()
    job_posting_ids = matches |> Enum.map(& &1.job_posting_id) |> Enum.uniq()

    interviews =
      Repo.all(
        from(ji in Algora.Interviews.JobInterview,
          where: ji.user_id in ^user_ids and ji.job_posting_id in ^job_posting_ids,
          preload: [:user]
        )
      )

    Enum.reduce(interviews, %{}, fn interview, acc ->
      Map.put(acc, {interview.user_id, interview.job_posting_id}, interview)
    end)
  end

  defp build_carousel_items(candidates_data) do
    job_pages = [
      # %{url: "https://algora.io/og/coderabbit/jobs", alt: "CodeRabbit jobs"},
      # %{url: "https://algora.io/og/lovable/jobs", alt: "Lovable jobs"}
    ]

    # Cadence: Candidate, Candidate, Job page, Candidate, Candidate, Job page
    candidates_data
    |> Enum.reduce({[], 0, 0}, fn candidate, {acc, candidate_count, job_page_index} ->
      # Add the candidate
      acc_with_candidate = acc ++ [{:candidate, candidate}]
      new_candidate_count = candidate_count + 1

      # After every 2 candidates, insert a job page
      if job_pages != [] and rem(new_candidate_count, 2) == 0 do
        job_page = Enum.at(job_pages, rem(job_page_index, length(job_pages)))
        {acc_with_candidate ++ [{:job_page, job_page}], new_candidate_count, job_page_index + 1}
      else
        {acc_with_candidate, new_candidate_count, job_page_index}
      end
    end)
    |> elem(0)
  end
end
