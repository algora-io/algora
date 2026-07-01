defmodule AlgoraWeb.HomeLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

  import Ecto.Changeset

  alias Algora.Matches
  alias Algora.Settings
  alias AlgoraWeb.Components.Header

  defmodule Form do
    @moduledoc false
    use Ecto.Schema

    @primary_key false
    @derive {Jason.Encoder,
             only: [
               :email,
               :job_description,
               :candidate_description,
               :comp_range,
               :location,
               :location_type,
               :hire_type,
               :tech_stack
             ]}
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
  def mount(_params, _session, socket) do
    case socket.assigns[:current_user] do
      %{handle: handle} = user when is_binary(handle) ->
        {:ok, redirect(socket, to: AlgoraWeb.UserAuth.signed_in_path(user))}

      _ ->
        candidate_ids = Settings.get_home_carousel_candidate_ids()

        candidates_data =
          candidate_ids
          |> Enum.map(&load_candidate_data/1)
          |> Enum.reject(&is_nil/1)

        socket =
          socket
          |> assign(:page_title, "Algora - Hire the top 1% open source engineers")
          |> assign(:page_title_suffix, "")
          |> assign(:page_image, "#{AlgoraWeb.Endpoint.url()}/images/og/home.png")
          |> assign(:hires, hires())
          |> assign(:form, to_form(Form.changeset(%Form{}, %{tech_stack: []})))
          |> assign(:candidates_data, candidates_data)

        {:ok, socket}
    end
  end

  @impl true
  def handle_event("tech_stack_changed", %{"tech_stack" => tech_stack}, socket) do
    changeset = Form.changeset(socket.assigns.form.source, %{tech_stack: tech_stack})
    {:noreply, assign(socket, :form, to_form(changeset))}
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
        Algora.Cloud.create_welcome_task(data)

        {:noreply, put_flash(socket, :info, "Thanks for submitting your JD, you'll hear back soon!")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative lg:min-h-[100dvh] lg:flex lg:flex-col">
      <div class="pointer-events-none fixed inset-0 z-0 overflow-hidden bg-black" aria-hidden="true">
        <div
          class="absolute inset-0"
          style="background-image: radial-gradient(circle, rgba(255,255,255,0.10) 1px, transparent 1px); background-size: 28px 28px;"
        >
        </div>
      </div>

      <main class="relative z-10 bg-transparent lg:flex-1 lg:min-h-0 lg:flex lg:flex-col">
        <section id="home-hero-section" class="flex flex-col lg:min-h-0 lg:flex-1 lg:overflow-hidden">
          <div id="home-top-navbar" class="relative z-10 w-full shrink-0 bg-black overflow-hidden">
            <Header.header overlay={false} class="max-w-6xl w-full bg-black" />
          </div>
          <div class="flex-1 w-full container mx-auto px-6 lg:px-8 flex flex-col min-h-[calc(100dvh-5.25rem)]">
            <div class="flex-1 flex flex-col justify-center pb-4 xl:pb-12 w-full min-h-0 lg:overscroll-y-contain">
              <h1 class="text-2xl min-[412px]:text-[1.75rem] sm:text-[2.5rem]/[3rem] md:text-[3.5rem]/[4rem] lg:text-[5.2rem]/[5.5rem] xl:text-[5.2rem]/[5.7rem] font-black tracking-tight text-foreground font-display text-center">
                Open source <br class="hidden" />
                <span class="text-emerald-400">tech recruiting</span>
              </h1>
              <p class="mt-2 xl:mt-4 text-[0.9rem]/[1.4rem] min-[412px]:text-base md:text-lg lg:text-[1.65rem]/[2.0rem] xl:text-[1.65rem]/[2.15rem] leading-6 font-medium text-foreground text-center">
                Connecting the most prolific open source maintainers & contributors with their next jobs
              </p>
              <div class="w-full mt-4 lg:mt-8 xl:mt-12 2xl:mt-20 grid grid-cols-1 gap-6 sm:gap-4 lg:grid-cols-3 max-w-6xl mx-auto px-6 lg:px-8">
                <%= for hire <- @hires do %>
                  <div
                    class="relative h-full min-h-[20rem] sm:min-h-[28rem]"
                    style={"--hire-theme: #{hire.theme_color}"}
                  >
                    <div
                      class="relative h-full overflow-hidden rounded-xl border-2 border-white/30 shadow-xl shadow-white/10"
                      style={"background-color: #{hire.overlay_color}"}
                    >
                      <div id={"hire-bg-#{hire.company_name}"} phx-update="ignore">
                        <img
                          src={hire.bg_image}
                          alt=""
                          style="object-position: 0% 0%;"
                          class="absolute inset-0 size-full object-cover grayscale opacity-0 transition-opacity duration-700"
                          onload="this.classList.remove('opacity-0')"
                        />
                      </div>

                      <div
                        class="absolute inset-0 mix-blend-multiply"
                        style={"background-color: #{hire.overlay_color}"}
                      >
                      </div>
                      <div class="absolute inset-x-0 bottom-0 h-64 bg-gradient-to-t from-black to-transparent">
                      </div>
                      <div class="absolute inset-x-0 top-0 h-64 bg-gradient-to-b from-black to-transparent">
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
          </div>
        </section>

        <div class="flex-1 p-4 pt-16 md:pt-24 md:py-4 flex flex-col overflow-hidden container w-full mx-auto">
          <div class="text-center mb-4 md:mb-8 px-2">
            <h2 class="text-3xl sm:text-4xl md:text-6xl font-black tracking-tight text-foreground font-display">
              Get your top candidates
            </h2>
            <p class="mt-3 text-base sm:text-lg font-medium text-muted-foreground max-w-4xl mx-auto">
              Tell us who you're looking for and we'll send handpicked engineers ready to interview
            </p>
          </div>
          <div class="w-full flex flex-col-reverse lg:flex-row gap-6 lg:gap-12 items-center px-2">
            <div class="shrink-0 w-full lg:w-[30%] text-left">
              <.form for={@form} phx-submit="submit" class="flex flex-col gap-4">
                <div>
                  <label class="block text-sm font-semibold text-foreground mb-2">
                    Tech stack
                  </label>
                  <.TechStack
                    tech={Ecto.Changeset.get_field(@form.source, :tech_stack) || []}
                    socket={@socket}
                    form="form"
                    classes="-mt-2"
                  />
                </div>
                <.input
                  field={@form[:job_description]}
                  type="textarea"
                  label="Job description / careers URL"
                  rows="3"
                  class="resize-none"
                  placeholder="Tell us about the role, requirements, ideal candidate..."
                />
                <div class="space-y-2">
                  <label class="block text-sm font-medium text-foreground">
                    Commitment
                  </label>
                  <div class="grid grid-cols-2 gap-3" phx-update="ignore" id="hire-type-radio-group">
                    <label class="group relative flex cursor-pointer rounded-lg px-3 py-2.5 shadow-sm focus:outline-none border bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10 border-input has-[:checked]:border-primary has-[:checked]:bg-primary/10">
                      <input
                        type="radio"
                        class="sr-only"
                        name={@form[:hire_type].name}
                        value="full_time"
                        checked={get_field(@form.source, :hire_type) == "full_time"}
                      />
                      <div class="flex items-center gap-2">
                        <.icon name="tabler-briefcase" class="h-5 w-5 text-primary shrink-0" />
                        <span class="text-sm text-foreground">
                          Full-time
                        </span>
                      </div>
                    </label>
                    <label class="group relative flex cursor-pointer rounded-lg px-3 py-2.5 shadow-sm focus:outline-none border bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10 border-input has-[:checked]:border-primary has-[:checked]:bg-primary/10">
                      <input
                        type="radio"
                        class="sr-only"
                        name={@form[:hire_type].name}
                        value="contract"
                        checked={get_field(@form.source, :hire_type) == "contract"}
                      />
                      <div class="flex items-center gap-2">
                        <.icon name="tabler-clock" class="h-5 w-5 text-primary shrink-0" />
                        <span class="text-sm text-foreground">
                          Contract
                        </span>
                      </div>
                    </label>
                  </div>
                </div>
                <div class="space-y-2">
                  <label class="block text-sm font-medium text-foreground">
                    Location type
                  </label>
                  <div
                    class="grid grid-cols-3 gap-3"
                    phx-update="ignore"
                    id="location-type-radio-group"
                  >
                    <label class="group relative flex cursor-pointer rounded-lg px-3 py-2.5 shadow-sm focus:outline-none border bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10 border-input has-[:checked]:border-primary has-[:checked]:bg-primary/10">
                      <input
                        type="radio"
                        class="sr-only"
                        name={@form[:location_type].name}
                        value="onsite"
                        checked={get_field(@form.source, :location_type) == "onsite"}
                      />
                      <div class="flex items-center gap-2">
                        <.icon name="tabler-building" class="h-5 w-5 text-primary shrink-0" />
                        <span class="text-sm text-foreground">
                          Onsite
                        </span>
                      </div>
                    </label>
                    <label class="group relative flex cursor-pointer rounded-lg px-3 py-2.5 shadow-sm focus:outline-none border bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10 border-input has-[:checked]:border-primary has-[:checked]:bg-primary/10">
                      <input
                        type="radio"
                        class="sr-only"
                        name={@form[:location_type].name}
                        value="hybrid"
                        checked={get_field(@form.source, :location_type) == "hybrid"}
                      />
                      <div class="flex items-center gap-2">
                        <.icon name="tabler-arrows-shuffle" class="h-5 w-5 text-primary shrink-0" />
                        <span class="text-sm text-foreground">
                          Hybrid
                        </span>
                      </div>
                    </label>
                    <label class="group relative flex cursor-pointer rounded-lg px-3 py-2.5 shadow-sm focus:outline-none border bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10 border-input has-[:checked]:border-primary has-[:checked]:bg-primary/10">
                      <input
                        type="radio"
                        class="sr-only"
                        name={@form[:location_type].name}
                        value="remote"
                        checked={get_field(@form.source, :location_type) == "remote"}
                      />
                      <div class="flex items-center gap-2">
                        <.icon name="tabler-home" class="h-5 w-5 text-primary shrink-0" />
                        <span class="text-sm text-foreground">
                          Remote
                        </span>
                      </div>
                    </label>
                  </div>
                </div>
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
                  <.input
                    field={@form[:comp_range]}
                    type="text"
                    label="Compensation"
                    placeholder="$175k-$330k + equity"
                  />
                  <.input
                    field={@form[:location]}
                    type="text"
                    label="Location"
                    placeholder="San Francisco"
                  />
                </div>
                <.input
                  field={@form[:email]}
                  type="email"
                  label="Your work email"
                  placeholder="you@company.com"
                />
                <div class="flex flex-col gap-3 mt-2">
                  <.button class="w-full" type="submit">Receive your candidates</.button>
                </div>
              </.form>
            </div>
            <div
              :if={length(@candidates_data) > 0}
              class="shrink-0 flex flex-col gap-3 w-full lg:w-[70%] lg:pr-12"
            >
              <div
                id="candidate-carousel-org"
                phx-hook="CandidateCarousel"
                class="relative w-full"
                phx-update="ignore"
              >
                <%= for {candidate_data, index} <- Enum.with_index(@candidates_data) do %>
                  <div
                    data-carousel-item={index}
                    class={"transition-opacity duration-500 #{if index == 0, do: "opacity-100", else: "opacity-0 absolute inset-0"}"}
                  >
                    <Algora.Cloud.candidate_card {Map.merge(candidate_data, %{anonymize: true, root_class: "h-[33rem] lg:h-[39rem]", fade_to_black?: false, tech_stack: [], hide_badges?: true, hide_scrollbars?: true})} />
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-black mt-12 md:mt-28">
          <AlgoraWeb.Components.Footer.footer class="pt-12 md:pt-28" />
        </div>
      </main>
    </div>
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
        overlay_color: "rgba(67, 20, 7, 0.65)",
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
        overlay_color: "rgba(117, 123, 65, 0.65)",
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
        company_name: "Firecrawl (YC S22)",
        company_avatar: "/images/wordmarks/firecrawl.svg",
        person_name: "Gergő Móricz",
        person_avatar: "https://avatars.githubusercontent.com/u/66118807?v=4",
        person_title: "Staff Software Engineer",
        bg_image: "https://algora.io/storage/avatars/calebpeffer.jpeg",
        bg_intrinsic_width: 400,
        bg_intrinsic_height: 400,
        bg_aspect_class: "aspect-square",
        theme_color: "#fe4900",
        overlay_color: "rgba(205, 121, 99, 0.65)",
        description: "Web context API for AI agents",
        series: "A",
        raised: "$14.5M",
        valuation: nil,
        testimonial:
          ~s(We met Gergő through Algora and couldn't be happier. He's been working with us for two years now and he's a core member of our team.),
        testimonial_html: true,
        testimonial_author: "Caleb Peffer · Co-Founder & CEO",
        testimonial_logo: "/images/wordmarks/firecrawl2.svg",
        testimonial_logo_class: "h-4 md:h-5"
      }
    ]
  end

  defp hire_testimonial_markup(%{testimonial_html: true} = hire), do: Phoenix.HTML.raw(hire.testimonial)
  defp hire_testimonial_markup(hire), do: hire.testimonial

  defp load_candidate_data(match_id) do
    case Matches.get_job_match_by_id(match_id) do
      nil ->
        nil

      match ->
        match = Algora.Repo.preload(match, job_posting: :user)
        user = match.user

        contributions = Algora.Workspace.list_user_contributions([user.id], exclude_personal: false, display_all: true)

        contributions_map = %{user.id => contributions}

        language_contributions_map = Algora.Cloud.list_language_contributions_batch([user.id])

        heatmaps_map =
          [user.id]
          |> Algora.Cloud.list_heatmaps()
          |> Map.new(fn heatmap -> {heatmap.user_id, heatmap.data} end)

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

  defp build_interviews_map(matches) do
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
end
