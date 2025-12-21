defmodule AlgoraWeb.HomeLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

  import AlgoraCloud.Components.CandidateCard
  import AlgoraWeb.Components.ModalVideo

  alias Algora.Accounts
  alias Algora.Bounties
  alias Algora.Jobs
  alias Algora.Matches
  alias Algora.Matches.JobMatch
  alias Algora.Payments
  alias AlgoraCloud.LanguageContributions
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

    # Load candidate data
    # candidate_ids = ["1ErYxMGNt6zTfjKS", "qsQa7KN3Cq4PwGWG", "EPYrDRS1ojkjqL9w", "jzwPf2Vn7v8NbM33"]
    candidate_ids = ["1ErYxMGNt6zTfjKS"]

    candidates_data =
      candidate_ids
      |> Enum.map(&load_candidate_data/1)
      |> Enum.reject(&is_nil/1)

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
        <div class="flex flex-col lg:grid lg:grid-cols-[1fr_28rem] lg:gap-8 lg:max-w-[88rem] lg:mx-auto">
          <%!-- Hero section: order-1 on mobile, left column on desktop --%>
          <div class="order-1 lg:order-1 lg:col-start-1">
            <section class="relative isolate min-h-[calc(100vh)]">
              <div class="h-full mx-auto max-w-[88rem] px-6 lg:px-8 flex flex-col items-center justify-center pt-20 lg:pt-32 pb-12">
                <div class="h-full mx-auto lg:mx-0 flex lg:max-w-none items-center justify-center text-center w-full">
                  <div class="w-full flex flex-col lg:items-start text-left lg:text-left">
                    <h1 class="text-5xl xl:text-[3.75rem] font-semibold tracking-tight text-foreground">
                      Open source <br class="block lg:hidden" />
                      <span class="text-emerald-400">tech recruiting</span>
                    </h1>
                    <p class="mt-2 text-lg leading-8 font-medium text-foreground">
                      Connecting the most prolific
                      <span class="hidden lg:inline">open source</span><span class="inline lg:hidden">OSS</span>
                      maintainers & contributors with their next jobs
                    </p>
                    <div class="flex items-center justify-start gap-6 lg:gap-12 overflow-x-auto scrollbar-thin py-4">
                      <img
                        src="/images/wordmarks/coderabbit.svg"
                        alt="CodeRabbit"
                        class="h-6 shrink-0 transition-all"
                      />
                      <img
                        src="/images/wordmarks/comfy.svg"
                        alt="Comfy"
                        class="h-5 shrink-0 transition-all"
                      />
                      <img
                        src="/images/wordmarks/lovable.svg"
                        alt="Lovable"
                        class="h-4 shrink-0 transition-all"
                      />
                      <div class="hidden lg:flex items-center transition-all">
                        <img
                          src="/images/wordmarks/firecrawl.svg"
                          alt="Firecrawl"
                          class="h-6 lg:h-7 shrink-0"
                        />
                        <img
                          src="/images/wordmarks/firecrawl2.svg"
                          alt="Firecrawl2"
                          class="h-3 lg:h-4 shrink-0"
                        />
                      </div>
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
                    <div :if={length(@candidates_data) > 0} class="-ml-2 mt-4 max-w-[48rem] w-full">
                      <div
                        id="candidate-carousel-home"
                        phx-hook="CandidateCarousel"
                        class="relative w-full"
                      >
                        <%= for {candidate_data, index} <- Enum.with_index(@candidates_data) do %>
                          <div
                            data-carousel-item={index}
                            class={"transition-opacity duration-500 #{if index == 0, do: "opacity-100", else: "opacity-0 absolute inset-0"}"}
                          >
                            <AlgoraCloud.Components.CandidateCard.candidate_card {Map.merge(candidate_data, %{anonymize: true, root_class: "h-[30rem]", tech_stack: []})} />
                          </div>
                        <% end %>
                      </div>
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
                </div>
              </div>
            </section>
          </div>

          <%!-- Form: order-2 on mobile, sticky on right on desktop --%>
          <div class="order-2 lg:order-2 lg:col-start-2 lg:row-start-1 lg:self-start px-6 lg:px-0 pb-12 lg:pb-0 lg:pt-32">
            <div class="lg:sticky lg:top-32 text-left">
              <div class="rounded-xl bg-card text-card-foreground shadow-2xl ring-1 ring-white/10">
                <div class="p-6 lg:p-8">
                  <h2 class="text-2xl lg:text-3xl font-semibold leading-7 text-white">
                    View your candidates
                  </h2>
                  <p class="pt-2 text-sm text-muted-foreground">
                    Share <span class="hidden lg:inline">your</span>
                    JD to receive your candidates within hours
                  </p>

                  <form class="mt-6 flex flex-col gap-3">
                    <div>
                      <label class="block text-sm font-semibold text-foreground mb-2">
                        Hire type
                      </label>
                      <div class="grid grid-cols-2 gap-4">
                        <label class="group relative flex cursor-pointer rounded-lg px-3 py-2 shadow-sm focus:outline-none border bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10 border-input has-[:checked]:border-primary has-[:checked]:bg-primary/10">
                          <input type="radio" name="hire_type" value="full_time" class="sr-only" />
                          <div class="flex items-center gap-3">
                            <.icon name="tabler-briefcase" class="h-6 w-6 text-primary shrink-0" />
                            <span class="text-xs text-foreground">
                              Full-time
                            </span>
                          </div>
                        </label>
                        <label class="group relative flex cursor-pointer rounded-lg px-3 py-2 shadow-sm focus:outline-none border bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10 border-input has-[:checked]:border-primary has-[:checked]:bg-primary/10">
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
                      <label class="block text-sm font-semibold text-foreground mb-2">
                        Tech stack
                      </label>
                      <.TechStack
                        tech={@tech_stack}
                        socket={@socket}
                        form="home_form"
                        classes="-mt-2"
                      />
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
                        placeholder="$175k - $330k"
                      />
                    </div>

                    <.input
                      type="textarea"
                      name="job_description"
                      value=""
                      label="Job description / careers URL"
                      rows="3"
                      placeholder="Tell us about the role, requirements, ideal candidate..."
                    />

                    <.input name="email" value="" label="Work email" placeholder="you@company.com" />
                    <div class="flex flex-col gap-4">
                      <.button class="w-full">Receive your candidates</.button>
                    </div>
                  </form>
                </div>
              </div>
            </div>
          </div>

          <%!-- Other sections: order-3 on mobile, left column on desktop --%>
          <div class="order-3 lg:order-1 lg:col-start-1">
            <div class="py-16 sm:py-24 relative">
              <div class="">
                <div class="z-10 relative overflow-hidden px-6 py-20 sm:px-10 sm:py-36 md:px-12 lg:px-20 dark:shadow-none dark:after:pointer-events-none dark:after:absolute dark:after:inset-0 dark:after:inset-ring dark:after:inset-ring-white/10 dark:after:sm:rounded-3xl">
                  <img
                    src="https://algora.io/storage/avatars/coderabbit/sam-hayes-85a0ba25.jpg"
                    alt=""
                    class="absolute inset-0 size-full object-cover object-top brightness-150 saturate-0"
                  />
                  <div class="absolute inset-0 bg-gray-900/90 mix-blend-multiply"></div>
                  <div
                    aria-hidden="true"
                    class="absolute -top-[56px] -left-[80px] transform-gpu blur-3xl"
                  >
                    <div
                      style="clip-path: polygon(74.1% 44.1%, 100% 61.6%, 97.5% 26.9%, 85.5% 0.1%, 80.7% 2%, 72.5% 32.5%, 60.2% 62.4%, 52.4% 68.1%, 47.5% 58.3%, 45.2% 34.5%, 27.5% 76.7%, 0.1% 64.9%, 17.9% 100%, 27.6% 76.8%, 76.1% 97.7%, 74.1% 44.1%)"
                      class="aspect-[1097/845] w-[274.25px] bg-linear-to-r from-[#ff4694] to-[#776fff] opacity-100"
                    >
                    </div>
                  </div>
                  <div
                    aria-hidden="true"
                    class="hidden md:absolute md:bottom-[16px] md:left-[200px] md:block md:transform-gpu md:blur-3xl"
                  >
                    <div
                      style="clip-path: polygon(74.1% 44.1%, 100% 61.6%, 97.5% 26.9%, 85.5% 0.1%, 80.7% 2%, 72.5% 32.5%, 60.2% 62.4%, 52.4% 68.1%, 47.5% 58.3%, 45.2% 34.5%, 27.5% 76.7%, 0.1% 64.9%, 17.9% 100%, 27.6% 76.8%, 76.1% 97.7%, 74.1% 44.1%)"
                      class="aspect-[1097/845] w-[274.25px] bg-linear-to-r from-[#ff4694] to-[#776fff] opacity-100"
                    >
                    </div>
                  </div>
                  <div class="relative mx-auto max-w-2xl lg:mx-0">
                    <img src="/images/wordmarks/coderabbit.svg" alt="CodeRabbit" class="h-12 w-auto" />
                    <figure>
                      <blockquote class="mt-6 text-lg font-semibold text-white sm:text-xl/8">
                        <p>
                          "Within one week of onboarding, we started interviewing qualified candidates interested to join 🐰CodeRabbit in San Francisco"
                        </p>
                      </blockquote>
                      <figcaption class="mt-6 text-base text-white dark:text-gray-200">
                        <div class="font-semibold">Sam Hayes</div>
                        <div class="mt-1">Talent Acquisition Lead at CodeRabbit</div>
                      </figcaption>
                    </figure>
                  </div>
                </div>
              </div>
            </div>

            <%!-- <section class="isolate overflow-hidden px-6 lg:px-8">
          <div class="relative mx-auto max-w-2xl py-24 sm:py-32 lg:max-w-4xl">
            <div class="absolute top-0 left-1/2 -z-10 h-200 w-360 -translate-x-1/2 bg-[radial-gradient(50%_100%_at_top,var(--color-indigo-100),white)] opacity-20 lg:left-36 dark:bg-[radial-gradient(45rem_50rem_at_top,var(--color-indigo-500),transparent)] dark:opacity-10">
            </div>
            <div class="absolute inset-y-0 right-1/2 -z-10 mr-12 w-[150vw] origin-bottom-left skew-x-[-30deg] bg-white shadow-xl ring-1 shadow-indigo-600/10 ring-indigo-50 sm:mr-20 md:mr-0 lg:right-full lg:-mr-36 lg:origin-center dark:bg-gray-900 dark:shadow-2xl dark:shadow-indigo-500/5 dark:ring-white/10">
            </div>
            <figure class="grid grid-cols-1 items-center gap-x-6 gap-y-8 lg:gap-x-10">
              <div class="relative col-span-2 lg:col-start-1 lg:row-start-2">
                <svg
                  viewBox="0 0 162 128"
                  fill="none"
                  aria-hidden="true"
                  class="absolute -top-12 left-0 -z-10 h-32 stroke-gray-900/10 dark:stroke-white/20"
                >
                  <path
                    id="b56e9dab-6ccb-4d32-ad02-6b4bb5d9bbeb"
                    d="M65.5697 118.507L65.8918 118.89C68.9503 116.314 71.367 113.253 73.1386 109.71C74.9162 106.155 75.8027 102.28 75.8027 98.0919C75.8027 94.237 75.16 90.6155 73.8708 87.2314C72.5851 83.8565 70.8137 80.9533 68.553 78.5292C66.4529 76.1079 63.9476 74.2482 61.0407 72.9536C58.2795 71.4949 55.276 70.767 52.0386 70.767C48.9935 70.767 46.4686 71.1668 44.4872 71.9924L44.4799 71.9955L44.4726 71.9988C42.7101 72.7999 41.1035 73.6831 39.6544 74.6492C38.2407 75.5916 36.8279 76.455 35.4159 77.2394L35.4047 77.2457L35.3938 77.2525C34.2318 77.9787 32.6713 78.3634 30.6736 78.3634C29.0405 78.3634 27.5131 77.2868 26.1274 74.8257C24.7483 72.2185 24.0519 69.2166 24.0519 65.8071C24.0519 60.0311 25.3782 54.4081 28.0373 48.9335C30.703 43.4454 34.3114 38.345 38.8667 33.6325C43.5812 28.761 49.0045 24.5159 55.1389 20.8979C60.1667 18.0071 65.4966 15.6179 71.1291 13.7305C73.8626 12.8145 75.8027 10.2968 75.8027 7.38572C75.8027 3.6497 72.6341 0.62247 68.8814 1.1527C61.1635 2.2432 53.7398 4.41426 46.6119 7.66522C37.5369 11.6459 29.5729 17.0612 22.7236 23.9105C16.0322 30.6019 10.618 38.4859 6.47981 47.558L6.47976 47.558L6.47682 47.5647C2.4901 56.6544 0.5 66.6148 0.5 77.4391C0.5 84.2996 1.61702 90.7679 3.85425 96.8404L3.8558 96.8445C6.08991 102.749 9.12394 108.02 12.959 112.654L12.959 112.654L12.9646 112.661C16.8027 117.138 21.2829 120.739 26.4034 123.459L26.4033 123.459L26.4144 123.465C31.5505 126.033 37.0873 127.316 43.0178 127.316C47.5035 127.316 51.6783 126.595 55.5376 125.148L55.5376 125.148L55.5477 125.144C59.5516 123.542 63.0052 121.456 65.9019 118.881L65.5697 118.507Z"
                  />
                  <use x="86" href="#b56e9dab-6ccb-4d32-ad02-6b4bb5d9bbeb" />
                </svg>
                <blockquote class="text-xl/8 font-semibold text-gray-900 sm:text-2xl/9 dark:text-white">
                  <p>
                    Within one week of onboarding, we started interviewing qualified candidates interested to join 🐰CodeRabbit in San Francisco
                  </p>
                </blockquote>
              </div>
              <div class="col-end-1 w-16 lg:row-span-4 lg:w-72">
                <img
                  src="https://algora.io/storage/avatars/coderabbit/sam-hayes-85a0ba25.jpg"
                  alt=""
                  class="rounded-xl bg-indigo-50 lg:rounded-3xl dark:bg-indigo-900/20"
                />
              </div>
              <figcaption class="text-base lg:col-start-1 lg:row-start-3">
                <div class="font-semibold text-gray-900 dark:text-white">Sam Hayes</div>
                <div class="mt-1 text-gray-500 dark:text-gray-400">
                  Talent Acquisition Lead at CodeRabbit
                </div>
              </figcaption>
            </figure>
          </div>
        </section> --%>

            <%!-- <section class="relative isolate py-16 sm:pb-40">
          <div class="max-w-[68rem] mx-auto flex flex-col md:flex-row gap-8 sm:gap-12 px-4">
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
        </section> --%>

            <section class="relative isolate py-16 sm:py-40">
              <div class="mx-auto px-6 lg:px-8 pt-24 xl:pt-0">
                <h2 class="font-display text-4xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-2 sm:mb-4">
                  Hire with Confidence
                </h2>
                <div class="flex flex-col items-center justify-center">
                  <div class="w-full space-y-4 max-w-3xl mx-auto">
                    <div class="mt-6 flex items-center gap-3">
                      <p class="text-foreground text-lg font-medium">
                        <.icon
                          name="tabler-circle-number-1"
                          class="w-8 h-8 mr-1 text-foreground shrink-0"
                        />
                        Share your JDs and receive handpicked candidates with the right skills and experience
                      </p>
                    </div>
                    <img
                      src={~p"/images/screenshots/candidates-page.png"}
                      alt="Candidates page"
                      class="w-full object-cover aspect-[1200/630] rounded-xl border border-border bg-[#121214]"
                      loading="lazy"
                    />
                  </div>
                  <div class="mt-12 w-full space-y-4 max-w-3xl mx-auto">
                    <div class="mt-6 flex items-center gap-3">
                      <p class="text-foreground text-lg font-medium">
                        <.icon
                          name="tabler-circle-number-2"
                          class="w-8 h-8 mr-1 text-foreground shrink-0"
                        /> Get notified in your
                        <div class="w-9 h-9 rounded-lg bg-white/10 border border-border flex items-center justify-center flex-shrink-0">
                          <img
                            src={~p"/images/logos/gmail.png"}
                            alt="Gmail"
                            class="w-5 h-auto aspect-[800/601]"
                          />
                        </div>
                        <span class="font-semibold">Inbox</span>
                        and
                        <div class="w-9 h-9 rounded-lg bg-white/10 border border-border flex items-center justify-center flex-shrink-0">
                          <img src={~p"/images/logos/slack.svg"} alt="Slack" class="w-5 h-5" />
                        </div>
                        <span class="font-semibold">Slack</span>
                        with candidates ready to interview
                      </p>
                    </div>
                    <img
                      src={~p"/images/screenshots/candidate-drip.png"}
                      alt="Candidate drip"
                      class="w-full object-cover aspect-[1008/561] rounded-xl border border-border bg-[#121214] p-1"
                      loading="lazy"
                    />
                  </div>
                  <div class="mt-12 w-full space-y-4 max-w-3xl mx-auto">
                    <div class="mt-6 flex items-center gap-3">
                      <p class="text-foreground text-lg font-medium">
                        <.icon
                          name="tabler-circle-number-3"
                          class="w-8 h-8 mr-1 text-foreground shrink-0"
                        /> Candidates are automatically added to your
                        <div class="w-9 h-9 rounded-lg overflow-hidden border border-border flex items-center justify-center flex-shrink-0">
                          <img
                            src={~p"/images/logos/ashby.png"}
                            alt="Gmail"
                            class="w-full h-full object-cover"
                          />
                        </div>
                        <span class="font-semibold">Ashby</span>
                      </p>
                    </div>
                    <img
                      src={~p"/images/screenshots/ashby.png"}
                      alt="Candidates"
                      class="w-full object-cover aspect-[787/419] rounded-xl border border-border bg-[#121214]"
                      loading="lazy"
                    />
                  </div>

                  <div class="pt-12 sm:pt-24 grid grid-cols-1 gap-12">
                    <div class="max-w-7xl px-6 pt-2">
                      <div class="grid grid-cols-1 md:grid-cols-3 gap-16 text-center">
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
                    <div class="max-w-7xl">
                      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 max-w-6xl mx-auto">
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

                      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 max-w-6xl mx-auto">
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

            <section class="relative isolate py-16 sm:py-40">
              <div class="mx-auto max-w-7xl px-6 lg:px-8 pt-24 xl:pt-0">
                <h2 class="font-display text-4xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-2 sm:mb-4">
                  Publish jobs
                </h2>
                <p class="text-center font-medium text-[15px] text-muted-foreground sm:text-xl mb-12 mx-auto">
                  Reach top 1% users matching your tech, skills, seniority and location preferences
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
            </section>
          </div>
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
                <div class="flex -space-x-1 ring-8 ring-gray-950">
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
                <div class="flex -space-x-1 ring-8 ring-gray-950">
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
                <div class="flex -space-x-1 ring-8 ring-gray-950">
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
                <div class="flex -space-x-1 ring-8 ring-gray-950">
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
        company_name: "Comfy",
        company_avatar: "https://avatars.githubusercontent.com/u/166579949?v=4",
        person_name: "David Aguilar",
        person_avatar: "https://algora-console.t3.storageapi.dev/avatars/davvid.jpeg",
        person_title: "Staff AI Cloud Infra Engineer"
      },
      %{
        company_name: "Golem Cloud",
        company_avatar: "https://github.com/golemcloud.png",
        person_name: "Maxim S",
        person_avatar: "https://github.com/mschuwalow.png",
        person_title: "Lead Engineer"
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
          |> LanguageContributions.list_language_contributions_batch()
          |> transform_language_contributions()

        # Fetch heatmap data for this user
        heatmaps_map =
          [user.id]
          |> AlgoraCloud.Profiles.list_heatmaps()
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

  defp placeholder_text do
    """
    - GitHub looks like a green carpet, red flag if wearing suit
    - Great communication skills, can talk to customers
    - Must be a shark, aggressive, has urgency and agency
    - Has contributions to open source inference engines (like vLLM)
    """
  end
end
