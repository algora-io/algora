defmodule AlgoraWeb.HomeLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

  import AlgoraWeb.Components.ModalVideo

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
        <Header.header class="container" />
      <% end %>

      <main class="bg-black relative overflow-hidden">
        <section class="relative isolate min-h-[calc(100vh)]">
          <div class="h-full mx-auto max-w-[88rem] px-6 lg:px-8 flex flex-col items-center justify-center pt-32 pb-12">
            <div class="h-full mx-auto lg:mx-0 flex lg:max-w-none items-center justify-center text-center w-full">
              <div class="w-full flex flex-col lg:flex-row lg:justify-center gap-6">
                <div class="w-full flex flex-col items-center lg:items-start text-center lg:text-left lg:pl-8">
                  <h1 class="font-display text-3xl sm:text-lg md:text-5xl xl:text-[3.25rem] font-semibold tracking-tight text-foreground">
                    Open source <span class="text-emerald-400">tech recruiting</span>
                  </h1>
                  <p class="mt-2 text-lg leading-8 font-medium text-foreground">
                    Connecting the most prolific open source maintainers & contributors with their next jobs
                  </p>
                  <div class="flex items-center justify-center lg:justify-start gap-12 overflow-x-auto scrollbar-thin py-4">
                    <img
                      src="/images/wordmarks/coderabbit.svg"
                      alt="CodeRabbit"
                      class="h-6 shrink-0 saturate-0 hover:saturate-100 transition-all"
                    />
                    <img
                      src="/images/wordmarks/comfy.svg"
                      alt="Comfy"
                      class="h-5 shrink-0 saturate-0 hover:saturate-100 transition-all"
                    />
                    <img
                      src="/images/wordmarks/lovable.svg"
                      alt="Lovable"
                      class="h-4 shrink-0 saturate-0 hover:saturate-100 transition-all"
                    />
                    <div class="flex items-center saturate-0 hover:saturate-100 transition-all">
                      <img src="/images/wordmarks/firecrawl.svg" alt="Firecrawl" class="h-8 shrink-0" />
                      <img
                        src="/images/wordmarks/firecrawl2.svg"
                        alt="Firecrawl2"
                        class="h-5 shrink-0"
                      />
                    </div>
                    <img
                      src="/images/wordmarks/golem.png"
                      alt="Golem"
                      class="h-5 shrink-0 saturate-0 hover:saturate-100 transition-all"
                    />
                    <img
                      src="/images/wordmarks/calcom.png"
                      alt="Cal.com"
                      class="h-4 shrink-0 saturate-0 hover:saturate-100 transition-all"
                    />
                  </div>
                  <%!-- <ul class="mt-2 flex flex-col gap-2 text-sm">
                    <li class="flex items-center text-left text-foreground/80">
                      <.icon
                        name="tabler-square-rounded-number-1"
                        class="size-6 mr-2 shrink-0 text-foreground/80"
                      />
                      <span class="font-medium leading-7 whitespace-nowrap">
                        Submit JD
                      </span>
                    </li>
                    <li class="flex items-center text-left text-foreground/80">
                      <.icon
                        name="tabler-square-rounded-number-2"
                        class="size-6 mr-2 shrink-0 text-foreground/80"
                      />
                      <span class="font-medium leading-7 whitespace-nowrap">
                        Receive matches <span class="text-emerald-300">within hours</span>
                      </span>
                    </li>
                    <li class="flex items-center text-left text-foreground/80">
                      <.icon
                        name="tabler-square-rounded-number-3"
                        class="size-6 mr-2 shrink-0 text-foreground/80"
                      />
                      <span class="font-medium leading-7 whitespace-nowrap">
                        Interview <span class="text-emerald-300">within days</span>
                      </span>
                    </li>
                  </ul> --%>
                  <div
                    id="candidate-carousel-home"
                    phx-hook="CandidateCarousel"
                    data-candidate-ids={
                      Jason.encode!(["9EL2CWmJxZ57eqGv", "Hx4qKGE9CLkLHySJ", "8oXJpLYUp3M4dYsf"])
                    }
                  >
                    <img
                      src="https://algora.io/og/coderabbit/candidates/9EL2CWmJxZ57eqGv"
                      alt="Job candidates"
                      class="-ml-2 mt-4 rounded-xl object-cover max-w-[48rem] transition-opacity duration-500"
                      style="aspect-ratio: 1200/630;"
                    />
                  </div>
                  <%!-- <div class="pt-4 sm:max-w-[40rem] grid w-full grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-y-4 gap-x-4 mx-auto items-center justify-center sm:ml-0">
                    <.link class="relative flex items-center justify-center" href={~p"/cal"}>
                      <Wordmarks.calcom class="w-[80%] col-auto" alt="Cal.com" />
                    </.link>
                    <.link class="relative flex items-center justify-center" href={~p"/qdrant"}>
                      <Wordmarks.qdrant class="w-[80%] col-auto" alt="Qdrant" />
                    </.link>
                    <.link class="relative flex items-center justify-center" href={~p"/zio"}>
                      <img
                        loading="eager"
                        src={~p"/images/wordmarks/zio.png"}
                        alt="ZIO"
                        class="mt-1 sm:mt-3 w-[70%] col-auto brightness-0 invert"
                      />
                    </.link>
                    <.link
                      class="relative flex items-center justify-center"
                      navigate={~p"/activepieces"}
                    >
                      <img
                        loading="eager"
                        src={~p"/images/wordmarks/activepieces.svg"}
                        alt="Activepieces"
                        class="col-auto brightness-0 invert"
                      />
                    </.link>
                    <.link class="relative flex items-center justify-center" href={~p"/golemcloud"}>
                      <Wordmarks.golemcloud class="col-auto w-[80%]" alt="Golem Cloud" />
                    </.link>
                    <.link
                      class="font-bold font-display text-sm sm:text-base whitespace-nowrap flex items-center justify-center"
                      navigate={~p"/browser-use"}
                    >
                      <img
                        loading="eager"
                        src={~p"/images/wordmarks/browser-use.svg"}
                        alt="Browser Use"
                        class="saturate-0 w-4 sm:w-4 mr-1 sm:mr-1"
                      /> Browser Use
                    </.link>
                  </div> --%>
                </div>

                <div class="w-full max-w-[34rem] text-left -mt-4">
                  <div class="rounded-xl bg-card text-card-foreground shadow-2xl ring-1 ring-white/10">
                    <div class="p-8">
                      <h2 class="text-3xl font-semibold leading-7 text-white">
                        View your candidates
                      </h2>
                      <p class="pt-2 text-sm text-muted-foreground">
                        Share your JD to receive your candidates within hours.
                      </p>

                      <form class="mt-6 flex flex-col gap-3">
                        <div class="space-y-3">
                          <label class="text-sm font-medium text-foreground">
                            Hire type
                          </label>
                          <div class="grid grid-cols-2 gap-4">
                            <label class="group relative flex cursor-pointer rounded-lg px-3 py-2 shadow-sm focus:outline-none border-2 bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10 border-border has-[:checked]:border-primary has-[:checked]:bg-primary/10">
                              <input type="radio" name="hire_type" value="full_time" class="sr-only" />
                              <div class="flex items-center gap-3">
                                <.icon name="tabler-briefcase" class="h-6 w-6 text-primary shrink-0" />
                                <span class="text-xs text-foreground">
                                  Full-time
                                </span>
                              </div>
                            </label>
                            <label class="group relative flex cursor-pointer rounded-lg px-3 py-2 shadow-sm focus:outline-none border-2 bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10 border-border has-[:checked]:border-primary has-[:checked]:bg-primary/10">
                              <input type="radio" name="hire_type" value="contract" class="sr-only" />
                              <div class="flex items-center gap-3">
                                <.icon name="tabler-clock" class="h-6 w-6 text-primary shrink-0" />
                                <span class="text-xs text-foreground">
                                  Contract
                                </span>
                              </div>
                            </label>
                          </div>
                        </div>

                        <div>
                          <label class="block text-sm font-medium text-foreground mb-2">
                            Tech stack
                          </label>
                          <.TechStack tech={@tech_stack} socket={@socket} form="home_form" />
                        </div>

                        <div class="grid grid-cols-2 gap-4">
                          <.input
                            name="location"
                            value=""
                            label="Location"
                            placeholder="San Francisco, Remote"
                          />
                          <.input
                            name="compensation"
                            value=""
                            label="Compensation range"
                            placeholder="$150k - $250k"
                          />
                        </div>

                        <.input
                          type="textarea"
                          name="job_description"
                          value=""
                          label="Job description / careers URL"
                          rows="3"
                          placeholder="Tell us about the role and your requirements..."
                        />

                        <.input
                          name="email"
                          value=""
                          label="Work email"
                          placeholder="you@company.com"
                        />
                        <div class="flex flex-col gap-4">
                          <.button class="w-full">Receive your candidates</.button>
                        </div>
                      </form>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section class="relative isolate py-16 sm:pb-40">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-12 pl-12">
            <div class="md:col-span-2 ml-auto max-w-7xl pl-12">
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
                          <div class="text-xs text-emerald-200/80 mt-1">{hire.person_title}</div>
                          <div :if={hire[:hire_date]} class="text-xs text-emerald-300/70 mt-1">
                            {hire.hire_date}
                          </div>
                        </div>
                      </div>
                      <.badge
                        variant="secondary"
                        class="absolute -top-2 -left-2 text-xs px-2 sm:px-3 py-0.5 sm:py-1 text-black bg-gradient-to-r from-emerald-400 to-emerald-500 font-semibold shadow-lg"
                      >
                        <.icon name="tabler-star-filled" class="size-4 text-black mr-1 -ml-0.5" />
                        New hire!
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
                        <div class="text-xs text-muted-foreground mt-1">{hire.person_title}</div>
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
            <div class="mr-auto max-w-7xl px-6 pt-2 pl-12">
              <div class="grid grid-cols-1 gap-16 text-center">
                <%= for stat <- @stats1 do %>
                  <div>
                    <div class="text-2xl sm:text-3xl md:text-4xl font-bold font-display text-foreground">
                      {stat.value}
                    </div>
                    <div class="text-sm sm:text-base text-muted-foreground mt-2">
                      {stat.label}
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
          <div class="pt-6 sm:pt-12 max-w-[69rem] mx-auto flex flex-col md:flex-row gap-8 sm:gap-12 px-4">
            <div class="flex-1 mx-auto flex flex-col justify-between">
              <figure class="relative flex flex-col h-full">
                <blockquote class="text-lg font-medium text-foreground/90 flex-grow">
                  "Algora helped us meet Nick, who after being contracted a few months, joined the Trigger founding team full-time. It was the
                  <span class="text-success">easiest hire</span>
                  and turned out to be <span class="text-success">very very good</span>."
                </blockquote>
                <figcaption class="mt-8 flex items-center gap-x-4">
                  <img
                    src="/images/people/eric-allam.jpg"
                    alt="Eric Allam"
                    class="h-16 w-16 rounded-full object-cover bg-gray-800"
                    loading="lazy"
                  />
                  <div class="text-sm">
                    <div class="text-base font-semibold text-foreground">Eric Allam</div>
                    <div class="text-foreground/90 font-medium">Co-founder & CTO</div>
                    <div class="text-muted-foreground font-medium">
                      Trigger.dev <span class="text-orange-400">(YC W23)</span>
                    </div>
                  </div>
                </figcaption>
              </figure>
            </div>

            <div class="flex-1 mx-auto flex flex-col justify-between">
              <figure class="relative flex flex-col h-full">
                <blockquote class="text-lg font-medium text-foreground/90 flex-grow">
                  "Algora helped us meet Gergő and
                  <span class="text-success">I couldn't be happier</span>
                  with the results. He's been working full-time with us for
                  <span class="text-success">over a year</span>
                  now and is a key contributor to our product."
                </blockquote>
                <figcaption class="mt-8 flex items-center gap-x-4">
                  <img
                    src="/images/people/nicolas-camara.jpg"
                    alt="Nicolas Camara"
                    class="h-16 w-16 rounded-full object-cover bg-gray-800"
                    loading="lazy"
                  />
                  <div class="text-sm">
                    <div class="text-base font-semibold text-foreground">Nicolas Camara</div>
                    <div class="text-foreground/90 font-medium">Co-founder & CTO</div>
                    <div class="text-muted-foreground font-medium">
                      Firecrawl <span class="text-orange-400">(YC S22)</span>
                    </div>
                  </div>
                </figcaption>
              </figure>
            </div>
          </div>
        </section>

        <section class="relative isolate py-16 sm:py-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8 pt-24 xl:pt-0">
            <h2 class="font-display text-4xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-2 sm:mb-4">
              Receive candidates
            </h2>
            <p class="text-center font-medium text-[15px] text-muted-foreground sm:text-xl mb-12 mx-auto">
              Share your JDs and receive handpicked candidates with the right skills and experience
            </p>
            <div class="flex mx-auto gap-8">
              <div class="w-[47%]">
                <img
                  src={~p"/images/screenshots/candidate-drip.png"}
                  alt="Candidate drip"
                  class="w-full object-cover aspect-[1008/561] rounded-xl border border-border bg-[#121214] p-1"
                  loading="lazy"
                />
                <div class="mt-6 flex items-center gap-3">
                  <div class="w-12 h-12 rounded-xl bg-white/10 border border-border flex items-center justify-center flex-shrink-0">
                    <img
                      src={~p"/images/logos/gmail.png"}
                      alt="Gmail"
                      class="w-8 h-auto aspect-[800/601]"
                    />
                  </div>
                  <div class="w-12 h-12 rounded-xl bg-white/10 border border-border flex items-center justify-center flex-shrink-0">
                    <img src={~p"/images/logos/slack.svg"} alt="Slack" class="w-7 h-7" />
                  </div>
                  <p class="text-foreground text-lg font-medium">
                    Receive candidates in your inbox/Slack
                  </p>
                </div>
              </div>
              <div class="w-[53%]">
                <img
                  src={~p"/images/screenshots/candidates.png"}
                  alt="Candidates"
                  class="w-full object-cover aspect-[1480/726] rounded-xl border border-border bg-[#121214]"
                  loading="lazy"
                />
                <div class="mt-6 flex items-center gap-3">
                  <img
                    src={~p"/images/logos/ashby.png"}
                    alt="Ashby"
                    class="w-12 h-12 rounded-xl bg-white/10 border border-border"
                  />
                  <p class="text-foreground text-lg font-medium">
                    Sync with your Ashby to track candidates
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section class="relative isolate py-16 sm:py-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8 pt-24 xl:pt-0">
            <h2 class="font-display text-4xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-2 sm:mb-4">
              Publish jobs
            </h2>
            <p class="text-center font-medium text-[15px] text-muted-foreground sm:text-xl mb-12 mx-auto">
              Access top 1% users matching your tech, skills, seniority and location preferences
            </p>
            <div class="grid grid-cols-3 gap-8">
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
            <div class="pt-12 sm:pt-24 text-center">
              <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div>
                  <div class="mb-2 mx-auto flex items-center justify-center h-12 w-12 bg-emerald-400/10 rounded-full">
                    <.icon name="tabler-filter" class="h-8 w-8 text-emerald-400" />
                  </div>
                  <h4 class="font-semibold text-foreground mb-1">High Signal Only</h4>
                  <p class="text-sm text-foreground-light">
                    Your Algora job board automatically <br /> screens and ranks applicants
                  </p>
                </div>
                <div>
                  <div class="mb-2 mx-auto flex items-center justify-center h-12 w-12 bg-emerald-400/10 rounded-full">
                    <.icon name="tabler-clock" class="h-8 w-8 text-emerald-400" />
                  </div>
                  <h4 class="font-semibold text-foreground mb-1">Save Time & Money</h4>
                  <p class="text-sm text-foreground-light">
                    Match with top developers efficiently
                  </p>
                </div>
                <div>
                  <div class="mb-2 mx-auto flex items-center justify-center h-12 w-12 bg-emerald-400/10 rounded-full">
                    <.icon name="tabler-shield-check" class="h-8 w-8 text-emerald-400" />
                  </div>
                  <h4 class="font-semibold text-foreground mb-1">Avoid Bad Hires</h4>
                  <p class="text-sm text-foreground-light">
                    Trial candidates with real paid projects<br />
                    to assess role fit and job performance
                  </p>
                </div>
                <div>
                  <div class="mb-2 mx-auto flex items-center justify-center h-12 w-12 bg-emerald-400/10 rounded-full">
                    <.icon name="tabler-users" class="h-8 w-8 text-emerald-400" />
                  </div>
                  <h4 class="font-semibold text-foreground mb-1">Massive Reach</h4>
                  <p class="text-sm text-foreground-light">
                    Reach 50K+ devs with unlimited job postings
                  </p>
                </div>
                <div>
                  <div class="mb-2 mx-auto flex items-center justify-center h-12 w-12 bg-emerald-400/10 rounded-full">
                    <.icon name="tabler-target" class="h-8 w-8 text-emerald-400" />
                  </div>
                  <h4 class="font-semibold text-foreground mb-1">Top Talent</h4>
                  <p class="text-sm text-foreground-light">
                    Access top 1% users matching your<br />tech, skills, seniority and location preferences
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
        </section>

        <section class="relative isolate py-16 sm:py-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="font-display text-4xl font-semibold tracking-tight text-foreground sm:text-7xl text-center mb-2 sm:mb-4">
              Paid trials
            </h2>
            <p class="text-center font-medium text-base text-muted-foreground sm:text-xl mb-12 mx-auto">
              Use bounties and contract work to trial your top candidates before hiring them full-time.
            </p>

            <div class="mx-auto max-w-6xl gap-8 text-sm leading-6">
              <div class="flex gap-4 sm:gap-8">
                <div class="w-[40%]">
                  <.modal_video
                    class="aspect-[9/16] rounded-xl lg:rounded-2xl lg:rounded-r-none"
                    src="https://www.youtube.com/embed/xObOGcUdtY0"
                    start={122}
                    title="$15,000 Open source bounty to hire a Rust engineer"
                    poster={~p"/images/people/john-de-goes.jpg"}
                    alt="John A De Goes"
                  />
                </div>
                <div class="w-[60%]">
                  <.link
                    href="https://github.com/golemcloud/golem/issues/1004"
                    rel="noopener"
                    target="_blank"
                    class="relative flex aspect-[1121/1343] w-full items-center justify-center overflow-hidden rounded-xl lg:rounded-2xl lg:rounded-l-none"
                  >
                    <img
                      src={~p"/images/screenshots/bounty-to-hire-golem2.png"}
                      alt="Golem bounty to hire"
                      class="object-cover"
                      loading="lazy"
                    />
                  </.link>
                </div>
              </div>
            </div>

            <div class="mx-auto mt-4 max-w-7xl gap-8 text-sm leading-6 sm:mt-8">
              <div class="lg:col-span-7">
                <h3 class="text-xl sm:text-2xl xl:text-3xl font-display font-bold leading-[1.2] sm:leading-[2rem] xl:leading-[3rem]">
                  We used Algora extensively at Ziverge to reward over
                  <span class="text-success">$180,000</span>
                  in bounties and introduce a whole
                  <span class="text-success">new generation of contributors</span>
                  and <span class="text-success">hired multiple engineers.</span>
                </h3>
                <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-2 sm:pt-6">
                  <div class="flex items-center gap-4">
                    <div>
                      <div class="text-xl sm:text-2xl xl:text-3xl font-semibold text-foreground">
                        John A De Goes
                      </div>
                      <div class="sm:pt-2 text-sm sm:text-lg xl:text-2xl font-medium text-muted-foreground">
                        Founder & CEO at Ziverge
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section class="relative isolate py-16 sm:py-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8 pt-24 xl:pt-0">
            <h2 class="font-display text-4xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-2 sm:mb-4">
              <span class="text-success-300 drop-shadow-[0_1px_5px_#34d39980]">
                Frictionless
              </span>
              <br />contract work
            </h2>
            <p class="text-center font-medium text-[15px] text-muted-foreground sm:text-xl mb-12 mx-auto">
              Complete outcome-based contract work with your contributors and Algora matches
            </p>
            <video
              src={~p"/videos/contracts.mp4"}
              autoplay
              loop
              muted
              playsinline
              class="mt-8 w-full h-full object-cover mx-auto border border-border rounded-xl"
              speed={2}
              playbackspeed={2}
            />
            <div class="pt-12 sm:pt-24 text-center">
              <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div>
                  <div class="mb-2 mx-auto flex items-center justify-center h-12 w-12 bg-emerald-400/10 rounded-full">
                    <.icon name="tabler-bolt" class="h-8 w-8 text-emerald-400" />
                  </div>
                  <h4 class="font-semibold text-foreground mb-1">Instant Matches</h4>
                  <p class="text-sm text-foreground-light">
                    Top 1% developers in your tech stack <br />available to hire now
                  </p>
                </div>
                <div>
                  <div class="mb-2 mx-auto flex items-center justify-center h-12 w-12 bg-emerald-400/10 rounded-full">
                    <.icon name="tabler-clock-dollar" class="h-8 w-8 text-emerald-400" />
                  </div>
                  <h4 class="font-semibold text-foreground mb-1">Track Time & Pull Requests</h4>
                  <p class="text-sm text-foreground-light">
                    Log hours worked and PRs submitted every week
                  </p>
                </div>
                <div>
                  <div class="mb-2 mx-auto flex items-center justify-center h-12 w-12 bg-emerald-400/10 rounded-full">
                    <.icon name="tabler-shield-check" class="h-8 w-8 text-emerald-400" />
                  </div>
                  <h4 class="font-semibold text-foreground mb-1">Escrow Payments</h4>
                  <p class="text-sm text-foreground-light">
                    Pay only for outcomes
                  </p>
                </div>
                <div>
                  <div class="mb-2 mx-auto flex items-center justify-center h-12 w-12 bg-emerald-400/10 rounded-full">
                    <.icon name="tabler-world" class="h-8 w-8 text-emerald-400" />
                  </div>
                  <h4 class="font-semibold text-foreground mb-1">120+ Countries</h4>
                  <p class="text-sm text-foreground-light">
                    Global payments, invoices, compliance, 1099s
                  </p>
                </div>
                <div>
                  <div class="mb-2 mx-auto flex items-center justify-center h-12 w-12 bg-emerald-400/10 rounded-full">
                    <.icon name="tabler-eye-dollar" class="h-8 w-8 text-emerald-400" />
                  </div>
                  <h4 class="font-semibold text-foreground mb-1">What You See is What You Pay</h4>
                  <p class="text-sm text-foreground-light">
                    Hourly rate quotes include developer, payment processing and Algora service fees
                  </p>
                </div>
                <div>
                  <div class="mb-2 mx-auto flex items-center justify-center h-12 w-12 bg-emerald-400/10 rounded-full">
                    <.icon name="tabler-trending-up" class="h-8 w-8 text-emerald-400" />
                  </div>
                  <h4 class="font-semibold text-foreground mb-1">Scale On Demand</h4>
                  <p class="text-sm text-foreground-light">
                    Contract individual contributors or entire flex teams
                  </p>
                </div>
              </div>
            </div>

            <div class="pt-12 sm:pt-24 flex flex-col md:flex-row gap-8 px-4">
              <div class="flex-1 mx-auto max-w-xl flex flex-col justify-between">
                <figure class="relative">
                  <blockquote class="text-lg font-medium text-foreground/90">
                    <p>
                      "I've used Algora in the past for bounties, and recently used them to hire a contract engineer. Every time the process has yield fantastic results, with high quality code and fast turn arounds. I'm a big fan."
                    </p>
                  </blockquote>
                  <figcaption class="mt-4 flex md:items-center md:justify-center gap-x-4">
                    <img
                      src="/images/people/drew-baker.jpeg"
                      alt="Drew Baker"
                      class="h-16 w-16 rounded-full object-cover bg-gray-800"
                      loading="lazy"
                    />
                    <div class="text-sm">
                      <div class="text-base font-semibold text-foreground">Drew Baker</div>
                      <div class="text-foreground/90 font-medium">Technical Partner</div>
                      <div class="text-muted-foreground font-medium">Funkhaus | Notes.fm</div>
                    </div>
                  </figcaption>
                </figure>
              </div>
            </div>
          </div>
        </section>

        <section class="relative isolate pb-16 sm:pb-40 dev:bg-zinc-900">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="font-display text-2xl sm:text-3xl md:text-4xl lg:text-5xl xl:text-6xl font-semibold tracking-tight text-foreground text-center mb-2">
              Open source bounties
            </h2>
            <p class="text-center text-muted-foreground mb-8">
              Use bounties for outcome-based contract work with full GitHub integration.
            </p>

            <%= if Enum.empty?(@orgs_with_stats) do %>
              <div class="text-center py-12">
                <.icon name="tabler-trophy" class="h-12 w-12 text-muted-foreground mx-auto mb-4" />
                <p class="text-muted-foreground">No active bounty programs at the moment</p>
              </div>
            <% else %>
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-6xl mx-auto">
                <%= for org <- @orgs_with_stats do %>
                  <.link navigate={~p"/#{org.handle}/home"} class="group">
                    <div class="relative h-full p-6 bg-card rounded-xl border hover:border-emerald-400/50 hover:shadow-lg transition-all duration-200 group-hover:scale-[1.02]">
                      <div class="flex items-start gap-4 mb-4">
                        <img src={org.avatar_url} alt={org.name} class="size-12 rounded-full" />
                        <div>
                          <h3 class="text-lg font-semibold text-foreground/90 group-hover:text-foreground transition-colors">
                            {org.name}
                          </h3>
                          <p class="text-sm text-muted-foreground line-clamp-2">
                            {org.bio}
                          </p>
                        </div>
                      </div>

                      <div class="grid grid-cols-3 gap-4 mb-4">
                        <div class="text-center p-3 bg-background/50 rounded-lg">
                          <div class="text-lg font-bold font-display text-emerald-400">
                            {org.bounty_stats.open_bounties_count || 0}
                          </div>
                          <div class="text-xs text-muted-foreground">Open bounties</div>
                        </div>
                        <div class="text-center p-3 bg-background/50 rounded-lg">
                          <div class="text-lg font-bold font-display text-emerald-400">
                            {org.bounty_stats.rewarded_bounties_count || 0}
                          </div>
                          <div class="text-xs text-muted-foreground">Rewarded bounties</div>
                        </div>
                        <div class="text-center p-3 bg-background/50 rounded-lg">
                          <div class="text-lg font-bold font-display text-emerald-400">
                            {org.bounty_stats.solvers_count || 0}
                          </div>
                          <div class="text-xs text-muted-foreground">Developers rewarded</div>
                        </div>
                      </div>

                      <%= if org.bounty_stats.total_awarded_amount do %>
                        <div class="text-center p-3 bg-emerald-400/10 rounded-lg border border-emerald-400/20">
                          <div class="text-sm font-medium text-emerald-400">
                            <span class="font-display">
                              {format_money(org.bounty_stats.total_awarded_amount)}
                            </span>
                            paid out
                          </div>
                        </div>
                      <% end %>

                      <div class="flex items-center justify-center mt-4 gap-2 text-xs text-muted-foreground group-hover:text-emerald-400 transition-colors">
                        <span>View bounties</span>
                        <.icon name="tabler-arrow-right" class="size-3" />
                      </div>
                    </div>
                  </.link>
                <% end %>
              </div>

              <div class="text-center mt-8">
                <.button navigate={~p"/bounties"} variant="outline">
                  View all bounties
                </.button>
              </div>
            <% end %>
          </div>
        </section>

        <section class="relative isolate py-16 sm:pb-40 dev:bg-zinc-900">
          <div class="flex flex-col gap-12">
            <div class="mx-auto max-w-7xl">
              <div class="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-6xl mx-auto">
                <%= for hire <- @hires2 do %>
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
                          <div class="text-xs text-emerald-200/80 mt-1">{hire.person_title}</div>
                          <div :if={hire[:hire_date]} class="text-xs text-emerald-300/70 mt-1">
                            {hire.hire_date}
                          </div>
                        </div>
                      </div>
                      <.badge
                        variant="secondary"
                        class="absolute -top-2 -left-2 text-xs px-2 sm:px-3 py-0.5 sm:py-1 text-black bg-gradient-to-r from-emerald-400 to-emerald-500 font-semibold shadow-lg"
                      >
                        <.icon name="tabler-star-filled" class="size-4 text-black mr-1 -ml-0.5" />
                        New hire!
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

              <div class="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-6xl mx-auto">
                <%= for hire <- @hires2 do %>
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
                        <div class="text-xs text-muted-foreground mt-1">{hire.person_title}</div>
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
        </section>

        <section class="relative isolate pb-16 sm:pb-40 dev:bg-zinc-900">
          <div class="flex flex-col gap-4 px-4 pt-6 sm:pt-10 mx-auto max-w-4xl">
            <div class="mx-auto max-w-7xl px-6 lg:px-8 pt-24 xl:pt-0">
              <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-6xl mb-2 sm:mb-4">
                Community highlights
              </h2>
            </div>
            <.events events={@events} />
          </div>
        </section>

        <section class="relative isolate py-16 sm:py-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-2 sm:mb-4">
              Trusted by open source founders
            </h2>

            <div class="mx-auto mt-16 max-w-6xl gap-8 text-sm leading-6 sm:mt-32">
              <div class="grid grid-cols-1 items-center gap-x-8 sm:gap-x-16 gap-y-8 lg:grid-cols-11">
                <div class="w-[12rem] sm:w-auto lg:col-span-5">
                  <div class="relative flex aspect-[791/576] items-center justify-center overflow-hidden rounded-xl sm:rounded-2xl bg-gray-800">
                    <img
                      src={~p"/images/people/louis-beaumont.png"}
                      alt="Louis Beaumont"
                      class="object-cover"
                      loading="lazy"
                    />
                  </div>
                </div>
                <div class="lg:col-span-6">
                  <h3 class="text-xl sm:text-2xl xl:text-3xl font-display font-bold leading-[1.2] sm:leading-[2rem] xl:leading-[3rem]">
                    I posted our bounty on <span class="text-success">Upwork</span>
                    to try it, overall it's <span class="text-success">1000x more friction</span>
                    than OSS bounties with Algora.
                  </h3>
                  <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-6 sm:pt-12">
                    <div class="flex items-center gap-4">
                      <div>
                        <div class="text-xl sm:text-2xl xl:text-3xl font-semibold text-foreground">
                          Louis Beaumont
                        </div>
                        <div class="sm:pt-2 text-sm sm:text-lg xl:text-2xl font-medium text-muted-foreground">
                          Co-founder & CEO at Screenpipe
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="mx-auto mt-16 max-w-6xl gap-8 text-sm leading-6 sm:mt-32">
              <div class="grid grid-cols-1 items-center gap-x-16 gap-y-8 lg:grid-cols-11">
                <div class="w-[12rem] sm:w-auto lg:col-span-5 order-first lg:order-last">
                  <div class="relative flex aspect-[1091/1007] items-center justify-center overflow-hidden rounded-2xl bg-gray-800">
                    <img
                      src={~p"/images/people/josh-pigford.png"}
                      alt="Josh Pigford"
                      class="object-cover"
                      loading="lazy"
                    />
                  </div>
                </div>
                <div class="lg:col-span-6 order-last lg:order-first">
                  <h3 class="text-xl sm:text-2xl xl:text-3xl font-display font-bold leading-[1.2] sm:leading-[2rem] xl:leading-[3rem]">
                    <span class="text-success">Let's offer a bounty</span>
                    to say "Hey, someone please prioritize this, who has the skillset for it?" I think long term I'd like to make it a
                    <span class="text-success">very consistent</span>
                    part of our development process.
                  </h3>
                  <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-4 sm:pt-12">
                    <div class="flex items-center gap-4">
                      <div>
                        <div class="text-xl sm:text-2xl xl:text-3xl font-semibold text-foreground">
                          Josh Pigford
                        </div>
                        <div class="sm:pt-2 text-sm sm:text-lg xl:text-2xl font-medium text-muted-foreground">
                          Co-founder & CEO at Maybe
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="mx-auto mt-16 max-w-6xl gap-8 text-sm leading-6 sm:mt-32">
              <div class="grid grid-cols-1 items-center gap-x-16 gap-y-8 lg:grid-cols-11">
                <div class="w-[12rem] sm:w-auto lg:col-span-4">
                  <div class="relative flex items-center justify-center">
                    <img
                      src={~p"/images/people/john-de-goes-2.jpg"}
                      alt="John A De Goes"
                      class="object-cover size-84 rounded-2xl"
                      loading="lazy"
                    />
                  </div>
                </div>
                <div class="lg:col-span-7">
                  <h3 class="text-xl sm:text-2xl xl:text-3xl font-display font-bold leading-[1.2] sm:leading-[2rem] xl:leading-[3rem]">
                    We used Algora extensively at Ziverge to reward over
                    <span class="text-success">$143,000</span>
                    in bounties and introduce a whole
                    <span class="text-success">new generation of contributors</span>
                    to the ZIO and Golem ecosystems.
                  </h3>
                  <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-4 sm:pt-12">
                    <div class="flex items-center gap-4">
                      <div>
                        <div class="text-xl sm:text-2xl xl:text-3xl font-semibold text-foreground">
                          John A De Goes
                        </div>
                        <div class="sm:pt-2 text-sm sm:text-lg xl:text-2xl font-medium text-muted-foreground">
                          Founder & CEO at Ziverge
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section class="relative isolate pb-16 sm:pb-40 dev:bg-zinc-900">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="font-display text-2xl sm:text-3xl md:text-4xl lg:text-5xl xl:text-6xl font-semibold tracking-tight text-foreground text-center mb-2">
              Challenges
            </h2>
            <p class="text-center text-foreground mb-8"></p>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-6xl mx-auto mb-16">
              <div class="flex flex-col">
                <.link
                  class="group relative flex aspect-[1200/630] flex-1 rounded-2xl border-2 border-solid border-border bg-cover hover:no-underline hover:scale-[1.02] transition-all duration-200"
                  style="background-image:url(/images/challenges/limbo/og.png)"
                  navigate={~p"/challenges/limbo"}
                >
                </.link>
                <div class="flex items-center justify-center gap-1 mt-4 text-base font-medium text-foreground">
                  <span>Sponsored by</span>
                  <img src="/images/wordmarks/turso-aqua.svg" alt="Turso" class="h-6" />
                </div>
              </div>
              <div class="flex flex-col">
                <div class="relative">
                  <.link
                    class="group relative flex aspect-[1200/630] flex-1 rounded-2xl border-2 border-solid border-border bg-cover hover:no-underline hover:scale-[1.02] transition-all duration-200 opacity-75 hover:opacity-100"
                    style="background-image:url(/images/challenges/atopile/og.png)"
                    navigate={~p"/challenges/atopile"}
                  >
                  </.link>
                  <div class="absolute -top-2 -right-2 bg-orange-900 text-orange-200 text-xs font-semibold px-3 py-1.5 rounded-full border border-orange-700/50 shadow-lg">
                    Coming Soon
                  </div>
                </div>
                <div class="flex items-center justify-center gap-2 mt-4 text-base font-medium text-foreground">
                  <span>Sponsored by</span>
                  <img src="/images/wordmarks/atopile.svg" alt="Atopile" class="h-5" />
                </div>
              </div>
              <div
                class="group relative flex aspect-[1200/630] flex-1 rounded-2xl border-2 border-dashed border-border bg-card hover:no-underline hover:scale-[1.02] transition-all duration-200 hover:border-emerald-400/50 cursor-pointer"
                phx-click="show_challenge_drawer"
              >
                <div class="flex flex-col items-center justify-center w-full h-full text-center p-6">
                  <.icon
                    name="tabler-plus"
                    class="size-12 text-muted-foreground group-hover:text-emerald-400 transition-colors mb-4"
                  />
                  <h3 class="text-lg font-semibold text-foreground group-hover:text-emerald-400 transition-colors mb-2">
                    Create a Challenge
                  </h3>
                  <p class="text-sm text-muted-foreground group-hover:text-foreground transition-colors">
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section class="relative isolate py-16 sm:py-40 dev:bg-zinc-900">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <div class="text-center mb-16">
              <h2 class="font-display text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-semibold tracking-tight text-foreground mb-4 !leading-[1.25]">
                Join the open source economy
              </h2>
              <%!-- <p class="text-lg sm:text-xl text-muted-foreground max-w-3xl mx-auto">
              </p> --%>
            </div>

            <div class="grid grid-cols-1 lg:grid-cols-2 gap-12 items-start">
              <%!-- Left column: Stats --%>
              <div class="space-y-8">
                <%= for stat <- @stats2 do %>
                  <div class="p-8 rounded-2xl bg-card border border-border">
                    <div class="text-4xl sm:text-5xl md:text-6xl font-bold font-display text-emerald-400 mb-3">
                      {stat.value}
                    </div>
                    <div class="text-base sm:text-lg text-muted-foreground">
                      {stat.label}
                    </div>
                  </div>
                <% end %>
              </div>

              <%!-- Right column: GitHub repo and YouTube --%>
              <div class="space-y-8">
                <div>
                  <p class="text-xl font-medium text-muted-foreground mb-2">
                    We're open source!
                  </p>
                </div>
                <.link
                  href="https://github.com/algora-io/algora"
                  target="_blank"
                  rel="noopener"
                  class="group block rounded-2xl overflow-hidden border-2 border-border hover:border-emerald-400/50 transition-all duration-300 hover:shadow-2xl hover:shadow-emerald-400/10"
                >
                  <img
                    src={~p"/images/repo-og.png"}
                    alt="Algora GitHub Repository"
                    class="w-full h-auto aspect-[1200/630]"
                  />
                </.link>

                <div>
                  <p class="text-xl font-medium text-muted-foreground mb-2">
                    OSS Founder Podcast
                  </p>
                </div>
                <.link
                  href="https://www.youtube.com/@algora-io"
                  target="_blank"
                  rel="noopener"
                  class="group block rounded-2xl overflow-hidden border-2 border-border hover:border-red-400/50 transition-all duration-300 hover:shadow-2xl hover:shadow-red-400/10"
                >
                  <img
                    src={~p"/images/screenshots/oss-founder-podcast.png"}
                    alt="OSS Founder Podcast"
                    class="w-full h-full aspect-[1825/775]"
                  />
                </.link>
              </div>
            </div>
          </div>
        </section>

        <section class="relative isolate pb-16 sm:pb-40 bg-black">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="font-display text-4xl sm:text-3xl md:text-4xl lg:text-5xl xl:text-6xl font-semibold tracking-tight text-foreground text-center mb-4 !leading-[1.25]">
              Our journey
            </h2>
            <p class="mt-2 text-lg text-muted-foreground text-center">
              From coding marketplace to the largest open source hiring platform
            </p>

            <div class="mt-12 max-w-4xl mx-auto">
              <div class="relative">
                <div class="absolute left-8 top-0 bottom-0 w-0.5 bg-gradient-to-b from-emerald-400 via-emerald-400/50 to-transparent">
                </div>

                <div class="space-y-12">
                  <div class="relative flex items-start gap-6">
                    <div class="flex-shrink-0 w-16 h-16 bg-emerald-400 rounded-full flex items-center justify-center text-black font-bold text-lg">
                      2022
                    </div>
                    <div class="flex-1 pb-8">
                      <h3 class="text-xl font-semibold text-foreground mb-2">
                        "Uber for Coding" introduced
                      </h3>
                      <p class="text-muted-foreground mb-4">
                        Launched an on-demand marketplace where companies would match with a developer for contract work with a click of a button. The top HN comment branded us "delusional entrepreneurs", and we struggled to make it work for the next 6 months.
                      </p>
                      <.link
                        href="https://news.ycombinator.com/item?id=32129089"
                        target="_blank"
                        class="inline-flex items-center gap-2 text-sm text-foreground/90 hover:text-foreground transition-colors group"
                      >
                        <.icon
                          name="tabler-brand-ycombinator"
                          class="size-5 text-orange-500 group-hover:text-orange-400 transition-colors"
                        /> View HN discussion
                      </.link>
                    </div>
                  </div>

                  <div class="relative flex items-start gap-6">
                    <div class="flex-shrink-0 w-16 h-16 bg-emerald-400 rounded-full flex items-center justify-center text-black font-bold text-lg">
                      2023
                    </div>
                    <div class="flex-1 pb-8">
                      <h3 class="text-xl font-semibold text-foreground mb-2">
                        Open source bounties launched
                      </h3>
                      <p class="text-muted-foreground mb-4">
                        Launched a new platform focused on open source projects with bounties and payments integrated on GitHub. We successfully reduced friction and increased trust for paid open source contributions, and fulfilled our vision of "press a button and get work done".
                      </p>
                      <.link
                        href="https://news.ycombinator.com/item?id=35412226"
                        target="_blank"
                        class="inline-flex items-center gap-2 text-sm text-foreground/90 hover:text-foreground transition-colors group"
                      >
                        <.icon
                          name="tabler-brand-ycombinator"
                          class="size-5 text-orange-500 group-hover:text-orange-400 transition-colors"
                        /> View HN discussion
                      </.link>
                    </div>
                  </div>

                  <div class="relative flex items-start gap-6">
                    <div class="flex-shrink-0 w-16 h-16 bg-emerald-400 rounded-full flex items-center justify-center text-black font-bold text-lg">
                      2024
                    </div>
                    <div class="flex-1 pb-8">
                      <h3 class="text-xl font-semibold text-foreground mb-2">
                        Sustainable & profitable
                      </h3>
                      <p class="text-muted-foreground mb-4">
                        Algora Public Benefit Corporation became a bootstrapped, profitable business. Dozens of customers hired full-time the engineers they met with Algora. We unlocked a bigger adjacent problem to solve: full-time hiring.
                      </p>
                      <.link
                        href="https://news.ycombinator.com/item?id=37769595"
                        target="_blank"
                        class="inline-flex items-center gap-2 text-sm text-foreground/90 hover:text-foreground transition-colors group"
                      >
                        <.icon
                          name="tabler-brand-ycombinator"
                          class="size-5 text-orange-500 group-hover:text-orange-400 transition-colors"
                        /> View HN discussion
                      </.link>
                    </div>
                  </div>

                  <div class="relative flex items-start gap-6">
                    <div class="flex-shrink-0 w-16 h-16 bg-gradient-to-br from-emerald-400 to-emerald-500 rounded-full flex items-center justify-center text-black font-bold text-lg shadow-lg">
                      2025
                    </div>
                    <div class="flex-1">
                      <h3 class="text-xl font-semibold text-foreground mb-2">
                        The future: Uber for hiring
                      </h3>
                      <p class="text-muted-foreground mb-4">
                        Today, companies simply share their job description and receive qualified candidates within hours. We've transformed from a coding marketplace into the most efficient hiring platform for technical talent globally.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section class="relative isolate pb-16 sm:pb-40 bg-black">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="font-display text-xl sm:text-3xl xl:text-6xl font-semibold tracking-tight text-foreground text-center !leading-[1.25]">
              Meet your new teammates today
            </h2>
            <div class="mt-6 sm:mt-10 flex gap-4 justify-center">
              <.button
                navigate={~p"/hire"}
                class="h-10 sm:h-14 rounded-md px-8 sm:px-12 text-sm sm:text-xl"
              >
                Start hiring
              </.button>
              <.button
                navigate={~p"/platform"}
                variant="secondary"
                class="h-10 sm:h-14 rounded-md px-8 sm:px-12 text-sm sm:text-xl"
              >
                Explore platform
              </.button>
            </div>
          </div>
        </section>

        <div class="relative isolate overflow-hidden bg-gradient-to-br from-black to-background">
          <Footer.footer />
        </div>

        <%!-- <section class="relative isolate pt-20 pb-8 sm:pb-12">
          <div class="mx-auto max-w-4xl px-6 lg:px-8 text-center">
            <h1 class="pt-12 sm:pt-20 font-display text-4xl sm:text-5xl md:text-6xl lg:text-8xl font-semibold tracking-tight text-foreground">
              Open source <br />
              <span class="text-emerald-400">tech recruiting</span>
            </h1>
            <p class="mt-4 sm:mt-6 text-sm sm:text-3xl font-medium text-foreground mx-auto">
              Connecting the most prolific open source <br />
              maintainers & contributors with their next jobs.
            </p>
            <div class="mt-12 flex items-center justify-center gap-4 sm:gap-6">
              <.button
                navigate={~p"/hire"}
                class="h-12 sm:h-14 rounded-md px-6 sm:px-12 text-base sm:text-lg"
              >
                Hire with Algora
              </.button>
              <.button
                href={AlgoraWeb.Constants.get(:calendar_url)}
                rel="noopener"
                class="h-12 sm:h-14 rounded-md px-6 sm:px-12 text-base sm:text-lg"
                variant="secondary"
              >
                Talk to us
              </.button>
            </div>
          </div>
        </section> --%>

        <%!-- <section class="relative isolate py-8 sm:py-12">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h3 class="text-center text-sm font-medium text-muted-foreground mb-6">
              Trusted by
            </h3>
            <div class="flex items-center justify-center gap-12 overflow-x-auto scrollbar-thin pb-0">
              <img
                src="/images/wordmarks/coderabbit.svg"
                alt="CodeRabbit"
                class="h-8 shrink-0 saturate-0 hover:saturate-100 transition-all"
              />
              <img
                src="/images/wordmarks/comfy.svg"
                alt="Comfy"
                class="h-6 shrink-0 saturate-0 hover:saturate-100 transition-all"
              />
              <img
                src="/images/wordmarks/lovable.svg"
                alt="Lovable"
                class="h-6 shrink-0 saturate-0 hover:saturate-100 transition-all"
              />
              <div class="flex items-center saturate-0 hover:saturate-100 transition-all">
                <img src="/images/wordmarks/firecrawl.svg" alt="Firecrawl" class="h-10 shrink-0" />
                <img src="/images/wordmarks/firecrawl2.svg" alt="Firecrawl2" class="h-6 shrink-0" />
              </div>
              <img
                src="/images/wordmarks/golem.png"
                alt="Golem"
                class="h-8 shrink-0 saturate-0 hover:saturate-100 transition-all"
              />
              <img
                src="/images/wordmarks/calcom.png"
                alt="Cal.com"
                class="h-6 shrink-0 saturate-0 hover:saturate-100 transition-all"
              />
            </div>
          </div>
        </section> --%>
      </main>
    </div>

    <.modal_video_dialog />
    <.challenge_drawer
      show_challenge_drawer={@show_challenge_drawer}
      challenge_form={@challenge_form}
    />
    """
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

  defp events(assigns) do
    ~H"""
    <ul class="w-full pl-10 relative space-y-8">
      <li :for={{event, index} <- @events |> Enum.with_index()} class="relative">
        <.event_item type={event.type} event={event} last?={index == length(@events) - 1} />
      </li>
    </ul>
    """
  end

  defp event_item(%{type: :transaction} = assigns) do
    assigns = assign(assigns, :transaction, assigns.event.item)

    ~H"""
    <div>
      <div class="relative -ml-[2.75rem]">
        <span
          :if={!@last?}
          class="absolute left-1 top-6 h-full w-0.5 block ml-[2.75rem] bg-muted-foreground/25"
          aria-hidden="true"
        >
        </span>
        <.link
          rel="noopener"
          target="_blank"
          class="w-full group inline-flex"
          href={
            if @transaction.ticket.repository,
              do: @transaction.ticket.url,
              else: ~p"/#{@transaction.linked_transaction.user.handle}/home"
          }
        >
          <div class="w-full relative flex space-x-3">
            <div class="w-full flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
              <div class="w-full flex items-center gap-3">
                <div class="flex -space-x-1 ring-8 ring-black">
                  <span class="relative shrink-0 overflow-hidden flex h-9 w-9 sm:h-12 sm:w-12 items-center justify-center rounded-xl ring-4 bg-gray-950 ring-black">
                    <img
                      class="aspect-square h-full w-full"
                      alt={@transaction.user.name}
                      src={@transaction.user.avatar_url}
                    />
                  </span>
                  <span class="relative shrink-0 overflow-hidden flex h-9 w-9 sm:h-12 sm:w-12 items-center justify-center rounded-xl ring-4 bg-gray-950 ring-black">
                    <img
                      class="aspect-square h-full w-full"
                      alt={@transaction.linked_transaction.user.name}
                      src={@transaction.linked_transaction.user.avatar_url}
                    />
                  </span>
                </div>
                <div class="w-full z-10 flex gap-3 items-start xl:items-end">
                  <p class="text-xs transition-colors text-muted-foreground group-hover:text-foreground/90 sm:text-xl text-left">
                    <span class="font-semibold text-foreground/80 group-hover:text-foreground transition-colors">
                      {@transaction.linked_transaction.user.name}
                    </span>
                    awarded
                    <span class="font-semibold text-foreground/80 group-hover:text-foreground transition-colors">
                      {@transaction.user.name}
                    </span>
                    a
                    <span class={
                      classes([
                        "font-bold font-display transition-colors",
                        cond do
                          @transaction.bounty_id && @transaction.ticket.repository ->
                            "text-success-400 group-hover:text-success-300"

                          @transaction.bounty_id && !@transaction.ticket.repository ->
                            "text-blue-400 group-hover:text-blue-300"

                          true ->
                            "text-red-400 group-hover:text-red-300"
                        end
                      ])
                    }>
                      {Money.to_string!(@transaction.net_amount)}
                      <%= if @transaction.bounty_id do %>
                        <%= if @transaction.ticket.repository do %>
                          bounty
                        <% else %>
                          contract
                        <% end %>
                      <% else %>
                        tip
                      <% end %>
                    </span>
                  </p>
                  <div class="ml-auto xl:ml-0 xl:mb-[2px] whitespace-nowrap text-xs text-muted-foreground sm:text-sm">
                    <time datetime={@transaction.succeeded_at}>
                      {cond do
                        @transaction.bounty_id && !@transaction.ticket.repository ->
                          start_month = Calendar.strftime(@transaction.succeeded_at, "%B")
                          end_date = Date.add(@transaction.succeeded_at, 30)
                          end_month = Calendar.strftime(end_date, "%B")

                          if start_month == end_month do
                            "#{start_month} #{Calendar.strftime(end_date, "%Y")}"
                          else
                            "#{start_month} - #{end_month} #{Calendar.strftime(end_date, "%Y")}"
                          end

                        true ->
                          Algora.Util.time_ago(@transaction.succeeded_at)
                      end}
                    </time>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </.link>
      </div>
    </div>
    """
  end

  defp event_item(%{type: :job} = assigns) do
    assigns = assign(assigns, :job, assigns.event.item)

    ~H"""
    <div :if={@job.user.handle}>
      <div class="relative -ml-[2.75rem]">
        <span
          :if={!@last?}
          class="absolute left-1 top-6 h-full w-0.5 block ml-[2.75rem] bg-muted-foreground/25"
          aria-hidden="true"
        >
        </span>
        <.link
          rel="noopener"
          target="_blank"
          class="w-full group inline-flex"
          href={~p"/#{@job.user.handle}/jobs"}
        >
          <div class="w-full relative flex space-x-3">
            <div class="w-full flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
              <div class="w-full flex items-center gap-3">
                <div class="flex -space-x-1 ring-8 ring-black">
                  <span class="ml-6 relative shrink-0 overflow-hidden flex h-9 w-9 sm:h-12 sm:w-12 items-center justify-center rounded-xl">
                    <img
                      class="aspect-square h-full w-full"
                      alt={@job.user.name}
                      src={@job.user.avatar_url}
                    />
                  </span>
                </div>
                <div class="w-full z-10 flex gap-3 items-start xl:items-end">
                  <p class="text-xs transition-colors text-muted-foreground group-hover:text-foreground/90 sm:text-xl text-left">
                    <span class="font-semibold text-foreground/80 group-hover:text-foreground transition-colors">
                      {@job.user.name}
                    </span>
                    is hiring!
                    <span class="font-semibold text-purple-400 group-hover:text-purple-300 transition-colors">
                      {@job.title}
                    </span>
                  </p>
                  <div class="ml-auto xl:ml-0 xl:mb-[2px] whitespace-nowrap text-xs text-muted-foreground sm:text-sm">
                    <time datetime={@job.inserted_at}>
                      {Algora.Util.time_ago(@job.inserted_at)}
                    </time>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </.link>
      </div>
    </div>
    """
  end

  defp event_item(%{type: :bounty} = assigns) do
    assigns = assign(assigns, :bounty, assigns.event.item)

    ~H"""
    <div>
      <div class="relative -ml-[2.75rem]">
        <span
          :if={!@last?}
          class="absolute left-1 top-6 h-full w-0.5 block ml-[2.75rem] bg-muted-foreground/25"
          aria-hidden="true"
        >
        </span>
        <.link
          rel="noopener"
          target="_blank"
          class="w-full group inline-flex"
          href={
            if @bounty.repository,
              do: @bounty.ticket.url,
              else: ~p"/#{@bounty.owner.handle}/home"
          }
        >
          <div class="w-full relative flex space-x-3">
            <div class="w-full flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
              <div class="w-full flex items-center gap-3">
                <div class="flex -space-x-1 ring-8 ring-black">
                  <span class="ml-6 relative shrink-0 overflow-hidden flex h-9 w-9 sm:h-12 sm:w-12 items-center justify-center rounded-xl bg-gray-950">
                    <img
                      class="aspect-square h-full w-full"
                      alt={@bounty.owner.name}
                      src={@bounty.owner.avatar_url}
                    />
                  </span>
                </div>
                <div class="w-full z-10 flex gap-3 items-start xl:items-end">
                  <p class="text-xs transition-colors text-muted-foreground group-hover:text-foreground/90 sm:text-xl text-left">
                    <span class="font-semibold text-foreground/80 group-hover:text-foreground transition-colors">
                      {@bounty.owner.name}
                    </span>
                    shared a
                    <span class="font-bold font-display transition-colors text-cyan-400 group-hover:text-cyan-300">
                      {Money.to_string!(@bounty.amount)} bounty
                    </span>
                  </p>
                  <div class="ml-auto xl:ml-0 xl:mb-[2px] whitespace-nowrap text-xs text-muted-foreground sm:text-sm">
                    <time datetime={@bounty.inserted_at}>
                      {Algora.Util.time_ago(@bounty.inserted_at)}
                    </time>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </.link>
      </div>
    </div>
    """
  end

  defp event_item(%{type: :ats} = assigns) do
    assigns = assign(assigns, :match, assigns.event.item.match)
    assigns = assign(assigns, :data, assigns.event.item.event)

    ~H"""
    <div>
      <div class="relative -ml-[2.75rem]">
        <span
          :if={!@last?}
          class="absolute left-1 top-6 h-full w-0.5 block ml-[2.75rem] bg-muted-foreground/25"
          aria-hidden="true"
        >
        </span>
        <.link
          rel="noopener"
          target="_blank"
          class="w-full group inline-flex"
          href={"/#{@match.job_posting.user.handle}/home"}
        >
          <div class="w-full relative flex space-x-3">
            <div class="w-full flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
              <div class="w-full flex items-center gap-3">
                <div class="flex -space-x-1 ring-8 ring-black">
                  <span class="relative shrink-0 overflow-hidden flex h-9 w-9 sm:h-12 sm:w-12 items-center justify-center rounded-xl ring-4 bg-gray-950 ring-black">
                    <img
                      class="aspect-square h-full w-full"
                      alt={@match.job_posting.user.name}
                      src={@match.job_posting.user.avatar_url}
                    />
                  </span>
                  <span class="relative shrink-0 overflow-hidden flex h-9 w-9 sm:h-12 sm:w-12 items-center justify-center rounded-xl ring-4 bg-gray-950 ring-black">
                    <img
                      class="aspect-square h-full w-full"
                      alt={@match.user.name}
                      src={@match.user.avatar_url}
                    />
                  </span>
                </div>

                <div class="w-full z-10 flex gap-3 items-start xl:items-end">
                  <p class="text-xs transition-colors text-muted-foreground group-hover:text-foreground/90 sm:text-xl text-left">
                    <span class="font-semibold text-foreground/80 group-hover:text-foreground transition-colors">
                      {@match.job_posting.user.name}
                    </span>
                    {Algora.Cloud.label_ats_event(@data["title"]) || " <> "}
                    <span class="font-semibold text-foreground/80 group-hover:text-foreground transition-colors">
                      {@match.user.name}
                    </span>
                  </p>
                  <div class="ml-auto xl:ml-0 xl:mb-[2px] whitespace-nowrap text-xs text-muted-foreground sm:text-sm">
                    <time datetime={@event.timestamp}>
                      {Algora.Util.time_ago(@event.timestamp)}
                    </time>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </.link>
      </div>
    </div>
    """
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
        person_name: "Jiawei Zhang",
        person_avatar: "https://algora-console.t3.storageapi.dev/avatars/jiawei-zhang-a.jpeg",
        person_title: "Senior Applied ML Engineer"
      },
      %{
        company_name: "Comfy",
        company_avatar: "https://avatars.githubusercontent.com/u/166579949?v=4",
        person_name: "David Aguilar",
        person_avatar: "https://algora-console.t3.storageapi.dev/avatars/davvid.jpeg",
        person_title: "Staff AI Cloud Infra Engineer"
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
        company_name: "TraceMachina",
        company_avatar: "https://avatars.githubusercontent.com/u/144973251?s=200&v=4",
        person_name: "Aman",
        person_avatar: "https://avatars.githubusercontent.com/u/53134669?v=4",
        person_title: "Software Engineer",
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

  defp placeholder_text do
    """
    - GitHub looks like a green carpet, red flag if wearing suit
    - Great communication skills, can talk to customers
    - Must be a shark, aggressive, has urgency and agency
    - Has contributions to open source inference engines (like vLLM)
    """
  end
end
