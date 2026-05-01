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
  alias Algora.PSP.ConnectCountries
  alias Algora.Settings
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
    stats1 = [
      %{label: "Full-time Hires", value: "30+"},
      %{label: "1st Year Retention", value: "100%"},
      %{label: "Time to Interview", value: "<1 wk"}
    ]

    # Get cached jobs and orgs data
    jobs_by_user = HomeCache.get_jobs_by_user()
    orgs_with_stats = HomeCache.get_orgs_with_stats()

    # Load candidate data (override via Settings.home_carousel_candidates)
    candidate_ids =
      Settings.get_home_carousel_candidate_ids()

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
        client_timezone = read_client_timezone(socket)

        socket =
          socket
          |> assign(:page_title, "Algora - Hire the top 1% open source engineers")
          |> assign(:page_title_suffix, "")
          |> assign(:page_image, "#{AlgoraWeb.Endpoint.url()}/images/og/home.png")
          |> assign(:screenshot?, not is_nil(params["screenshot"]))
          |> assign(:stats1, stats1)
          |> assign(:jobs_by_user, jobs_by_user)
          |> assign(:orgs_with_stats, orgs_with_stats)
          |> assign(:hires, hires())
          |> assign(:tech_stack, [])
          |> assign(:candidates_data, candidates_data)
          |> assign(:carousel_items, carousel_items)
          |> assign(:current_candidate_index, 0)
          |> assign(:onboarding_started, onboarding_started?(params))
          |> assign(:liked_ids, [])
          |> assign(:disliked_ids, [])
          |> assign(:show_onboarding_form, false)
          |> assign(:transitioning_to_onboarding_form, false)
          |> assign(:onboarding_form_submitted, false)
          |> assign(:client_timezone, client_timezone)
          |> assign(
            :form,
            to_form(
              Form.changeset(%Form{}, %{
                tech_stack: [],
                location: location_prefill(client_timezone, socket.assigns[:current_country])
              })
            )
          )
          |> assign_user_applications()
          |> assign_events()
          |> LocalStore.init(key: __MODULE__)

        socket = if connected?(socket), do: LocalStore.subscribe(socket), else: socket
        {:ok, socket}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    onboarding_started = onboarding_started?(params) || socket.assigns.onboarding_started

    {:noreply, assign(socket, :onboarding_started, onboarding_started)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class={unless @screenshot?, do: "relative lg:min-h-[100dvh] lg:flex lg:flex-col"}>
      <div
        :if={not @screenshot?}
        class="pointer-events-none fixed inset-0 z-0 overflow-hidden bg-black"
        aria-hidden="true"
      >
        <div
          class="absolute inset-0"
          style="background-image: radial-gradient(circle, rgba(255,255,255,0.10) 1px, transparent 1px); background-size: 28px 28px;"
        >
        </div>
      </div>
      <% likes_reached_goal = onboarding_goal_reached?(@liked_ids) %>
      <% deck_exhausted? = deck_exhausted?(@current_candidate_index, @candidates_data) %>
      <% present_onboarding_form_ui? =
        @show_onboarding_form || deck_exhausted? || @onboarding_form_submitted %>
      <% tinder_buttons_visible? =
        (@onboarding_started ||
           (!@show_onboarding_form && !deck_exhausted? && !@onboarding_form_submitted)) &&
          !present_onboarding_form_ui? %>
      <div
        id="local-state-store"
        phx-hook="LocalStateStore"
        data-storage="localStorage"
        class="hidden"
      >
      </div>
      <%!-- <div :if={not @screenshot?} class="container mx-auto max-w-5xl px-4 pt-16 sm:pt-20">
        <.debug
          class="max-h-80 text-xs text-foreground border border-white/10"
          data={visitor_ipinfo_debug(@ipinfo, @current_country, @client_timezone)}
        />
      </div> --%>
      <%= if @screenshot? do %>
        <div class="-mt-24" />
      <% end %>
      <div
        :if={not @screenshot? and not @onboarding_started}
        id="home-top-navbar"
        phx-update="ignore"
        class="relative z-10 w-full shrink-0 bg-black overflow-hidden transition-all duration-300 ease-out max-h-40 opacity-100 translate-y-0"
      >
        <Header.header overlay={false} class="max-w-6xl w-full bg-black" />
      </div>

      <main class={[
        "relative z-10",
        if(@screenshot?, do: "bg-black", else: "bg-transparent"),
        @screenshot? == false && "lg:flex-1 lg:min-h-0 lg:flex lg:flex-col"
      ]}>
        <%!-- Hero section --%>
        <section
          :if={!@onboarding_started}
          class="min-h-screen flex flex-col lg:min-h-0 lg:flex-1 lg:overflow-hidden"
        >
          <div class="flex-1 w-full max-w-6xl mx-auto px-6 lg:px-8 flex flex-col min-h-0">
            <div class="flex-1 flex flex-col lg:items-center justify-center lg:justify-start pb-4 w-full min-h-0 lg:overscroll-y-contain">
              <%!-- Hero copy (unchanged) --%>
              <h1 class="text-2xl min-[412px]:text-[1.75rem] sm:text-[2.5rem]/[3rem] md:text-[3.5rem]/[4rem] lg:text-[3rem]/[3.5rem] xl:text-[5rem]/[5.5rem] font-black tracking-tight text-foreground font-display">
                Open source <br class="hidden" />
                <span class="text-emerald-400">tech recruiting</span>
              </h1>
              <p class="mt-2 text-[0.9rem]/[1.4rem] min-[412px]:text-base md:text-lg xl:text-lg 2xl:text-2xl leading-6 font-medium text-foreground">
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
              <div class="w-full mt-4 sm:mt-8 grid grid-cols-1 gap-6 sm:gap-4 lg:grid-cols-3">
                <%= for hire <- @hires do %>
                  <div
                    class="relative h-full min-h-[20rem] sm:min-h-[30rem]"
                    style={"--hire-theme: #{hire.theme_color}"}
                  >
                    <div
                      class="relative h-full overflow-hidden rounded-xl border-2 border-white/30 shadow-xl shadow-white/10"
                      style={"background-color: #{hire.overlay_color}"}
                    >
                      <img
                        src={hire.bg_image}
                        alt=""
                        style="object-position: 0% 0%;"
                        class={[
                          "absolute inset-0 size-full object-cover grayscale"
                        ]}
                      />

                      <div
                        class="absolute inset-0 mix-blend-multiply"
                        style={"background-color: #{hire.overlay_color}"}
                      >
                      </div>
                      <div class="absolute inset-0 bg-gradient-to-t from-black/90 via-black/50 to-black/30">
                      </div>
                      <div class="relative h-full p-4 sm:p-5 min-h-[14rem] flex flex-col justify-center">
                        <div class="flex items-center gap-3 mb-3">
                          <img
                            src={hire.person_avatar}
                            alt={hire.person_name}
                            class="size-9 sm:size-10 rounded-full ring-2 ring-[color:var(--hire-theme)] shrink-0"
                          />
                          <.icon name="tabler-arrow-right" class="size-3.5 text-white/80 shrink-0" />
                          <img
                            src={hire.company_avatar}
                            alt={hire.company_name}
                            class="size-9 sm:size-10 rounded-full ring-2 ring-[color:var(--hire-theme)] shrink-0"
                          />
                          <div class="min-w-0">
                            <div class="text-sm font-semibold text-white/90 truncate">
                              {hire.person_name}
                            </div>
                            <div class="text-xs text-white/80">{hire.person_title}</div>
                          </div>
                        </div>
                        <blockquote class="text-sm font-medium text-white/90 leading-relaxed">
                          "{hire_testimonial_markup(hire)}"
                        </blockquote>
                        <div class="mt-2 flex items-center gap-2">
                          <span class="text-sm text-white/70 font-medium">
                            {hire.testimonial_author}
                          </span>
                        </div>
                        <div class="mt-3"></div>
                        <div class="mt-auto pt-3 border-t border-white/10 space-y-3">
                          <div class="flex items-center gap-2">
                            <img
                              src={hire.testimonial_logo}
                              alt={hire.company_name}
                              class={["opacity-70", hire.testimonial_logo_class]}
                            />
                            <p class="text-sm text-white/80 truncate">{hire.description}</p>
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
                      style="background-color: color-mix(in srgb, var(--hire-theme) 10%, rgba(0, 0, 0, 100%)); border: 2px solid var(--hire-theme)"
                      class="absolute -top-2 -left-2 text-xs px-2 sm:px-3 py-0.5 font-semibold shadow-lg text-white/80"
                    >
                      <.icon
                        name="tabler-star-filled"
                        class="size-3.5 text-[color:var(--hire-theme)] mr-1 -ml-0.5"
                      /> New hire!
                    </.badge>
                  </div>
                <% end %>
              </div>
            </div>
            <%!-- Scroll arrow --%>
            <div class="flex shrink-0 flex-col items-center gap-1 py-6 sm:py-8 lg:py-4 lg:pb-6">
              <span class="text-xs font-medium text-muted-foreground tracking-widest uppercase">
                Scroll to get started
              </span>
              <div class="mt-2 flex flex-col items-center animate-bounce">
                <.icon name="tabler-chevron-down" class="size-5 text-emerald-400" />
                <.icon name="tabler-chevron-down" class="-mt-2 size-5 text-emerald-400/50" />
              </div>
            </div>
          </div>
        </section>

        <%!-- Candidate section: tinder-style single card --%>
        <% current_candidate = Enum.at(@candidates_data, @current_candidate_index) %>
        <section
          id="candidate-section"
          phx-hook="TinderSection"
          data-onboarding-started={to_string(@onboarding_started)}
          class="relative min-h-screen"
        >
          <div class="pointer-events-none absolute inset-0 z-[5] overflow-hidden" aria-hidden="true">
            <div class="motion-safe:animate-onboarding-orb-breathe absolute top-1/2 left-1/2 w-[500px] h-[500px] rounded-full bg-[#1ebba2]/10 blur-[100px] motion-reduce:animate-none">
            </div>
            <div class="motion-safe:animate-onboarding-orb-breathe absolute top-1/2 right-1/2 w-[500px] h-[500px] rounded-full bg-[#1ebba2]/10 blur-[100px] motion-reduce:animate-none">
            </div>
          </div>
          <div class="relative z-10 w-full max-w-6xl mx-auto px-6 lg:px-8 pb-0">
            <div class={[
              "min-h-screen pt-4 transition-[opacity,transform] duration-700 ease-[cubic-bezier(0.2,0.8,0.2,1)] motion-reduce:transition-opacity motion-reduce:duration-500",
              if(present_onboarding_form_ui?,
                do:
                  "opacity-0 pointer-events-none motion-safe:translate-y-3 motion-safe:scale-[0.96] motion-reduce:translate-y-0 motion-reduce:scale-100",
                else: "opacity-100 translate-y-0 scale-100"
              )
            ]}>
              <%= if current_candidate do %>
                <Algora.Cloud.candidate_card {Map.merge(current_candidate, %{
                  anonymize: true,
                  # root_class: "h-[calc(100svh-8rem)] max-h-[52rem]",
                  tech_stack: [],
                  hide_badges?: true,
                  hide_scrollbars?: true
                })} />
              <% else %>
                <div class="min-h-[60vh]" aria-hidden="true"></div>
              <% end %>
            </div>
            <div
              :if={likes_reached_goal || deck_exhausted?}
              class={[
                "onboarding-form-overlay-scroll absolute inset-0 flex justify-center overflow-y-auto transition-opacity duration-700 ease-out",
                if(@onboarding_form_submitted, do: "items-center", else: "items-start"),
                if(present_onboarding_form_ui?,
                  do: "opacity-100",
                  else: "opacity-0 pointer-events-none"
                )
              ]}
            >
              <div class={[
                "relative z-10 w-full text-card-foreground px-6 lg:px-8 pt-4 sm:pt-8 pb-0 transition-[opacity,transform] duration-700 ease-[cubic-bezier(0.2,0.8,0.2,1)] motion-reduce:transition-opacity motion-reduce:duration-300",
                if(present_onboarding_form_ui?,
                  do: "opacity-100 motion-safe:translate-y-0 motion-safe:scale-100",
                  else:
                    "opacity-0 motion-safe:translate-y-6 motion-safe:scale-[0.97] motion-reduce:translate-y-0 motion-reduce:scale-100"
                )
              ]}>
                <%= if @onboarding_form_submitted do %>
                  <div class="relative flex w-full flex-col items-center justify-center text-center py-12 sm:py-16">
                    <div class="home-onboarding-sparks z-0" aria-hidden="true">
                      <span />
                      <span />
                      <span />
                      <span />
                      <span />
                      <span />
                      <span />
                      <span />
                    </div>
                    <div class="relative z-10 flex size-16 sm:size-20 items-center justify-center rounded-full bg-emerald-500/15 ring-2 ring-emerald-500/40 mb-6 motion-safe:animate-onboarding-success-icon motion-reduce:animate-none">
                      <.icon name="tabler-check" class="size-9 sm:size-11 text-emerald-400" />
                    </div>
                    <h2 class="relative z-10 text-2xl sm:text-3xl font-semibold leading-tight tracking-tight text-foreground motion-safe:animate-onboarding-line-in motion-safe:delay-100 motion-reduce:animate-none">
                      You're all set
                    </h2>
                    <p class="relative z-10 mt-2 max-w-md text-base text-muted-foreground leading-relaxed motion-safe:animate-onboarding-line-in motion-safe:delay-200 motion-reduce:animate-none">
                      Thanks for reaching out, we'll get in touch soon!
                    </p>
                  </div>
                <% else %>
                  <h2 class="text-2xl sm:text-3xl font-semibold leading-tight tracking-tight text-foreground motion-safe:animate-in motion-safe:fade-in motion-safe:slide-in-from-bottom-4 motion-safe:duration-500">
                    Get your top candidates
                  </h2>
                  <p class="mt-3 text-base text-muted-foreground motion-safe:animate-in motion-safe:fade-in motion-safe:slide-in-from-bottom-3 motion-safe:duration-500 motion-safe:delay-75">
                    You'll hear back from the Algora founders
                  </p>
                  <.form
                    for={@form}
                    id="onboarding-candidates-form"
                    phx-submit="submit"
                    class="mt-8 flex flex-col gap-8 motion-safe:animate-in motion-safe:fade-in motion-safe:slide-in-from-bottom-3 motion-safe:duration-500 motion-safe:delay-150"
                  >
                    <%!--
                      <div class="space-y-3">
                        <div class="block text-base sm:text-xl font-semibold leading-snug text-foreground">
                          Tech stack
                        </div>
                        <.TechStack
                          tech={Ecto.Changeset.get_field(@form.source, :tech_stack) || []}
                          socket={@socket}
                          form="form"
                          classes="-mt-2"
                        />
                      </div>
                      --%>
                    <input type="hidden" name={@form[:tech_stack].name} value="[]" />
                    <div class="motion-safe:animate-in motion-safe:fade-in motion-safe:slide-in-from-bottom-2 motion-safe:duration-500 motion-safe:delay-200">
                      <label
                        for={@form[:job_description].id}
                        class="block text-base sm:text-xl font-semibold leading-snug text-foreground mb-2"
                      >
                        Careers URL
                      </label>
                      <.input
                        field={@form[:job_description]}
                        class="px-3 py-3 !text-sm !sm:text-base sm:!leading-7 bg-white/5"
                        placeholder="https://company.com/careers"
                      />
                    </div>
                    <div class="grid grid-cols-1 gap-6 gap-y-8 motion-safe:animate-in motion-safe:fade-in motion-safe:slide-in-from-bottom-2 motion-safe:duration-500 motion-safe:delay-[260ms]">
                      <div>
                        <label
                          for={@form[:comp_range].id}
                          class="block text-base sm:text-xl font-semibold leading-snug text-foreground mb-2"
                        >
                          Compensation
                        </label>
                        <.input
                          field={@form[:comp_range]}
                          type="text"
                          placeholder="$175k-$330k + equity"
                          class="px-3 py-3 !text-sm !sm:text-base sm:!leading-7 bg-white/5"
                        />
                      </div>
                      <div>
                        <label
                          for={@form[:location].id}
                          class="block text-base sm:text-xl font-semibold leading-snug text-foreground mb-2"
                        >
                          Location
                        </label>
                        <.input
                          field={@form[:location]}
                          type="text"
                          placeholder="San Francisco"
                          class="px-3 py-3 !text-sm !sm:text-base sm:!leading-7 bg-white/5"
                        />
                      </div>
                    </div>
                    <div class="motion-safe:animate-in motion-safe:fade-in motion-safe:slide-in-from-bottom-2 motion-safe:duration-500 motion-safe:delay-[320ms]">
                      <label
                        for={@form[:email].id}
                        class="block text-base sm:text-xl font-semibold leading-snug text-foreground mb-2"
                      >
                        Your work email
                      </label>
                      <.input
                        field={@form[:email]}
                        placeholder="you@company.com"
                        class="px-3 py-3 !text-sm !sm:text-base sm:!leading-7 bg-white/5"
                      />
                    </div>
                    <%!-- <div class="grid grid-cols-3 gap-4 sm:gap-8 motion-safe:animate-in motion-safe:fade-in motion-safe:slide-in-from-bottom-2 motion-safe:duration-500 motion-safe:delay-[380ms]">
                      <%= for stat <- @stats1 do %>
                        <div>
                          <div class="text-2xl sm:text-3xl font-bold font-display text-foreground">
                            {stat.value}
                          </div>
                          <div class="text-xs sm:text-sm text-muted-foreground mt-1">
                            {stat.label}
                          </div>
                        </div>
                      <% end %>
                    </div> --%>
                  </.form>
                <% end %>
              </div>
            </div>
          </div>
        </section>
      </main>

      <%!-- Tinder action buttons: fixed dock, shown when candidate section is in view --%>
      <div
        :if={tinder_buttons_visible?}
        id="tinder-buttons"
        phx-hook="TinderButtons"
        phx-update="ignore"
        data-like-count={onboarding_likes(@liked_ids)}
        data-like-goal={onboarding_likes_goal()}
        class="fixed bottom-0 left-0 right-0 z-40 pb-6 sm:pb-8 pt-5 bg-gradient-to-t from-black via-black/80 to-transparent opacity-0 transition-opacity duration-500 pointer-events-none"
      >
        <div class="mx-auto flex w-full max-w-6xl gap-3 sm:gap-4 px-6 lg:px-8">
          <button
            class="pointer-events-auto flex flex-1 basis-0 flex-row items-center justify-center gap-2 rounded-2xl bg-red-950/60 border-2 border-red-500/50 hover:border-red-400 hover:bg-red-900/60 py-4 shadow-xl shadow-red-900/40 transition-[transform,box-shadow] duration-200 ease-out motion-safe:hover:scale-[1.02] motion-safe:active:scale-[0.97] disabled:opacity-60 disabled:pointer-events-none"
            phx-click="dislike_candidate"
            disabled={likes_reached_goal}
            aria-label="Skip candidate"
          >
            <.icon name="tabler-x" class="size-7 shrink-0 text-red-400 sm:size-8" />
            <span class="text-sm font-semibold text-red-400 tracking-wide">Skip</span>
          </button>
          <button
            class="pointer-events-auto flex flex-1 basis-0 flex-row items-center justify-center gap-3 rounded-2xl bg-emerald-950/60 border-2 border-emerald-500/50 hover:border-emerald-400 hover:bg-emerald-900/60 py-4 shadow-xl shadow-emerald-900/40 transition-[transform,box-shadow] duration-200 ease-out motion-safe:hover:scale-[1.02] motion-safe:active:scale-[0.97] disabled:opacity-60 disabled:pointer-events-none"
            phx-click="like_candidate"
            disabled={likes_reached_goal}
            aria-label="Like candidate"
          >
            <% fill_pct = onboarding_fill_pct(@liked_ids) %>
            <% curve_bottom_px = onboarding_curve_bottom_px(@liked_ids) %>
            <div class="onboarding-heart-wrap">
              <div class="onboarding-heart">
                <div class="onboarding-heart-tank" style={"height: #{fill_pct}%;"}></div>
                <svg
                  class="onboarding-heart-curve"
                  viewBox="0 24 150 28"
                  preserveAspectRatio="none"
                  shape-rendering="auto"
                  style={"bottom: #{curve_bottom_px}px;"}
                >
                  <defs>
                    <path
                      id="onboarding-heart-gentle-wave"
                      d="M-160 44c30 0 58-18 88-18s 58 18 88 18 58-18 88-18 58 18 88 18 v44h-352z"
                    />
                  </defs>
                  <g>
                    <use
                      href="#onboarding-heart-gentle-wave"
                      x="48"
                      y="0"
                      fill="rgba(16, 185, 129, 0.5)"
                    />
                    <use
                      href="#onboarding-heart-gentle-wave"
                      x="48"
                      y="1"
                      fill="rgba(52, 211, 153, 0.35)"
                    />
                    <use
                      href="#onboarding-heart-gentle-wave"
                      x="48"
                      y="2"
                      fill="rgba(5, 150, 105, 1)"
                    />
                  </g>
                </svg>
              </div>
              <svg class="onboarding-heart-clip-defs" aria-hidden="true">
                <clipPath id="onboarding-heart-clip-path" clipPathUnits="objectBoundingBox">
                  <path d="M0.373,0.967 S0.616,0.866,0.768,0.644 S0.912,0.107,0.739,0 S0.373,0.108,0.373,0.108 S0.166,-0.113,0,-0.002 S-0.159,0.432,-0.021,0.644 S0.373,0.967,0.373,0.967">
                  </path>
                </clipPath>
              </svg>
            </div>
            <span
              id="onboarding-heart-label"
              class="text-sm font-semibold text-emerald-400 tracking-wide"
            >
              Like
            </span>
          </button>
        </div>
      </div>

      <%!-- Onboarding form submit: fixed dock, same chrome as like/dislike --%>
      <div
        :if={present_onboarding_form_ui? && !@onboarding_form_submitted}
        id="onboarding-form-submit-dock"
        class="fixed bottom-0 left-0 right-0 z-40 pb-6 sm:pb-8 pt-5 bg-gradient-to-t from-black via-black/80 to-transparent pointer-events-none"
      >
        <div class="mx-auto flex w-full max-w-6xl gap-3 sm:gap-4 px-6 lg:px-8 items-stretch justify-center">
          <button
            type="submit"
            form="onboarding-candidates-form"
            class="pointer-events-auto flex w-full flex-row items-center justify-center gap-2 rounded-2xl bg-emerald-950/60 border-2 border-emerald-500/50 hover:border-emerald-400 hover:bg-emerald-900/60 py-4 shadow-xl shadow-emerald-900/40 transition-[transform,box-shadow] duration-200 ease-out motion-safe:hover:scale-[1.02] motion-safe:active:scale-[0.97] sm:gap-3"
          >
            <.icon name="tabler-send" class="size-6 shrink-0 text-emerald-400 sm:size-7" />
            <span class="text-base font-semibold text-emerald-400 tracking-wide sm:text-lg">
              Receive your candidates
            </span>
          </button>
        </div>
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
    tech_stack =
      Jason.decode!(params["tech_stack"] || "[]") ++
        case String.trim(params["tech_stack_input"] || "") do
          "" -> []
          tech_stack_input -> String.split(tech_stack_input, ",")
        end

    params = Map.put(params, "tech_stack", tech_stack)

    case %Form{} |> Form.changeset(params) |> Ecto.Changeset.apply_action(:save) do
      {:ok, data} ->
        welcome_attrs =
          Map.merge(Map.from_struct(data), %{
            liked_ids: home_onboarding_feedback_user_ids(socket.assigns.liked_ids),
            disliked_ids: home_onboarding_feedback_user_ids(socket.assigns.disliked_ids)
          })

        Algora.Cloud.create_welcome_task(welcome_attrs)

        {:noreply, assign(socket, :onboarding_form_submitted, true)}

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
    socket =
      socket
      |> LocalStore.restore(token)
      |> assign(:liked_ids, [])
      |> assign(:show_onboarding_form, false)
      |> assign(:transitioning_to_onboarding_form, false)
      |> assign(:onboarding_form_submitted, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("start_onboarding", _params, socket) do
    if socket.assigns.onboarding_started do
      {:noreply, socket}
    else
      {:noreply, assign(socket, :onboarding_started, true)}
    end
  end

  @impl true
  def handle_event("like_candidate", _params, socket) do
    current = Enum.at(socket.assigns.candidates_data, socket.assigns.current_candidate_index)
    user_id = current && current.candidate.match.user.id
    liked_ids = if user_id, do: [user_id | socket.assigns.liked_ids], else: socket.assigns.liked_ids
    likes_reached_goal = onboarding_goal_reached?(liked_ids)

    socket = assign(socket, :liked_ids, liked_ids)

    cond do
      likes_reached_goal && socket.assigns.transitioning_to_onboarding_form ->
        {:noreply, socket}

      likes_reached_goal ->
        Process.send_after(self(), :show_onboarding_form, 450)
        {:noreply, assign(socket, :transitioning_to_onboarding_form, true)}

      true ->
        {:noreply, assign(socket, :current_candidate_index, socket.assigns.current_candidate_index + 1)}
    end
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

  @impl true
  def handle_info(:show_onboarding_form, socket) do
    {:noreply,
     socket
     |> assign(:show_onboarding_form, true)
     |> assign(:transitioning_to_onboarding_form, false)}
  end

  # Session stores lowercase ISO code from AlgoraWeb.Analytics (IPinfo Lite). Prefer a readable
  # country name; ConnectCountries covers Stripe-supported codes (fallback: uppercase code).
  defp location_prefill(client_timezone, country_code) do
    us? =
      is_binary(country_code) and String.downcase(String.trim(country_code)) == "us"

    cond do
      us? and client_timezone == "America/Los_Angeles" ->
        "San Francisco"

      us? and client_timezone == "America/New_York" ->
        "New York"

      us? and is_binary(client_timezone) and String.starts_with?(client_timezone, "America/") ->
        "United States"

      true ->
        location_prefill_from_country(country_code)
    end
  end

  defp location_prefill_from_country(nil), do: ""

  defp location_prefill_from_country(code) when is_binary(code) do
    code
    |> String.trim()
    |> case do
      "" -> ""
      c -> ConnectCountries.from_code(String.upcase(c))
    end
  end

  defp visitor_ipinfo_debug(nil, current_country, client_timezone) do
    %{
      "note" =>
        "No ipinfo in session yet (e.g. session from before this payload was stored). current_country from session:",
      "current_country" => current_country,
      "client_timezone" => client_timezone
    }
  end

  defp visitor_ipinfo_debug(data, _current_country, client_timezone) when is_map(data) do
    Map.put(data, "client_timezone", client_timezone)
  end

  # Same IANA zone as Timezone.svelte / assets/js/liveSocket `params.timezone`.
  defp read_client_timezone(socket) do
    case get_connect_params(socket) do
      %{"timezone" => tz} when is_binary(tz) and tz != "" -> tz
      _ -> nil
    end
  end

  defp assign_user_applications(socket) do
    user_applications =
      if socket.assigns[:current_user] do
        Jobs.list_user_applications(socket.assigns.current_user)
      else
        MapSet.new()
      end

    assign(socket, :user_applications, user_applications)
  end

  defp onboarding_started?(params) do
    Map.has_key?(params, "go")
  end

  defp onboarding_likes_goal, do: 3

  defp home_onboarding_feedback_user_ids(ids) when is_list(ids) do
    ids
    |> Enum.reverse()
    |> Enum.uniq()
  end

  defp deck_exhausted?(index, candidates_data) when is_list(candidates_data) do
    candidates_data != [] and match?(nil, Enum.at(candidates_data, index))
  end

  defp onboarding_goal_reached?(liked_ids), do: onboarding_likes(liked_ids) >= onboarding_likes_goal()

  defp onboarding_likes(liked_ids) do
    liked_ids
    |> Enum.uniq()
    |> length()
    |> min(onboarding_likes_goal())
  end

  defp onboarding_fill_pct(liked_ids) do
    trunc(onboarding_likes(liked_ids) / onboarding_likes_goal() * 100)
  end

  defp onboarding_curve_bottom_px(liked_ids) do
    fill_pct = onboarding_fill_pct(liked_ids)
    max(-10, trunc(fill_pct * 0.24) - 10)
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
        person_name: "Erfan Al-Hossami",
        person_avatar: "https://algora.io/storage/avatars/taisazero.jpeg",
        person_title: "Applied AI Engineer",
        bg_image: "https://algora.io/storage/avatars/coderabbit/samhayes.jpg",
        bg_intrinsic_width: 400,
        bg_intrinsic_height: 400,
        bg_aspect_class: "aspect-square",
        theme_color: "#F97316",
        overlay_color: "rgba(67, 20, 7, 0.6)",
        description: "AI code reviews",
        series: "B",
        raised: "$60M",
        valuation: "$550M",
        testimonial:
          "Within one week of onboarding, we started interviewing qualified candidates who joined CodeRabbit in San Francisco.",
        testimonial_author: "Sam Hayes · Talent Acquisition Lead",
        testimonial_logo: "/images/wordmarks/coderabbit.svg",
        testimonial_logo_class: "h-7 md:h-8"
      },
      %{
        special: true,
        company_name: "ComfyUI",
        company_avatar: "https://avatars.githubusercontent.com/u/166579949?v=4",
        person_name: "Matt Miller",
        person_avatar: "https://algora.io/storage/avatars/MillerMedia.jpeg",
        person_title: "Backend Engineer",
        bg_image: "https://algora.io/storage/avatars/comfy/robinjhuang.jpg",
        bg_intrinsic_width: 400,
        bg_intrinsic_height: 400,
        bg_aspect_class: "aspect-square",
        theme_color: "#BEF264",
        overlay_color: "rgba(117, 125, 14, 0.65)",
        description: "Open source OS for creative AI",
        series: "B",
        raised: "$30M",
        valuation: "$500M",
        testimonial:
          ~s(To build AI for Hollywood, we need engineers with experience in creative media exactly like <a href="https://www.linkedin.com/feed/update/urn:li:activity:7453498218417557504/" class="underline hover:text-white underline-offset-2" target="_blank" rel="noopener noreferrer">Matt</a>. We're super happy to work together.),
        testimonial_html: true,
        testimonial_author: "Robin Huang · Co-Founder",
        testimonial_logo: "/images/wordmarks/comfy.svg",
        testimonial_logo_class: "h-5 md:h-6"
      },
      %{
        special: true,
        company_name: "TextQL",
        company_avatar: "https://algora.io/storage/avatars/textql.jpeg",
        person_name: "Christian Lim",
        person_avatar: "https://avatars.githubusercontent.com/u/2482353?v=4",
        person_title: "Member of Technical Staff",
        bg_image: "https://algora.io/storage/avatars/textql/ethanding.jpg",
        bg_intrinsic_width: 400,
        bg_intrinsic_height: 400,
        bg_aspect_class: "aspect-square",
        theme_color: "#2DD4BF",
        overlay_color: "rgba(8, 69, 51, 0.75)",
        description: "Agentic analytics for enterprises",
        series: "A",
        raised: "$17M",
        valuation: nil,
        testimonial:
          ~s(Our newest hire <a href="https://www.linkedin.com/posts/theethanding_trade-alert-textql-has-signed-former-activity-7434276471830904832-fGHZ?utm_source=share&utm_medium=member_desktop&rcm=ACoAAB4_M5IB8eXlIdyyQIJr1-gfNJj8jwIuXoQ" class="underline hover:text-white underline-offset-2" target="_blank" rel="noopener noreferrer">Christian</a> spent 6 years at Google, taught at MIT and worked as a quant at Two Sigma. This is exactly the profile we asked.),
        testimonial_html: true,
        testimonial_author: "Ethan Ding · Co-Founder & CEO",
        testimonial_logo: "/images/wordmarks/textql.svg",
        testimonial_logo_class: "h-4 md:h-5"
      }
    ]
  end

  defp hire_testimonial_markup(%{testimonial_html: true} = hire), do: Phoenix.HTML.raw(hire.testimonial)
  defp hire_testimonial_markup(hire), do: hire.testimonial

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
          screenshot?: false,
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
