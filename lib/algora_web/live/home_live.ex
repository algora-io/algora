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
  alias AlgoraWeb.Forms.ChallengeForm

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
      %{label: "Full-time SWEs Hired", value: "30+"},
      %{label: "1st Year Retention", value: "100%"},
      %{label: "Happy Customers", value: "100+"}
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
        {:ok,
         socket
         |> assign(:page_title, "Algora - Hire the top 1% open source engineers")
         |> assign(:page_title_suffix, "")
         |> assign(:page_image, "#{AlgoraWeb.Endpoint.url()}/images/og/home.png")
         |> assign(:screenshot?, not is_nil(params["screenshot"]))
         |> assign(:stats1, stats1)
         |> assign(:stats2, stats2)
         |> assign(:jobs_by_user, jobs_by_user)
         |> assign(:orgs_with_stats, orgs_with_stats)
         |> assign(:hires1, hires1())
         |> assign(:hires2, hires2())
         |> assign(:show_challenge_drawer, false)
         |> assign(:challenge_form, to_form(ChallengeForm.changeset(%ChallengeForm{}, %{})))
         |> assign(:tech_stack, [])
         |> assign(:candidates_data, candidates_data)
         |> assign(:carousel_items, carousel_items)
         |> assign(:form, to_form(Form.changeset(%Form{}, %{tech_stack: []})))
         |> assign_user_applications()
         |> assign_events()}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @screenshot? do %>
        <div class="-mt-24" />
      <% else %>
        <Header.header class="container fixed top-0 left-0 right-0 z-50 bg-black" />
      <% end %>

      <main class="bg-black relative">
        <div class="flex flex-col lg:grid lg:grid-cols-[1fr_28rem] lg:gap-2 md:gap-8 lg:max-w-[88rem] lg:w-full lg:mx-auto">
          <div class="order-1 lg:order-1 lg:col-start-1 lg:min-w-[860px]">
            <section class="relative isolate min-h-[calc(100vh)]">
              <div class="h-full mx-auto px-6 lg:px-8 flex flex-col items-center justify-center pt-20 lg:pt-24 2xl:pt-32 pb-12">
                <div class="h-full mx-auto lg:mx-0 flex lg:max-w-none items-center justify-center text-center w-full">
                  <div class="w-full flex flex-col lg:items-start text-left lg:text-left">
                    <h1 class="text-2xl min-[412px]:text-[1.75rem] sm:text-[2.5rem]/[3rem] md:text-[3.5rem]/[4rem] lg:text-[3rem]/[3.5rem] xl:text-[4rem]/[4.5rem] font-semibold tracking-tight text-foreground">
                      Open source <br class="hidden" />
                      <span class="text-emerald-400">tech recruiting</span>
                    </h1>
                    <p class="mt-2 text-[0.9rem]/[1.4rem] min-[412px]:text-base md:text-lg xl:text-lg 2xl:text-xl leading-6 font-medium text-foreground">
                      Connecting the most prolific open source maintainers & contributors with their next jobs
                    </p>
                    <div class="flex items-center justify-start gap-3 lg:gap-12 overflow-x-auto scrollbar-thin py-4">
                      <img
                        src="/images/wordmarks/coderabbit.svg"
                        alt="CodeRabbit"
                        class="h-5 sm:h-6 shrink-0 transition-all"
                      />
                      <img
                        src="/images/wordmarks/comfy.svg"
                        alt="Comfy"
                        class="h-3.5 sm:h-5 shrink-0 transition-all"
                      />
                      <img
                        src="/images/wordmarks/lovable.svg"
                        alt="Lovable"
                        class="h-3 sm:h-4 shrink-0 transition-all"
                      />
                      <div class="hidden min-[412px]:flex items-center transition-all">
                        <img
                          src="/images/wordmarks/firecrawl.svg"
                          alt="Firecrawl"
                          class="h-6 sm:h-7 shrink-0"
                        />
                        <img
                          src="/images/wordmarks/firecrawl2.svg"
                          alt="Firecrawl2"
                          class="h-3 sm:h-4 shrink-0"
                        />
                      </div>
                    </div>
                    <div :if={length(@carousel_items) > 0} class="mt-4 w-full">
                      <div
                        id="candidate-carousel-home"
                        phx-hook="CandidateCarousel"
                        class="relative w-full"
                      >
                        <%= for {item, index} <- Enum.with_index(@carousel_items) do %>
                          <div
                            data-carousel-item={index}
                            class={"transition-opacity duration-500 #{if index == 0, do: "opacity-100", else: "opacity-0 absolute inset-0"}"}
                          >
                            <%= case item do %>
                              <% {:candidate, candidate_data} -> %>
                                <Algora.Cloud.candidate_card {Map.merge(candidate_data, %{anonymize: true, root_class: "h-[38rem] lg:h-[31rem]", tech_stack: [], hide_badges?: true, hide_scrollbars?: true})} />
                              <% {:job_page, %{url: url, alt: alt}} -> %>
                                <div class="h-[38rem] lg:h-[31rem] flex items-center justify-center bg-card rounded-xl border overflow-hidden">
                                  <img
                                    src={url}
                                    alt={alt}
                                    class="w-full h-full object-cover"
                                    loading="lazy"
                                  />
                                </div>
                            <% end %>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </section>
          </div>

          <div class="order-2 lg:sticky lg:top-0 lg:order-2 lg:col-start-2 lg:row-start-1 lg:self-start px-6 lg:px-0 pb-12 lg:pb-8 lg:pt-24 2xl:pt-32 overflow-y-auto lg:max-h-screen scrollbar-thin">
            <div class="text-left">
              <div class="rounded-xl bg-card text-card-foreground shadow-2xl border">
                <div class="p-6 lg:p-8">
                  <h2 class="text-2xl lg:text-3xl font-semibold leading-7 text-foreground">
                    View your candidates
                  </h2>
                  <p class="pt-2 text-sm text-muted-foreground">
                    Share <span class="hidden lg:inline">your</span>
                    JD to receive your candidates within hours
                  </p>

                  <.form for={@form} phx-submit="submit" class="mt-6 flex flex-col gap-3">
                    <div>
                      <label class="block text-sm font-semibold text-foreground mb-2">
                        Hire type
                      </label>
                      <div
                        class="grid grid-cols-2 gap-4"
                        phx-update="ignore"
                        id="hire-type-radio-group"
                      >
                        <label class="group relative flex cursor-pointer rounded-lg px-3 py-2 shadow-sm focus:outline-none border bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10 border-input has-[:checked]:border-primary has-[:checked]:bg-primary/10">
                          <input
                            type="radio"
                            class="sr-only"
                            name={@form[:hire_type].name}
                            value="full_time"
                            checked={get_field(@form.source, :hire_type) == "full_time"}
                          />
                          <div class="flex items-center gap-3">
                            <.icon name="tabler-briefcase" class="h-6 w-6 text-primary shrink-0" />
                            <span class="text-sm text-foreground">
                              Full-time
                            </span>
                          </div>
                        </label>
                        <label class="group relative flex cursor-pointer rounded-lg px-3 py-2 shadow-sm focus:outline-none border bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10 border-input has-[:checked]:border-primary has-[:checked]:bg-primary/10">
                          <input
                            type="radio"
                            class="sr-only"
                            name={@form[:hire_type].name}
                            value="contract"
                            checked={get_field(@form.source, :hire_type) == "contract"}
                          />
                          <div class="flex items-center gap-3">
                            <.icon name="tabler-clock" class="h-6 w-6 text-primary shrink-0" />
                            <span class="text-sm text-foreground">
                              Contract
                            </span>
                          </div>
                        </label>
                      </div>
                    </div>

                    <div>
                      <label class="block text-sm font-semibold text-foreground mb-2">
                        Tech stack
                      </label>
                      <.TechStack tech={@tech_stack} socket={@socket} form="form" classes="-mt-2" />
                    </div>

                    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
                      <.input
                        field={@form[:location]}
                        type="text"
                        label="Location"
                        placeholder="San Francisco"
                      />
                      <.input
                        field={@form[:comp_range]}
                        type="text"
                        label="Compensation"
                        placeholder="$175k-$330k + equity"
                      />
                    </div>

                    <.input
                      field={@form[:job_description]}
                      type="textarea"
                      label="Job description / careers URL"
                      rows="3"
                      placeholder="Tell us about the role, requirements, ideal candidate..."
                    />

                    <.input
                      field={@form[:email]}
                      type="email"
                      label="Work email"
                      placeholder="you@company.com"
                    />
                    <div class="flex flex-col gap-4">
                      <.button class="w-full">Receive your candidates</.button>
                    </div>
                  </.form>
                </div>
              </div>
            </div>
          </div>

          <div class="order-3 lg:order-1 lg:col-start-1">
            <div class="py-16 sm:py-24 relative">
              <div class="">
                <div class="z-10 relative overflow-hidden px-6 py-20 sm:px-10 sm:py-36 md:px-12 lg:px-20 dark:shadow-none dark:after:pointer-events-none dark:after:absolute dark:after:inset-0 dark:after:inset-ring dark:after:inset-ring-white/10 dark:after:sm:rounded-3xl">
                  <img
                    src="https://algora.io/storage/avatars/coderabbit/sam-hayes-85a0ba25.jpg"
                    alt=""
                    class="absolute inset-0 size-full object-cover object-top grayscale"
                  />
                  <div class="absolute inset-0 bg-orange-950/60 mix-blend-multiply"></div>
                  <div class="absolute inset-0 bg-gradient-to-t from-transparent from-[97%] to-black">
                  </div>
                  <div class="absolute inset-0 bg-gradient-to-b from-transparent from-[97%] to-black">
                  </div>
                  <div class="absolute hidden lg:block inset-0 bg-gradient-to-r from-transparent from-[97%] to-black">
                  </div>
                  <div class="absolute hidden lg:block inset-0 bg-gradient-to-l from-transparent from-[97%] to-black">
                  </div>

                  <div class="relative mx-auto max-w-2xl lg:mx-0">
                    <img src="/images/wordmarks/coderabbit.svg" alt="CodeRabbit" class="h-12 w-auto" />
                    <figure>
                      <blockquote class="mt-6 text-lg font-semibold text-white sm:text-xl/8">
                        <p>
                          "Within one week of onboarding, we started interviewing qualified candidates interested to join CodeRabbit in San Francisco."
                        </p>
                      </blockquote>
                      <figcaption class="mt-6 text-base text-white dark:text-gray-200">
                        <div class="font-semibold">Sam Hayes</div>
                        <div class="mt-1">Talent Acquisition Lead</div>
                      </figcaption>
                    </figure>
                  </div>
                </div>
              </div>
            </div>

            <section class="relative isolate py-8 sm:py-20">
              <div class="mx-auto px-6 lg:px-8 pt-24 xl:pt-0">
                <h2 class="font-display text-[2rem] font-semibold tracking-tight text-foreground sm:text-6xl sm:mb-4 text-center sm:text-left">
                  Hire with Confidence
                </h2>
                <div class="flex flex-col">
                  <div class="w-full space-y-4">
                    <div class="mt-6 flex items-start lg:items-center gap-2 sm:gap-3">
                      <.icon
                        name="tabler-circle-number-1"
                        class="w-6 h-6 sm:w-8 sm:h-8 text-foreground shrink-0"
                      />
                      <p class="text-foreground text-sm sm:text-lg font-medium">
                        Share your JDs and receive handpicked candidates with the right skills and experience
                      </p>
                    </div>
                    <div class="relative z-30 mx-auto">
                      <div class="relative mx-auto">
                        <div class="group/card h-full border-2 border-white/10 bg-muted md:gap-8 group relative flex-1 overflow-hidden rounded-xl bg-cover hover:no-underline">
                          <div class="grid h-7 grid-cols-[1fr_auto_1fr] overflow-hidden border-b border-gray-800 ">
                            <div class="ml-2 flex items-center gap-1">
                              <div class="h-2.5 w-2.5 rounded-full bg-red-400"></div>
                              <div class="h-2.5 w-2.5 rounded-full bg-yellow-400"></div>
                              <div class="h-2.5 w-2.5 rounded-full bg-green-400"></div>
                            </div>
                            <div class="flex items-center justify-center gap-2">
                              <img
                                src={~p"/images/logo-192px.png"}
                                alt="Algora"
                                class="w-4 h-4 rounded"
                              />
                              <div class="text-xs text-foreground">
                                algora.io<span class="text-foreground/70 hidden sm:inline">/candidates</span>
                              </div>
                            </div>
                            <div></div>
                          </div>
                          <div class="relative flex aspect-[1200/630] h-full w-full items-center justify-center text-balance text-center text-xl font-medium text-red-100 sm:text-2xl">
                            <img
                              src={~p"/images/screenshots/candidates-page.png"}
                              alt="Candidates page"
                              class="w-full bg-[#121214] p-1"
                            />
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div class="mt-12 w-full space-y-4">
                    <div class="mt-6 flex items-start lg:items-center gap-2 sm:gap-3">
                      <.icon
                        name="tabler-circle-number-2"
                        class="w-6 h-6 sm:w-8 sm:h-8 text-foreground shrink-0"
                      />
                      <p class="text-foreground text-sm sm:text-lg font-medium">
                        Get notified in your inbox and Slack with candidates ready to interview
                      </p>
                    </div>

                    <div class="relative z-30 mx-auto">
                      <div class="relative mx-auto">
                        <div class="group/card h-full border-2 border-white/10 bg-muted md:gap-8 group relative flex-1 overflow-hidden rounded-xl bg-cover hover:no-underline">
                          <div class="grid h-7 grid-cols-[1fr_auto_1fr] overflow-hidden border-b border-gray-800 ">
                            <div class="ml-2 flex items-center gap-1">
                              <div class="h-2.5 w-2.5 rounded-full bg-red-400"></div>
                              <div class="h-2.5 w-2.5 rounded-full bg-yellow-400"></div>
                              <div class="h-2.5 w-2.5 rounded-full bg-green-400"></div>
                            </div>
                            <div class="flex items-center justify-center gap-2">
                              <img
                                src={~p"/images/logos/slack.svg"}
                                alt="Slack"
                                class="w-4 h-4 rounded"
                              />
                              <div class="text-xs text-foreground">
                                app.slack.com<span class="text-foreground/70 hidden sm:inline">/client/T05UQ2UMHFX/C09FC54M0S3</span>
                              </div>
                            </div>
                            <div></div>
                          </div>
                          <div class="relative flex aspect-[1008/561] h-full w-full items-center justify-center text-balance text-center text-xl font-medium text-red-100 sm:text-2xl">
                            <img
                              src={~p"/images/screenshots/candidate-drip.png"}
                              alt="Candidate drip"
                              class="w-full bg-[#121214] p-1"
                            />
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div class="mt-12 w-full space-y-4">
                    <div class="mt-6 flex items-start lg:items-center gap-2 sm:gap-3">
                      <.icon
                        name="tabler-circle-number-3"
                        class="w-6 h-6 sm:w-8 sm:h-8 text-foreground shrink-0"
                      />
                      <p class="text-foreground text-sm sm:text-lg font-medium">
                        Candidates are auto-added to your Ashby
                      </p>
                    </div>
                    <div class="relative z-30 mx-auto">
                      <div class="relative mx-auto">
                        <div class="group/card h-full border-2 border-white/10 bg-muted md:gap-8 group relative flex-1 overflow-hidden rounded-xl bg-cover hover:no-underline">
                          <div class="grid h-7 grid-cols-[1fr_auto_1fr] overflow-hidden border-b border-gray-800 ">
                            <div class="ml-2 flex items-center gap-1">
                              <div class="h-2.5 w-2.5 rounded-full bg-red-400"></div>
                              <div class="h-2.5 w-2.5 rounded-full bg-yellow-400"></div>
                              <div class="h-2.5 w-2.5 rounded-full bg-green-400"></div>
                            </div>
                            <div class="flex items-center justify-center gap-2">
                              <img
                                src={~p"/images/logos/ashby.png"}
                                alt="Ashby"
                                class="w-4 h-4 rounded"
                              />
                              <div class="text-xs text-foreground">
                                app.ashbyhq.com<span class="text-foreground/70 hidden sm:inline">/candidates/pipeline/active</span>
                              </div>
                            </div>
                            <div></div>
                          </div>
                          <div class="relative flex aspect-[816/414] h-full w-full items-center justify-center text-balance text-center text-xl font-medium text-red-100 sm:text-2xl">
                            <img src={~p"/images/screenshots/ashby.png"} alt="Ashby" class="w-full" />
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div class="pt-12 sm:pt-24 grid grid-cols-1 gap-12">
                    <div class="max-w-[88rem] pt-2">
                      <div class="grid grid-cols-3 gap-8 lg:gap-16">
                        <%= for stat <- @stats1 do %>
                          <div>
                            <div class="text-4xl font-bold font-display text-foreground">
                              {stat.value}
                            </div>
                            <div class="text-base text-muted-foreground mt-2">
                              {stat.label}
                            </div>
                          </div>
                        <% end %>
                      </div>
                    </div>
                    <div class="max-w-[88rem]">
                      <div class="grid grid-cols-1 md:grid-cols-2 gap-8 max-w-6xl mx-auto">
                        <%= for hire <- @hires1 do %>
                          <%= if Map.get(hire, :special) do %>
                            <div class="relative flex-1 flex mb-12 max-w-md">
                              <div class="truncate flex items-center gap-2 sm:gap-3 p-4 sm:py-6 bg-gradient-to-br from-emerald-900/30 to-emerald-800/20 rounded-xl border-2 border-emerald-400/30 shadow-xl shadow-emerald-400/10 w-full">
                                <img
                                  src={hire.person_avatar}
                                  alt={hire.person_name}
                                  class="size-8 sm:size-12 rounded-full ring-2 ring-emerald-400/50"
                                />
                                <.icon
                                  name="tabler-arrow-right"
                                  class="size-3 sm:size-4 text-emerald-400 shrink-0"
                                />
                                <img
                                  src={hire.company_avatar}
                                  alt={hire.company_name}
                                  class="size-8 sm:size-12 rounded-full ring-2 ring-emerald-400/50"
                                />
                                <div class="flex-1">
                                  <div class="text-sm font-medium whitespace-nowrap text-emerald-100">
                                    {hire.person_name}
                                    <.icon name="tabler-arrow-right" class="size-3 text-emerald-400" /> {hire.company_name}
                                  </div>
                                  <div class="text-xs text-emerald-200/80 mt-1">
                                    {hire.person_title}
                                  </div>
                                  <div :if={hire[:hire_date]} class="text-xs text-emerald-300/70 mt-1">
                                    {hire.hire_date}
                                  </div>
                                </div>
                              </div>
                              <.badge
                                variant="secondary"
                                class="absolute -top-2 -left-2 text-xs px-2 sm:px-3 py-0.5 sm:py-1 text-black bg-gradient-to-r from-emerald-400 to-emerald-500 font-semibold shadow-lg"
                              >
                                <.icon
                                  name="tabler-star-filled"
                                  class="size-4 text-black mr-1 -ml-0.5"
                                /> New hire!
                              </.badge>

                              <%= if String.contains?(hire.company_name, "YC") do %>
                                <img
                                  src={~p"/images/logos/yc.svg"}
                                  alt="Y Combinator"
                                  class="absolute -top-2 -right-2 size-6 opacity-90"
                                />
                              <% end %>
                            </div>
                          <% end %>
                        <% end %>
                      </div>

                      <div class="grid grid-cols-1 md:grid-cols-2 gap-8 max-w-6xl mx-auto">
                        <%= for hire <- @hires1 do %>
                          <%= unless Map.get(hire, :special) do %>
                            <div class="relative flex items-center gap-2 sm:gap-3 p-4 sm:py-6 bg-card rounded-xl border shrink-0">
                              <img
                                src={hire.person_avatar}
                                alt={hire.person_name}
                                class="size-8 sm:size-12 rounded-full"
                              />
                              <.icon
                                name="tabler-arrow-right"
                                class="size-3 sm:size-4 text-muted-foreground shrink-0"
                              />
                              <img
                                src={hire.company_avatar}
                                alt={hire.company_name}
                                class="size-8 sm:size-12 rounded-full"
                              />
                              <div class="flex-1">
                                <div class="text-sm font-medium whitespace-nowrap">
                                  {hire.person_name}
                                  <.icon name="tabler-arrow-right" class="size-3 text-foreground" /> {Algora.Util.compact_org_name(
                                    hire.company_name
                                  )}
                                  <%= if String.contains?(hire.company_name, "YC") do %>
                                    <img
                                      src={~p"/images/logos/yc.svg"}
                                      alt="Y Combinator"
                                      class="size-4 opacity-90 inline-flex ml-1"
                                    />
                                  <% end %>
                                </div>
                                <div class="text-xs text-muted-foreground mt-1">
                                  {hire.person_title}
                                </div>
                              </div>
                              <%= if String.contains?(hire.company_name, "Permit.io") or String.contains?(hire.company_name, "Prefix.dev") or String.contains?(hire.company_name, "Twenty") or String.contains?(hire.company_name, "Comfy") do %>
                                <.badge
                                  variant="secondary"
                                  class="absolute -top-2 -left-2 text-xs px-2 py-1 text-emerald-400 bg-emerald-950"
                                >
                                  Contract hire!
                                </.badge>
                              <% else %>
                                <.badge
                                  variant="secondary"
                                  class="absolute -top-2 -left-2 text-xs px-2 py-1 text-emerald-400 bg-emerald-950"
                                >
                                  Full-time hire!
                                </.badge>
                              <% end %>
                            </div>
                          <% end %>
                        <% end %>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </section>

            <%!-- <section class="relative isolate py-8 sm:py-20">
              <div class="mx-auto max-w-[88rem] px-6 lg:px-8 pt-24 xl:pt-0">
                <h2 class="font-display text-4xl font-semibold tracking-tight text-foreground sm:text-6xl mb-2 sm:mb-4">
                  Publish jobs
                </h2>
                <p class="font-medium text-[15px] text-muted-foreground sm:text-xl mb-12 mx-auto">
                  Reach top 1% users matching your tech, skills, seniority and location preferences
                </p>
                <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
                  <.link href="https://algora.io/coderabbit/jobs" target="_blank">
                    <img
                      src="https://algora.io/og/coderabbit/jobs?cached"
                      alt="CodeRabbit jobs"
                      class="object-cover aspect-[1200/630] rounded-xl border border-border bg-gray-800"
                      loading="lazy"
                    />
                  </.link>
                  <.link href="https://algora.io/comfy-org/jobs" target="_blank">
                    <img
                      src="https://algora.io/og/comfy-org/jobs?cached"
                      alt="Comfy.org jobs"
                      class="object-cover aspect-[1200/630] rounded-xl border border-border bg-gray-800"
                      loading="lazy"
                    />
                  </.link>
                  <.link href="https://algora.io/lovable/jobs" target="_blank">
                    <img
                      src="https://algora.io/og/lovable/jobs?cached"
                      alt="Lovable jobs"
                      class="object-cover aspect-[1200/630] rounded-xl border border-border bg-gray-800"
                      loading="lazy"
                    />
                  </.link>
                </div>
                <div class="pt-9 sm:pt-18 text-center">
                  <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div>
                      <div class="mb-2 mx-auto flex items-center justify-center h-12 w-12 bg-emerald-400/10 rounded-full">
                        <.icon name="github" class="h-8 w-8 text-emerald-400" />
                      </div>
                      <h4 class="font-semibold text-foreground mb-1">Apply with GitHub</h4>
                      <p class="text-sm text-foreground-light">
                        Your Algora job board automatically screens and ranks applicants based on OSS contributions
                      </p>
                    </div>
                    <div>
                      <div class="mb-2 mx-auto flex items-center justify-center h-12 w-12 bg-emerald-400/10 rounded-full">
                        <.icon name="tabler-speakerphone" class="h-8 w-8 text-emerald-400" />
                      </div>
                      <h4 class="font-semibold text-foreground mb-1">Massive Reach</h4>
                      <p class="text-sm text-foreground-light">
                        Reach 200K+ devs with unlimited job postings
                      </p>
                    </div>
                    <div>
                      <div class="mb-2 mx-auto flex items-center justify-center h-12 w-12 bg-emerald-400/10 rounded-full">
                        <.icon name="tabler-plug-connected" class="h-8 w-8 text-emerald-400" />
                      </div>
                      <h4 class="font-semibold text-foreground mb-1">White-label</h4>
                      <p class="text-sm text-foreground-light">
                        Embed 1-click apply on your website<br />
                        and add custom branding to your job board
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </section> --%>
          </div>
        </div>
      </main>
    </div>

    <div class="relative isolate overflow-hidden bg-gradient-to-br from-black to-background">
      <Footer.footer class="max-w-[88rem]" />
    </div>

    <.modal_video_dialog />
    <.challenge_drawer
      show_challenge_drawer={@show_challenge_drawer}
      challenge_form={@challenge_form}
    />
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
  def handle_event("show_challenge_drawer", _, socket) do
    {:noreply, assign(socket, :show_challenge_drawer, true)}
  end

  @impl true
  def handle_event("close_challenge_drawer", _, socket) do
    {:noreply, assign(socket, :show_challenge_drawer, false)}
  end

  @impl true
  def handle_event("submit_challenge", %{"challenge_form" => params}, socket) do
    case ChallengeForm.changeset(%ChallengeForm{}, params) do
      %{valid?: true} = changeset ->
        data = Ecto.Changeset.apply_changes(changeset)
        Algora.Activities.alert("New challenge submission from #{data.email}: #{data.description}", :critical)

        {:noreply,
         socket
         |> assign(:show_challenge_drawer, false)
         |> put_flash(:info, "Thank you for your submission! We'll be in touch soon.")}

      %{valid?: false} = changeset ->
        {:noreply, assign(socket, :challenge_form, to_form(changeset))}
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

  defp hires1 do
    [
      %{
        company_name: "Comfy",
        company_avatar: "https://avatars.githubusercontent.com/u/166579949?v=4",
        person_name: "Gavin Li",
        person_avatar: "https://avatars.githubusercontent.com/u/1113905?v=4",
        person_title: "Staff Applied ML Engineer"
      },
      %{
        company_name: "Trigger.dev (YC W23)",
        company_avatar: "https://github.com/triggerdotdev.png",
        person_name: "Nick",
        person_avatar: "https://trigger.dev/blog/authors/nick.png",
        person_title: "Founding Engineer"
      },
      %{
        company_name: "Golem Cloud",
        company_avatar: "https://github.com/golemcloud.png",
        person_name: "Maxim S",
        person_avatar: "https://github.com/mschuwalow.png",
        person_title: "Lead Engineer"
      },
      %{
        company_name: "Comfy",
        company_avatar: "https://avatars.githubusercontent.com/u/166579949?v=4",
        person_name: "David Aguilar",
        person_avatar: "https://algora-console.t3.storageapi.dev/avatars/davvid.jpeg",
        person_title: "Staff AI Cloud Infra Engineer"
      },
      %{
        company_name: "TraceMachina",
        company_avatar: "https://avatars.githubusercontent.com/u/144973251?s=200&v=4",
        person_name: "Tom",
        person_avatar: "https://avatars.githubusercontent.com/u/38532?v=4",
        person_title: "Staff Software Engineer"
      },
      %{
        company_name: "Firecrawl (YC S22)",
        company_avatar: "https://github.com/mendableai.png",
        person_name: "Gergő Móricz",
        person_avatar: "https://github.com/mogery.png",
        person_title: "Software Engineer"
      }
    ]
  end

  defp hires2 do
    [
      %{
        company_name: "Cal.com",
        company_avatar: "https://github.com/calcom.png",
        person_name: "Efraín",
        person_avatar: "https://github.com/roae.png",
        person_title: "Software Engineer"
      },
      %{
        company_name: "Hanko",
        company_avatar: "https://avatars.githubusercontent.com/u/20222142?v=4",
        person_name: "Ashutosh",
        person_avatar: "https://algora-console.fly.storage.tigris.dev/avatars/Ashutosh-Bhadauriya.jpeg",
        person_title: "Developer Advocate"
      },
      %{
        company_name: "Tailcall",
        company_avatar:
          "https://algora.io/asset/storage/v1/object/public/images/org/cli0b0kdt0000mh0fngt4r4bk-1741007407053",
        person_name: "Kiryl",
        person_avatar: "https://algora.io/asset/storage/v1/object/public/images/user/clg4rtl2n0002jv0fg30lto6l",
        person_title: "Founding Engineer"
      },
      %{
        company_name: "Forge Code",
        company_avatar: "https://avatars.githubusercontent.com/u/197551910?s=200&v=4",
        person_name: "Sandipsinh",
        person_avatar: "https://algora-console.fly.storage.tigris.dev/avatars/ssddOnTop.jpeg",
        person_title: "Software Engineer"
      },
      %{
        company_name: "Twenty (YC S22)",
        company_avatar: "https://github.com/twentyhq.png",
        person_name: "Neo",
        person_avatar: "https://github.com/neo773.png",
        person_title: "Software Engineer"
      },
      %{
        company_name: "Tailcall",
        company_avatar:
          "https://algora.io/asset/storage/v1/object/public/images/org/cli0b0kdt0000mh0fngt4r4bk-1741007407053",
        person_name: "Panagiotis",
        person_avatar: "https://github.com/karatakis.png",
        person_title: "Software Engineer"
      },
      %{
        company_name: "TraceMachina",
        company_avatar: "https://avatars.githubusercontent.com/u/144973251?s=200&v=4",
        person_name: "Tom",
        person_avatar: "https://avatars.githubusercontent.com/u/38532?v=4",
        person_title: "Staff Software Engineer",
        special: true
      },
      %{
        company_name: "Activepieces (YC S22)",
        company_avatar: "https://avatars.githubusercontent.com/u/99494700?s=48&v=4",
        person_name: "David",
        person_avatar: "https://avatars.githubusercontent.com/u/51977119?v=4",
        person_title: "Software Engineer",
        special: true
      },
      %{
        company_name: "TraceMachina",
        company_avatar: "https://avatars.githubusercontent.com/u/144973251?s=200&v=4",
        person_name: "Aman",
        person_avatar: "https://avatars.githubusercontent.com/u/53134669?v=4",
        person_title: "Software Engineer",
        special: true
      },
      %{
        company_name: "Permit.io",
        company_avatar: "https://github.com/permitio.png",
        person_name: "David",
        person_avatar: "https://github.com/daveads.png",
        person_title: "Software Engineer"
      },
      %{
        company_name: "Shuttle (YC S20)",
        company_avatar: "https://app.algora.io/asset/storage/v1/object/public/images/org/shuttle.png",
        person_name: "Jon",
        person_avatar: "https://github.com/jonaro00.png",
        person_title: "Software Engineer"
      },
      %{
        company_name: "Prefix.dev",
        company_avatar: "https://github.com/prefix-dev.png",
        person_name: "Denizhan",
        person_avatar: "https://algora-console.fly.storage.tigris.dev/avatars/zelosleone.jpeg",
        person_title: "Software Engineer"
      }
    ]
  end

  defp challenge_drawer(assigns) do
    ~H"""
    <.drawer show={@show_challenge_drawer} on_cancel="close_challenge_drawer" direction="right">
      <.drawer_header>
        <.drawer_title>Submit Challenge</.drawer_title>
        <.drawer_description>
          Tell us about your coding challenge and we'll help you set it up.
        </.drawer_description>
      </.drawer_header>
      <.drawer_content class="mt-4">
        <.form for={@challenge_form} phx-submit="submit_challenge">
          <div class="space-y-6 max-w-md">
            <.input
              field={@challenge_form[:email]}
              label="Email"
              type="email"
              required
              placeholder="your@email.com"
            />
            <.input
              field={@challenge_form[:description]}
              label="Challenge Description"
              type="textarea"
              required
              placeholder="Describe your coding challenge..."
            />
            <div class="flex justify-end gap-4">
              <.button variant="outline" type="button" phx-click="close_challenge_drawer">
                Cancel
              </.button>
              <.button type="submit">
                Submit
              </.button>
            </div>
          </div>
        </.form>
      </.drawer_content>
    </.drawer>
    """
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
      %{url: "https://algora.io/og/coderabbit/jobs", alt: "CodeRabbit jobs"},
      %{url: "https://algora.io/og/lovable/jobs", alt: "Lovable jobs"}
    ]

    # Cadence: Candidate, Candidate, Job page, Candidate, Candidate, Job page
    candidates_data
    |> Enum.reduce({[], 0, 0}, fn candidate, {acc, candidate_count, job_page_index} ->
      # Add the candidate
      acc_with_candidate = acc ++ [{:candidate, candidate}]
      new_candidate_count = candidate_count + 1

      # After every 2 candidates, insert a job page
      if rem(new_candidate_count, 2) == 0 do
        job_page = Enum.at(job_pages, rem(job_page_index, length(job_pages)))
        {acc_with_candidate ++ [{:job_page, job_page}], new_candidate_count, job_page_index + 1}
      else
        {acc_with_candidate, new_candidate_count, job_page_index}
      end
    end)
    |> elem(0)
  end
end
