defmodule AlgoraWeb.HomeLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

  import AlgoraWeb.Components.ModalVideo

  alias Algora.Accounts
  alias Algora.Bounties
  alias Algora.Jobs
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

    stats = [
      %{label: "Full-time SWEs Hired", value: "30+"},
      %{label: "1st Year Retention", value: "100%"},
      %{label: "Happy Customers", value: "100+"},
      %{label: "Countries", value: format_number(platform_stats.total_countries)},
      %{label: "Paid Out", value: format_money(platform_stats.total_paid_out)},
      %{label: "Completed Bounties", value: format_number(platform_stats.completed_bounties_count)}
    ]

    # Get company and people avatars for the section
    company_people_examples = get_company_people_examples()

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
         |> assign(:stats, stats)
         |> assign(:jobs_by_user, jobs_by_user)
         |> assign(:orgs_with_stats, orgs_with_stats)
         |> assign(:company_people_examples, company_people_examples)
         |> assign(:show_challenge_drawer, false)
         |> assign(:challenge_form, to_form(ChallengeForm.changeset(%ChallengeForm{}, %{})))
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
        <section class="relative isolate pt-20 pb-8 sm:pb-12">
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
                navigate={~p"/onboarding/org"}
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
        </section>

        <section class="relative isolate py-4 sm:py-12">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-8 text-center">
              <%= for stat <- @stats do %>
                <div>
                  <div class="text-2xl sm:text-3xl md:text-4xl font-bold font-display text-emerald-400">
                    {stat.value}
                  </div>
                  <div class="text-sm sm:text-base text-muted-foreground mt-2">
                    {stat.label}
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </section>

        <section class="relative isolate py-16 sm:pb-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <!-- Special 7th hire - centered on its own row -->
            <div class="flex flex-col md:flex-row md:justify-center gap-8 max-w-6xl mx-auto">
              <%= for example <- @company_people_examples do %>
                <%= if Map.get(example, :special) do %>
                  <div class="relative flex-1 flex mb-12 max-w-md">
                    <div class="truncate flex items-center gap-2 sm:gap-3 p-4 sm:py-6 bg-gradient-to-br from-emerald-900/30 to-emerald-800/20 rounded-xl border-2 border-emerald-400/30 shadow-xl shadow-emerald-400/10 w-full">
                      <img
                        src={example.person_avatar}
                        alt={example.person_name}
                        class="size-8 sm:size-12 rounded-full ring-2 ring-emerald-400/50"
                      />
                      <.icon
                        name="tabler-arrow-right"
                        class="size-3 sm:size-4 text-emerald-400 shrink-0"
                      />
                      <img
                        src={example.company_avatar}
                        alt={example.company_name}
                        class="size-8 sm:size-12 rounded-full ring-2 ring-emerald-400/50"
                      />
                      <div class="flex-1">
                        <div class="text-sm font-medium whitespace-nowrap text-emerald-100">
                          {example.person_name}
                          <.icon name="tabler-arrow-right" class="size-3 text-emerald-400" /> {example.company_name}
                        </div>
                        <div class="text-xs text-emerald-200/80 mt-1">{example.person_title}</div>
                        <div :if={example[:hire_date]} class="text-xs text-emerald-300/70 mt-1">
                          {example.hire_date}
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

                    <%= if String.contains?(example.company_name, "YC") do %>
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
            
    <!-- Regular hire cards grid -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 max-w-6xl mx-auto">
              <%= for example <- @company_people_examples do %>
                <%= unless Map.get(example, :special) do %>
                  <div class="relative flex items-center gap-2 sm:gap-3 p-4 sm:py-6 bg-card rounded-xl border shrink-0">
                    <img
                      src={example.person_avatar}
                      alt={example.person_name}
                      class="size-8 sm:size-12 rounded-full"
                    />
                    <.icon
                      name="tabler-arrow-right"
                      class="size-3 sm:size-4 text-muted-foreground shrink-0"
                    />
                    <img
                      src={example.company_avatar}
                      alt={example.company_name}
                      class="size-8 sm:size-12 rounded-full"
                    />
                    <div class="flex-1">
                      <div class="text-sm font-medium whitespace-nowrap">
                        {example.person_name}
                        <.icon name="tabler-arrow-right" class="size-3 text-foreground" /> {example.company_name}
                      </div>
                      <div class="text-xs text-muted-foreground mt-1">{example.person_title}</div>
                    </div>
                    <%= if String.contains?(example.company_name, "Permit.io") or String.contains?(example.company_name, "Prefix.dev") or String.contains?(example.company_name, "Twenty") do %>
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

                    <%= if String.contains?(example.company_name, "YC") do %>
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
          </div>
        </section>

        <section class="relative isolate pb-16 sm:pb-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8 pt-24 xl:pt-0">
            <h2 class="mt-4 sm:mt-8 font-display text-2xl sm:text-3xl md:text-4xl lg:text-5xl xl:text-6xl font-semibold tracking-tight text-foreground text-center mb-4 !leading-[1.25]">
              Trusted by <br class="md:hidden" /> open source founders
            </h2>

            <div class="pt-4 sm:pt-8 grid grid-cols-1 md:grid-cols-2 gap-8 px-4">
              <div class="flex-1 mx-auto max-w-xl flex flex-col justify-between border ring-1 ring-border transition-all bg-card group rounded-xl text-card-foreground shadow p-6">
                <figure class="relative flex flex-col h-full">
                  <blockquote class="text-base xl:text-lg font-medium text-foreground/90 flex-grow">
                    <p>
                      "Algora helped us meet Nick, who after being contracted a few months, joined the Trigger founding team full-time.
                    </p>
                    <p class="pt-2 xl:pt-4">
                      It was the <span class="text-success">easiest hire</span>
                      and turned out to be <span class="text-success">very very good</span>."
                    </p>
                  </blockquote>
                  <figcaption class="mt-4 xl:mt-8 flex items-center gap-3 xl:gap-4">
                    <img
                      src="/images/people/eric-allam.jpg"
                      alt="Eric Allam"
                      class="size-12 xl:size-16 rounded-full object-cover bg-gray-800"
                      loading="lazy"
                    />
                    <div>
                      <div class="text-sm xl:text-base font-semibold text-foreground">
                        Eric Allam
                      </div>
                      <div class="text-xs xl:text-sm text-foreground/90 font-medium">
                        Co-founder & CTO
                      </div>
                      <div class="text-xs xl:text-sm text-foreground/90 font-medium">
                        Trigger.dev <span class="text-orange-400">(YC W23)</span>
                      </div>
                    </div>
                  </figcaption>
                </figure>
              </div>

              <div class="flex-1 mx-auto max-w-xl flex flex-col justify-between border ring-1 ring-border transition-all bg-card group rounded-xl text-card-foreground shadow p-6">
                <figure class="relative flex flex-col h-full">
                  <blockquote class="text-base xl:text-lg font-medium text-foreground/90 flex-grow">
                    <p>
                      "Algora helped us meet Gergő and I
                      <span class="text-success">couldn't be happier</span>
                      with the results. He's been working full-time with us for
                      <span class="text-success">over a year</span>
                      now and is a key contributor to our product.
                    </p>

                    <p class="pt-2 xl:pt-4">
                      I think you realized this by now, but you have such a
                      <span class="text-success">powerful sourcing/hiring engine</span>
                      in your hands!"
                    </p>
                  </blockquote>
                  <figcaption class="mt-4 xl:mt-8 flex items-center gap-3 xl:gap-4">
                    <img
                      src="/images/people/nicolas-camara.jpg"
                      alt="Nicolas Camara"
                      class="size-12 xl:size-16 rounded-full object-cover bg-gray-800"
                      loading="lazy"
                    />
                    <div>
                      <div class="text-sm xl:text-base font-semibold text-foreground">
                        Nicolas Camara
                      </div>
                      <div class="text-xs xl:text-sm text-foreground/90 font-medium">
                        Co-founder & CEO
                      </div>
                      <div class="text-xs xl:text-sm text-foreground/90 font-medium">
                        Firecrawl <span class="text-orange-400">(YC S22)</span>
                      </div>
                    </div>
                  </figcaption>
                </figure>
              </div>

              <div class="flex-1 mx-auto max-w-xl flex flex-col justify-between border ring-1 ring-border transition-all bg-card group rounded-xl text-card-foreground shadow p-6">
                <figure class="relative flex flex-col h-full">
                  <blockquote class="text-base xl:text-lg font-medium text-foreground/90 flex-grow">
                    <p>
                      We used Algora extensively at Ziverge to reward over
                      <span class="text-success font-display">$143,000</span>
                      in <span class="text-success">open source bounties</span>.
                    </p>
                    <p class="pt-2 xl:pt-4">
                      We introduced a whole
                      new generation of contributors to our ecosystem
                      and <span class="text-success">hired multiple engineers</span>.
                    </p>
                  </blockquote>
                  <figcaption class="mt-4 xl:mt-8 flex items-center gap-3 xl:gap-4">
                    <img
                      src={~p"/images/people/john-de-goes-2.jpg"}
                      alt="John A De Goes"
                      class="size-12 xl:size-16 rounded-full object-cover bg-gray-800"
                      loading="lazy"
                    />
                    <div>
                      <div class="text-sm xl:text-base font-semibold text-foreground">
                        John A De Goes
                      </div>
                      <div class="text-xs xl:text-sm text-foreground/90 font-medium">
                        Founder & CEO
                      </div>
                      <div class="text-xs xl:text-sm text-foreground/90 font-medium">
                        Ziverge
                      </div>
                    </div>
                  </figcaption>
                </figure>
              </div>

              <div class="flex-1 mx-auto max-w-xl flex flex-col justify-between border ring-1 ring-border transition-all bg-card group rounded-xl text-card-foreground shadow p-6">
                <figure class="relative flex flex-col h-full">
                  <blockquote class="text-base xl:text-lg font-medium text-foreground/90 flex-grow">
                    <p>
                      "We met Tom through Algora from his contributions to our open source repository. We were so impressed with his work that we <span class="text-success">hired him full-time</span>.
                    </p>
                    <p class="pt-2 xl:pt-4">
                      He's been an <span class="text-success">incredible addition</span>
                      to the team and we're <span class="text-success">super happy</span>
                      with the results."
                    </p>
                  </blockquote>
                  <figcaption class="mt-4 xl:mt-8 flex items-center gap-3 xl:gap-4">
                    <img
                      src="https://avatars.githubusercontent.com/u/2353608?v=4"
                      alt="Marcus Eagan"
                      class="size-12 xl:size-16 rounded-full object-cover bg-gray-800"
                      loading="lazy"
                    />
                    <div>
                      <div class="text-sm xl:text-base font-semibold text-foreground">
                        Marcus Eagan
                      </div>
                      <div class="text-xs xl:text-sm text-foreground/90 font-medium">
                        Founder & CEO
                      </div>
                      <div class="text-xs xl:text-sm text-foreground/90 font-medium">
                        TraceMachina
                      </div>
                    </div>
                  </figcaption>
                </figure>
              </div>
            </div>
          </div>
        </section>

        <section class="relative isolate pb-16 sm:pb-40">
          <div class="flex flex-col gap-4 px-4 pt-6 sm:pt-10 mx-auto max-w-4xl">
            <div class="mx-auto max-w-7xl px-6 lg:px-8 pt-24 xl:pt-0">
              <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-6xl mb-2 sm:mb-4">
                Community highlights
              </h2>
            </div>
            <.events events={@events} />
          </div>
        </section>

        <section class="relative isolate pb-16 sm:pb-40">
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

        <section class="relative isolate pb-16 sm:pb-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="font-display text-2xl sm:text-3xl md:text-4xl lg:text-5xl xl:text-6xl font-semibold tracking-tight text-foreground text-center mb-2">
              Active bounty programs
            </h2>
            <p class="text-center text-muted-foreground mb-8">
              Contribute to open source and get paid by top companies when your PRs are merged
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

        <section class="relative isolate pb-16 sm:pb-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="font-display text-4xl sm:text-3xl md:text-4xl lg:text-5xl xl:text-6xl font-semibold tracking-tight text-foreground text-center mb-4 !leading-[1.25]">
              Our journey
            </h2>
            <p class="mt-2 text-lg text-muted-foreground text-center">
              From coding marketplace to the largest open source hiring platform
            </p>

            <div class="mt-12 max-w-4xl mx-auto">
              <div class="relative">
                <!-- Timeline line -->
                <div class="absolute left-8 top-0 bottom-0 w-0.5 bg-gradient-to-b from-emerald-400 via-emerald-400/50 to-transparent">
                </div>

                <div class="space-y-12">
                  <!-- 2022 -->
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
                  
    <!-- 2023 -->
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
                  
    <!-- 2024 -->
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
                  
    <!-- 2025 -->
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
                      <div class="inline-flex items-center gap-2 px-4 py-2 bg-emerald-400/10 border border-emerald-400/20 rounded-lg">
                        <.icon name="tabler-rocket" class="size-4 text-emerald-400" />
                        <span class="text-sm font-medium text-emerald-400">
                          New HN launch coming in September
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section class="relative isolate pb-16 sm:pb-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="font-display text-xl sm:text-3xl xl:text-6xl font-semibold tracking-tight text-foreground text-center !leading-[1.25]">
              Meet your new teammates today
            </h2>
            <div class="mt-6 sm:mt-10 flex gap-4 justify-center">
              <.button
                navigate={~p"/onboarding/org"}
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

  defp get_company_people_examples do
    [
      %{
        company_name: "Golem Cloud",
        company_avatar: "https://github.com/golemcloud.png",
        person_name: "Maxim",
        person_avatar: "https://github.com/mschuwalow.png",
        person_title: "Lead Engineer"
      },
      %{
        company_name: "Firecrawl (YC S22)",
        company_avatar: "https://github.com/mendableai.png",
        person_name: "Gergő",
        person_avatar: "https://github.com/mogery.png",
        person_title: "Software Engineer"
      },
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
        company_name: "Trigger.dev (YC W23)",
        company_avatar: "https://github.com/triggerdotdev.png",
        person_name: "Nick",
        person_avatar: "https://github.com/nicktrn.png",
        person_title: "Founding Engineer"
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
        person_title: "Staff Engineer",
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
      |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})

    assign(socket, :events, events)
  end
end
