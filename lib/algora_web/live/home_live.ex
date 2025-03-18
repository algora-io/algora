defmodule AlgoraWeb.HomeLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import Ecto.Changeset
  import Ecto.Query
  import Phoenix.LiveView.TagEngine
  import Tails, only: [classes: 1]

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Bounties
  alias Algora.Payments.Transaction
  alias Algora.PSP.ConnectCountries
  alias Algora.Repo
  alias Algora.Workspace
  alias AlgoraWeb.Components.Footer
  alias AlgoraWeb.Components.Header
  alias AlgoraWeb.Components.Logos
  alias AlgoraWeb.Components.Wordmarks
  alias AlgoraWeb.Data.PlatformStats
  alias AlgoraWeb.Forms.BountyForm
  alias AlgoraWeb.Forms.TipForm

  require Logger

  #

  @impl true
  def mount(%{"country_code" => country_code}, _session, socket) do
    Gettext.put_locale(AlgoraWeb.Gettext, Algora.Util.locale_from_country_code(country_code))

    stats = [
      %{label: "Paid Out", value: format_money(get_total_paid_out())},
      %{label: "Completed Bounties", value: format_number(get_completed_bounties_count())},
      %{label: "Contributors", value: format_number(get_contributors_count())},
      %{label: "Countries", value: format_number(get_countries_count())}
    ]

    {:ok,
     socket
     |> assign(:featured_devs, Accounts.list_featured_developers(country_code))
     |> assign(:stats, stats)
     |> assign(:faq_items, get_faq_items())
     |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
     |> assign(:tip_form, to_form(TipForm.changeset(%TipForm{}, %{})))
     |> assign(:pending_action, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Header.header />

      <main>
        <div class="relative isolate overflow-hidden min-h-screen bg-gradient-to-br from-black to-background">
          <!-- Background pattern -->
          <div
            class="absolute inset-x-0 -top-40 -z-10 transform overflow-hidden blur-3xl sm:-top-80"
            aria-hidden="true"
          >
            <div
              class="left-[calc(50%-11rem)] aspect-[1155/678] w-[36.125rem] rotate-[30deg] relative -translate-x-1/2 bg-gradient-to-tr from-slate-400 to-secondary opacity-20 sm:left-[calc(50%-30rem)] sm:w-[72.1875rem]"
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
              class="left-[calc(50%+3rem)] aspect-[1155/678] w-[36.125rem] relative -translate-x-1/2 bg-gradient-to-tr from-slate-400 to-secondary opacity-20 sm:left-[calc(50%+36rem)] sm:w-[72.1875rem]"
              style="clip-path: polygon(74.1% 44.1%, 100% 61.6%, 97.5% 26.9%, 85.5% 0.1%, 80.7% 2%, 72.5% 32.5%, 60.2% 62.4%, 52.4% 68.1%, 47.5% 58.3%, 45.2% 34.5%, 27.5% 76.7%, 0.1% 64.9%, 17.9% 100%, 27.6% 76.8%, 76.1% 97.7%, 74.1% 44.1%)"
            >
            </div>
          </div>
          <!-- Hero content -->
          <div class="mx-auto max-w-7xl px-6 pt-24 pb-12 lg:px-8 xl:pt-20 2xl:pt-28">
            <div class="mx-auto gap-x-14 lg:mx-0 lg:flex lg:max-w-none lg:items-center">
              <div class="relative w-full lg:max-w-xl lg:shrink-0 xl:max-w-2xl 2xl:max-w-3xl">
                <h1 class="font-display text-pretty text-5xl font-semibold tracking-tight text-foreground sm:text-7xl">
                  The open source Upwork for engineers
                </h1>
                <p class="mt-8 font-display text-lg font-medium text-muted-foreground sm:max-w-md sm:text-2xl/8 lg:max-w-none">
                  Discover GitHub bounties, contract work and jobs
                </p>
                <p class="mt-4 font-display text-lg font-medium text-muted-foreground sm:max-w-md sm:text-2xl/8 lg:max-w-none">
                  Hire top 1% of open source developers
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
              <div class="mt-14 flex justify-start md:justify-center gap-8 lg:justify-start lg:mt-0 lg:pl-0 overflow-x-auto scrollbar-thin lg:overflow-x-visible">
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
        </div>

        <section class="bg-gradient-to-br from-black to-background border-t py-16 sm:py-32">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-4">
              Fund GitHub Issues
            </h2>
            <p class="text-center font-medium text-base text-muted-foreground mb-8">
              Support open source development with bounties on GitHub issues
            </p>

            <div class="grid grid-cols-1 gap-4">
              <.link
                href="https://github.com/zed-industries/zed/issues/4440"
                rel="noopener"
                class="relative flex items-center gap-x-4 rounded-xl bg-card/50 p-6 ring-1 ring-border hover:bg-card/70 transition-colors"
              >
                <div class="flex -space-x-4">
                  <img
                    class="h-20 w-20 rounded-full z-0"
                    src="https://github.com/zed-industries.png"
                    alt="Zed"
                  />
                  <img
                    class="h-20 w-20 rounded-full z-10"
                    src="https://github.com/schacon.png"
                    alt="Scott Chacon"
                  />
                </div>
                <div class="text-base leading-6 flex-1">
                  <div class="text-2xl font-semibold text-foreground">
                    GitHub cofounder funds new feature in Zed Editor
                  </div>
                  <div class="text-lg font-medium text-muted-foreground">
                    Zed Editor, Scott Chacon
                  </div>
                </div>
                <.button size="lg" variant="secondary">
                  <Logos.github class="size-4 mr-4 -ml-2" /> View issue
                </.button>
              </.link>

              <.link
                href="https://github.com/PX4/PX4-Autopilot/issues/22464"
                rel="noopener"
                class="relative flex items-center gap-x-4 rounded-xl bg-card/50 p-6 ring-1 ring-border hover:bg-card/70 transition-colors"
              >
                <div class="flex items-center -space-x-6">
                  <img
                    class="h-20 w-20 rounded-full z-0"
                    src="https://pbs.twimg.com/profile_images/1277333515412045824/Xys6F_6E_400x400.jpg"
                    alt="Alex Klimaj"
                  />
                  <img class="h-16 w-16 z-20" src="https://github.com/PX4.png" alt="PX4" />
                  <img
                    class="h-20 w-20 rounded-full z-10"
                    src="https://pbs.twimg.com/profile_images/1768744461243387905/AHYQnqY9_400x400.jpg"
                    alt="Andrew Wilkins"
                  />
                </div>
                <div class="text-base leading-6 flex-1">
                  <div class="text-2xl font-semibold text-foreground">
                    DefenceTech CEOs fund obstacle avoidance in PX4 Drone Autopilot
                  </div>
                  <div class="text-lg font-medium text-muted-foreground">
                    Alex Klimaj, CEO/CTO of ARK Electronics, and Andrew Wilkins, CEO of Ascend Engineering
                  </div>
                </div>
                <.button size="lg" variant="secondary">
                  <Logos.github class="size-4 mr-4 -ml-2" /> View issue
                </.button>
              </.link>

              <div class="relative grid grid-cols-5 items-center w-full gap-x-4 rounded-xl bg-card/50 p-6 ring-2 ring-success/20 hover:bg-card/70 transition-colors">
                <div class="col-span-2 text-base leading-6 flex-1">
                  <div class="text-2xl font-semibold text-foreground">
                    Fund any issue <span class="text-success">in seconds</span>
                  </div>
                  <div class="text-lg font-medium text-muted-foreground">
                    Help improve the OSS you love and rely on
                  </div>
                  <div class="pt-1 col-span-3 text-sm text-muted-foreground space-y-0.5">
                    <div>
                      <.icon name="tabler-check" class="h-4 w-4 mr-1 text-success-400" />
                      Pay when PRs are merged
                    </div>
                    <div>
                      <.icon name="tabler-check" class="h-4 w-4 mr-1 text-success-400" />
                      Pool bounties with other sponsors
                    </div>
                    <div>
                      <.icon name="tabler-check" class="h-4 w-4 mr-1 text-success-400" />
                      Algora handles invoices, payouts, compliance & 1099s
                    </div>
                  </div>
                </div>
                <.form
                  for={@bounty_form}
                  phx-submit="create_bounty"
                  class="col-span-3 grid grid-cols-3 gap-6 w-full"
                >
                  <.input
                    label="URL"
                    field={@bounty_form[:url]}
                    placeholder="https://github.com/owner/repo/issues/1337"
                  />
                  <.input
                    label="Amount"
                    icon="tabler-currency-dollar"
                    field={@bounty_form[:amount]}
                    class="placeholder:text-success"
                  />
                  <div class="flex flex-col items-center gap-2">
                    <div class="text-sm text-muted-foreground">No credit card required</div>
                    <.button size="lg" class="w-full">Fund issue</.button>
                  </div>
                </.form>
              </div>
            </div>
          </div>
        </section>

        <section class="bg-gradient-to-br from-black to-background border-t py-16 sm:py-32">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-4">
              Build product faster
            </h2>
            <p class="text-center font-medium text-base text-muted-foreground mb-12 max-w-2xl mx-auto">
              Use bounties in your own repositories to manage contract work efficiently. Pay only for completed tasks, with full GitHub integration.
            </p>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-5xl mx-auto">
              <div class="flex flex-col items-center text-center">
                <.icon name="tabler-git-pull-request" class="h-12 w-12 mb-4 text-primary" />
                <h3 class="text-lg font-semibold mb-2">Native GitHub Workflow</h3>
                <p class="text-muted-foreground">
                  Work directly in GitHub using issues and pull requests - no context switching needed.
                </p>
              </div>
              <div class="flex flex-col items-center text-center">
                <.icon name="tabler-shield-check" class="h-12 w-12 mb-4 text-primary" />
                <h3 class="text-lg font-semibold mb-2">Secure Payments</h3>
                <p class="text-muted-foreground">
                  Pay only for completed work. No upfront costs - payments are processed after successful code review and merge.
                </p>
              </div>
              <div class="flex flex-col items-center text-center">
                <.icon name="tabler-users" class="h-12 w-12 mb-4 text-primary" />
                <h3 class="text-lg font-semibold mb-2">Global Talent Pool</h3>
                <p class="text-muted-foreground">
                  Access vetted developers from around the world, specialized in your tech stack.
                </p>
              </div>
            </div>
            <div class="mt-10 grid grid-cols-1 gap-4 sm:mt-16 lg:grid-cols-[repeat(14,_minmax(0,_1fr))]">
              <div class="flex p-px lg:col-span-8">
                <div class="w-full overflow-hidden rounded-lg bg-card ring-1 ring-white/15 max-lg:rounded-t-[2rem] lg:rounded-tl-[2rem]">
                  <img
                    class="object-cover object-left"
                    src={~p"/images/screenshots/bounty.png"}
                    alt=""
                  />
                  <div class="p-4 sm:p-6">
                    <h3 class="text-sm/4 font-semibold text-gray-400">Bounties</h3>
                    <p class="mt-2 text-lg font-medium tracking-tight text-white">
                      Fund Issues
                    </p>
                    <p class="mt-2 text-sm/6 text-gray-400">
                      Create bounties on any issue to incentivize solutions and attract talented contributors
                    </p>
                  </div>
                </div>
              </div>
              <div class="flex p-px lg:col-span-6">
                <div class="w-full overflow-hidden rounded-lg bg-card ring-1 ring-white/15 lg:rounded-tr-[2rem]">
                  <img class="object-cover" src={~p"/images/screenshots/tip.png"} alt="" />
                  <div class="p-4 sm:p-6">
                    <h3 class="text-sm/4 font-semibold text-gray-400">Tips</h3>
                    <p class="mt-2 text-lg font-medium tracking-tight text-white">
                      Show Appreciation
                    </p>
                    <p class="mt-2 text-sm/6 text-gray-400">
                      Say thanks with tips to recognize valuable contributions
                    </p>
                  </div>
                </div>
              </div>
              <div class="flex p-px lg:col-span-5">
                <div class="flex flex-col gap-4">
                  <div class="w-full overflow-hidden rounded-lg bg-card ring-1 ring-white/15">
                    <div class="flex object-cover">
                      <div class="flex h-full w-full items-center justify-center gap-x-4 p-4 pb-0 sm:gap-x-6">
                        <div class="flex w-full flex-col space-y-3 sm:w-auto">
                          <div
                            class="w-full items-center rounded-md bg-gradient-to-b from-gray-400 to-gray-800 p-px"
                            style="opacity: 1; transform: translateX(0.2px) translateZ(0px);"
                          >
                            <div class="flex items-center space-x-2 rounded-md bg-gradient-to-b from-gray-800 to-gray-900 p-2">
                              <svg
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 20 20"
                                fill="currentColor"
                                aria-hidden="true"
                                class="h-4 w-4 text-success-500"
                              >
                                <path
                                  fill-rule="evenodd"
                                  d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
                                  clip-rule="evenodd"
                                >
                                </path>
                              </svg>
                              <p class="pb-8 font-sans text-sm text-gray-200 last:pb-0">
                                Merged pull request
                              </p>
                            </div>
                          </div>
                          <div
                            class="w-full items-center rounded-md bg-gradient-to-b from-gray-400 to-gray-800 p-px"
                            style="opacity: 1; transform: translateX(0.2px) translateZ(0px);"
                          >
                            <div class="flex items-center space-x-2 rounded-md bg-gradient-to-b from-gray-800 to-gray-900 p-2">
                              <svg
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 20 20"
                                fill="currentColor"
                                aria-hidden="true"
                                class="h-4 w-4 text-success-500"
                              >
                                <path
                                  fill-rule="evenodd"
                                  d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
                                  clip-rule="evenodd"
                                >
                                </path>
                              </svg>
                              <p class="pb-8 font-sans text-sm text-gray-200 last:pb-0">
                                Completed payment
                              </p>
                            </div>
                          </div>
                          <div
                            class="w-full items-center rounded-md bg-gradient-to-b from-gray-400 to-gray-800 p-px"
                            style="opacity: 0.7; transform: translateX(0.357815px) translateZ(0px);"
                          >
                            <div class="flex items-center space-x-2 rounded-md bg-gradient-to-b from-gray-800 to-gray-900 p-2">
                              <svg
                                width="20"
                                height="20"
                                viewBox="0 0 20 20"
                                fill="none"
                                xmlns="http://www.w3.org/2000/svg"
                                class="h-4 w-4 animate-spin motion-reduce:hidden"
                              >
                                <rect
                                  x="2"
                                  y="2"
                                  width="16"
                                  height="16"
                                  rx="8"
                                  stroke="rgba(59, 130, 246, 0.4)"
                                  stroke-width="3"
                                >
                                </rect>
                                <path
                                  d="M10 18C5.58172 18 2 14.4183 2 10C2 5.58172 5.58172 2 10 2"
                                  stroke="rgba(59, 130, 246)"
                                  stroke-width="3"
                                  stroke-linecap="round"
                                >
                                </path>
                              </svg>
                              <p class="pb-8 font-sans text-sm text-gray-400 last:pb-0">
                                Transferring funds to contributor
                              </p>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                    <div class="p-4 sm:p-6">
                      <h3 class="text-sm/4 font-semibold text-gray-400">Payments</h3>
                      <p class="mt-2 text-lg font-medium tracking-tight text-white">
                        Pay When Merged
                      </p>
                      <p class="mt-2 text-sm/6 text-gray-400">
                        Set up auto-pay to instantly reward contributors as their PRs are merged
                      </p>
                    </div>
                  </div>
                  <div class="w-full overflow-hidden rounded-lg bg-card ring-1 ring-white/15 lg:rounded-bl-[2rem]">
                    <img
                      class="object-cover object-left"
                      src={~p"/images/screenshots/payout-account-compact.png"}
                      alt=""
                    />
                    <div class="p-4 sm:p-6">
                      <h3 class="text-sm/4 font-semibold text-gray-400">Payouts</h3>
                      <p class="mt-2 text-lg font-medium tracking-tight text-white">
                        Fast, Global Payouts
                      </p>
                      <p class="mt-2 text-sm/6 text-gray-400">
                        Receive payments directly to your bank account from all around the world
                        <span class="font-medium text-foreground">(120 countries supported)</span>
                      </p>
                    </div>
                  </div>
                </div>
              </div>
              <div class="flex p-px lg:col-span-9">
                <div class="w-full overflow-hidden rounded-lg bg-card ring-1 ring-white/15 max-lg:rounded-b-[2rem] lg:rounded-br-[2rem]">
                  <img class="object-cover" src={~p"/images/screenshots/contract.png"} alt="" />
                  <div class="p-4 sm:p-6">
                    <h3 class="text-sm/4 font-semibold text-gray-400">Contracts</h3>
                    <p class="mt-2 text-lg font-medium tracking-tight text-white">
                      Flexible Engagement
                    </p>
                    <p class="mt-2 text-sm/6 text-gray-400">
                      Set hourly rates, weekly hours, and payment schedules for ongoing development work. Track progress and manage payments all in one place.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section class="bg-gradient-to-br from-black to-background border-t py-16 sm:py-32">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-4xl text-center mb-4">
              Hire with Confidence
            </h2>
            <p class="text-center font-medium text-base text-muted-foreground mb-12 max-w-2xl mx-auto">
              Find your next team member through real-world collaboration. Use bounties to evaluate developers based on actual contributions to your codebase.
            </p>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-5xl mx-auto">
              <div class="flex flex-col items-center text-center">
                <.icon name="tabler-code" class="h-12 w-12 mb-4 text-primary" />
                <h3 class="text-lg font-semibold mb-2">Try Before You Hire</h3>
                <p class="text-muted-foreground">
                  Evaluate candidates through real contributions to your projects, not just interviews.
                </p>
              </div>
              <div class="flex flex-col items-center text-center">
                <.icon name="tabler-target" class="h-12 w-12 mb-4 text-primary" />
                <h3 class="text-lg font-semibold mb-2">Find Domain Experts</h3>
                <p class="text-muted-foreground">
                  Connect with developers who have proven expertise in your specific tech stack.
                </p>
              </div>
              <div class="flex flex-col items-center text-center">
                <.icon name="tabler-rocket" class="h-12 w-12 mb-4 text-primary" />
                <h3 class="text-lg font-semibold mb-2">Fast Onboarding</h3>
                <p class="text-muted-foreground">
                  Hire developers who are already familiar with your codebase and workflow.
                </p>
              </div>
            </div>
            <div class="mx-auto mt-16 max-w-2xl gap-8 text-sm leading-6 text-gray-900 sm:mt-20 sm:grid-cols-2 lg:mx-0 lg:max-w-none">
              <div class="grid gap-x-12 gap-y-8 lg:grid-cols-7">
                <div class="lg:col-span-3">
                  <div class="relative flex aspect-square w-full items-center justify-center overflow-hidden rounded-xl lg:rounded-2xl bg-gray-800">
                    <iframe
                      src="https://www.youtube.com/embed/xObOGcUdtY0?si=mrHBcTn-Nzj4_okq"
                      title="YouTube video player"
                      frameborder="0"
                      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                      referrerpolicy="strict-origin-when-cross-origin"
                      allowfullscreen
                      width="100%"
                      height="100%"
                    >
                    </iframe>
                  </div>
                </div>
                <div class="lg:col-span-4">
                  <h3 class="text-3xl font-display font-bold text-success">
                    $15,000 Bounty: Delighted by the Results
                  </h3>
                  <div class="relative text-base">
                    <svg
                      viewBox="0 0 162 128"
                      fill="none"
                      aria-hidden="true"
                      class="absolute -top-12 left-0 z-0 h-32 stroke-white/25"
                    >
                      <path
                        id="b56e9dab-6ccb-4d32-ad02-6b4bb5d9bbeb"
                        d="M65.5697 118.507L65.8918 118.89C68.9503 116.314 71.367 113.253 73.1386 109.71C74.9162 106.155 75.8027 102.28 75.8027 98.0919C75.8027 94.237 75.16 90.6155 73.8708 87.2314C72.5851 83.8565 70.8137 80.9533 68.553 78.5292C66.4529 76.1079 63.9476 74.2482 61.0407 72.9536C58.2795 71.4949 55.276 70.767 52.0386 70.767C48.9935 70.767 46.4686 71.1668 44.4872 71.9924L44.4799 71.9955L44.4726 71.9988C42.7101 72.7999 41.1035 73.6831 39.6544 74.6492C38.2407 75.5916 36.8279 76.455 35.4159 77.2394L35.4047 77.2457L35.3938 77.2525C34.2318 77.9787 32.6713 78.3634 30.6736 78.3634C29.0405 78.3634 27.5131 77.2868 26.1274 74.8257C24.7483 72.2185 24.0519 69.2166 24.0519 65.8071C24.0519 60.0311 25.3782 54.4081 28.0373 48.9335C30.703 43.4454 34.3114 38.345 38.8667 33.6325C43.5812 28.761 49.0045 24.5159 55.1389 20.8979C60.1667 18.0071 65.4966 15.6179 71.1291 13.7305C73.8626 12.8145 75.8027 10.2968 75.8027 7.38572C75.8027 3.6497 72.6341 0.62247 68.8814 1.1527C61.1635 2.2432 53.7398 4.41426 46.6119 7.66522C37.5369 11.6459 29.5729 17.0612 22.7236 23.9105C16.0322 30.6019 10.618 38.4859 6.47981 47.558L6.47976 47.558L6.47682 47.5647C2.4901 56.6544 0.5 66.6148 0.5 77.4391C0.5 84.2996 1.61702 90.7679 3.85425 96.8404L3.8558 96.8445C6.08991 102.749 9.12394 108.02 12.959 112.654L12.959 112.654L12.9646 112.661C16.8027 117.138 21.2829 120.739 26.4034 123.459L26.4033 123.459L26.4144 123.465C31.5505 126.033 37.0873 127.316 43.0178 127.316C47.5035 127.316 51.6783 126.595 55.5376 125.148L55.5376 125.148L55.5477 125.144C59.5516 123.542 63.0052 121.456 65.9019 118.881L65.5697 118.507Z"
                      >
                      </path>
                      <use href="#b56e9dab-6ccb-4d32-ad02-6b4bb5d9bbeb" x="86"></use>
                    </svg>
                    <div class="font-medium text-white whitespace-pre-line">
                      We've used Algora extensively at Golem Cloud for our hiring needs and what I have found actually over the course of a few decades of hiring people is that many times someone who is very active in open-source development, these types of engineers often make fantastic additions to a team.

                      Through our $15,000 bounty, we got hundreds of GitHub stars, more than 100 new users on our Discord, and some really fantastic Rust engineers.

                      The bounty system helps us assess real-world skills instead of just technical challenge problems. It's a great way to find talented developers who deeply understand how your system works.
                    </div>
                  </div>
                  <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-8">
                    <div class="flex items-center gap-4">
                      <span class="relative flex h-12 w-12 shrink-0 items-center overflow-hidden rounded-full">
                        <img
                          alt="John A. De Goes"
                          loading="lazy"
                          decoding="async"
                          data-nimg="fill"
                          class="aspect-square h-full w-full"
                          sizes="100vw"
                          src="https://pbs.twimg.com/profile_images/1771489509798236160/jGsCqm25_400x400.jpg"
                          style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                        />
                      </span>
                      <div>
                        <div class="text-base font-medium text-gray-100">John A. De Goes</div>
                        <div class="text-sm text-gray-300">Founder & CEO</div>
                      </div>
                    </div>
                  </div>
                  <dl class="flex flex-wrap items-center gap-x-12 gap-y-4 pt-8 xl:flex-nowrap">
                    <div class="flex flex-col-reverse">
                      <dt class="text-base text-gray-300">Total awarded</dt>
                      <dd class="font-display text-2xl font-semibold tracking-tight text-white">
                        $103,950
                      </dd>
                    </div>
                    <div class="flex flex-col-reverse">
                      <dt class="text-base text-gray-300">Bounties completed</dt>
                      <dd class="font-display text-2xl font-semibold tracking-tight text-white">
                        359
                      </dd>
                    </div>
                    <div class="flex flex-col-reverse">
                      <dt class="text-base text-gray-300">Contributors rewarded</dt>
                      <dd class="font-display text-2xl font-semibold tracking-tight text-white">
                        82
                      </dd>
                    </div>
                  </dl>
                </div>
              </div>
            </div>
            <div class="mx-auto mt-16 max-w-2xl gap-8 text-sm leading-6 text-gray-900 sm:mt-20 sm:grid-cols-2 lg:mx-0 lg:max-w-none">
              <div class="grid gap-x-12 gap-y-8 lg:grid-cols-7">
                <div class="lg:col-span-3 order-last lg:order-first">
                  <h3 class="text-3xl font-display font-bold text-success">
                    From Bounty Contributor<br />To Full-Time Engineer
                  </h3>
                  <div class="relative text-base">
                    <svg
                      viewBox="0 0 162 128"
                      fill="none"
                      aria-hidden="true"
                      class="absolute -top-12 left-0 z-0 h-32 stroke-white/25"
                    >
                      <path
                        id="b56e9dab-6ccb-4d32-ad02-6b4bb5d9bbeb"
                        d="M65.5697 118.507L65.8918 118.89C68.9503 116.314 71.367 113.253 73.1386 109.71C74.9162 106.155 75.8027 102.28 75.8027 98.0919C75.8027 94.237 75.16 90.6155 73.8708 87.2314C72.5851 83.8565 70.8137 80.9533 68.553 78.5292C66.4529 76.1079 63.9476 74.2482 61.0407 72.9536C58.2795 71.4949 55.276 70.767 52.0386 70.767C48.9935 70.767 46.4686 71.1668 44.4872 71.9924L44.4799 71.9955L44.4726 71.9988C42.7101 72.7999 41.1035 73.6831 39.6544 74.6492C38.2407 75.5916 36.8279 76.455 35.4159 77.2394L35.4047 77.2457L35.3938 77.2525C34.2318 77.9787 32.6713 78.3634 30.6736 78.3634C29.0405 78.3634 27.5131 77.2868 26.1274 74.8257C24.7483 72.2185 24.0519 69.2166 24.0519 65.8071C24.0519 60.0311 25.3782 54.4081 28.0373 48.9335C30.703 43.4454 34.3114 38.345 38.8667 33.6325C43.5812 28.761 49.0045 24.5159 55.1389 20.8979C60.1667 18.0071 65.4966 15.6179 71.1291 13.7305C73.8626 12.8145 75.8027 10.2968 75.8027 7.38572C75.8027 3.6497 72.6341 0.62247 68.8814 1.1527C61.1635 2.2432 53.7398 4.41426 46.6119 7.66522C37.5369 11.6459 29.5729 17.0612 22.7236 23.9105C16.0322 30.6019 10.618 38.4859 6.47981 47.558L6.47976 47.558L6.47682 47.5647C2.4901 56.6544 0.5 66.6148 0.5 77.4391C0.5 84.2996 1.61702 90.7679 3.85425 96.8404L3.8558 96.8445C6.08991 102.749 9.12394 108.02 12.959 112.654L12.959 112.654L12.9646 112.661C16.8027 117.138 21.2829 120.739 26.4034 123.459L26.4033 123.459L26.4144 123.465C31.5505 126.033 37.0873 127.316 43.0178 127.316C47.5035 127.316 51.6783 126.595 55.5376 125.148L55.5376 125.148L55.5477 125.144C59.5516 123.542 63.0052 121.456 65.9019 118.881L65.5697 118.507Z"
                      >
                      </path>
                      <use href="#b56e9dab-6ccb-4d32-ad02-6b4bb5d9bbeb" x="86"></use>
                    </svg>
                    <div class="font-medium text-white whitespace-pre-line">
                      We were doing bounties on Algora, and this one developer Nick kept solving them. His personality really came through in the GitHub issues and code. We ended up hiring him from that, and it was the easiest hire because we already knew he was great from his contributions.

                      That's one massive advantage open source companies have versus closed source. When I talk to young people asking for advice, I specifically tell them to go on Algora and find issues there. You get to show people your work, plus you can point to your contributions as proof of your abilities, and you make money in the meantime.
                    </div>
                  </div>
                  <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-8">
                    <div class="flex items-center gap-4">
                      <span class="relative flex h-12 w-12 shrink-0 items-center overflow-hidden rounded-full">
                        <img
                          alt="Eric Allam"
                          loading="lazy"
                          decoding="async"
                          data-nimg="fill"
                          class="aspect-square h-full w-full"
                          sizes="100vw"
                          src="https://pbs.twimg.com/profile_images/1584912680007204865/a_GK3tMi_400x400.jpg"
                          style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                        />
                      </span>
                      <div>
                        <div class="text-base font-medium text-gray-100">Eric Allam</div>
                        <div class="text-sm text-gray-300">Founder & CTO</div>
                      </div>
                    </div>
                    <div class="flex items-center gap-4">
                      <a
                        class="relative flex h-12 w-12 shrink-0 items-center overflow-hidden rounded-xl"
                        href={~p"/org/triggerdotdev"}
                      >
                        <img
                          alt="Trigger.dev"
                          loading="lazy"
                          decoding="async"
                          data-nimg="fill"
                          class="aspect-square h-full w-full"
                          sizes="100vw"
                          src="https://avatars.githubusercontent.com/u/95297378?s=200&v=4"
                          style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                        />
                      </a>
                      <div>
                        <a class="text-base font-medium text-gray-100" href={~p"/org/triggerdotdev"}>
                          Trigger.dev (YC W23)
                        </a>
                        <a
                          class="block text-sm text-gray-300 hover:text-white"
                          target="_blank"
                          rel="noopener"
                          href="https://trigger.dev"
                        >
                          trigger.dev
                        </a>
                      </div>
                    </div>
                  </div>
                  <dl class="flex flex-wrap items-center gap-x-6 gap-y-4 pt-8 xl:flex-nowrap">
                    <div class="flex flex-col-reverse">
                      <dt class="text-base text-gray-300">Total awarded</dt>
                      <dd class="font-display text-2xl font-semibold tracking-tight text-white">
                        $9,920
                      </dd>
                    </div>
                    <div class="flex flex-col-reverse">
                      <dt class="text-base text-gray-300">Bounties completed</dt>
                      <dd class="font-display text-2xl font-semibold tracking-tight text-white">
                        106
                      </dd>
                    </div>
                    <div class="flex flex-col-reverse">
                      <dt class="text-base text-gray-300">Contributors rewarded</dt>
                      <dd class="font-display text-2xl font-semibold tracking-tight text-white">
                        35
                      </dd>
                    </div>
                  </dl>
                </div>
                <div class="lg:col-span-4 order-first lg:order-last">
                  <div class="relative flex aspect-video w-full items-center justify-center overflow-hidden rounded-xl lg:rounded-2xl bg-gray-800">
                    <iframe
                      src="https://www.youtube.com/embed/FXQVD02rfg8?si=rt3r_8-aFt2ZKla8"
                      title="YouTube video player"
                      frameborder="0"
                      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                      referrerpolicy="strict-origin-when-cross-origin"
                      allowfullscreen
                      width="100%"
                      height="100%"
                    >
                    </iframe>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section class="bg-background border-t py-16 sm:py-32">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="mb-8 text-3xl font-bold text-card-foreground text-center">
              <span class="text-muted-foreground">The open source</span>
              <span class="block sm:inline">UpWork on GitHub</span>
            </h2>
            <div class="flex justify-center gap-4">
              <.button navigate="/onboarding/org">
                Start your project
              </.button>
              <.button href="https://cal.com/ioannisflo" variant="secondary">
                Request a demo
              </.button>
            </div>
          </div>
        </section>

        <div class="bg-gradient-to-br from-black to-background">
          <Footer.footer />
          <div class="mx-auto max-w-7xl px-6 pb-4 text-center text-xs text-muted-foreground">
            Upwork® is a registered trademark of Upwork Global Inc. Algora is not affiliated with, sponsored by, or endorsed by Upwork Global Inc, mmmkay?
          </div>
        </div>
      </main>
    </div>
    """
  end

  @impl true
  def handle_event("create_bounty" = event, %{"bounty_form" => params} = unsigned_params, socket) do
    changeset =
      %BountyForm{}
      |> BountyForm.changeset(params)
      |> Map.put(:action, :validate)

    amount = get_field(changeset, :amount)
    ticket_ref = get_field(changeset, :ticket_ref)

    if changeset.valid? do
      if socket.assigns[:current_user] do
        case Bounties.create_bounty(%{
               creator: socket.assigns.current_user,
               owner: socket.assigns.current_user,
               amount: amount,
               ticket_ref: ticket_ref
             }) do
          {:ok, _bounty} ->
            {:noreply,
             socket
             |> put_flash(:info, "Bounty created")
             |> redirect(to: ~p"/")}

          {:error, :already_exists} ->
            {:noreply,
             put_flash(socket, :warning, "You have already created a bounty for this ticket")}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Something went wrong")}
        end
      else
        {:noreply,
         socket
         |> assign(:pending_action, {event, unsigned_params})
         |> push_event("open_popup", %{url: socket.assigns.oauth_url})}
      end
    else
      {:noreply, assign(socket, :bounty_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("create_tip" = event, %{"tip_form" => params} = unsigned_params, socket) do
    changeset =
      %TipForm{}
      |> TipForm.changeset(params)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      if socket.assigns[:current_user] do
        with {:ok, token} <- Accounts.get_access_token(socket.assigns.current_user),
             {:ok, recipient} <-
               Workspace.ensure_user(token, get_field(changeset, :github_handle)),
             {:ok, checkout_url} <-
               Bounties.create_tip(%{
                 creator: socket.assigns.current_user,
                 owner: socket.assigns.current_user,
                 recipient: recipient,
                 amount: get_field(changeset, :amount)
               }) do
          {:noreply, redirect(socket, external: checkout_url)}
        else
          {:error, reason} ->
            Logger.error("Failed to create tip: #{inspect(reason)}")
            {:noreply, put_flash(socket, :error, "Something went wrong")}
        end
      else
        {:noreply,
         socket
         |> assign(:pending_action, {event, unsigned_params})
         |> push_event("open_popup", %{url: socket.assigns.oauth_url})}
      end
    else
      {:noreply, assign(socket, :tip_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_info({:authenticated, user}, socket) do
    socket = assign(socket, :current_user, user)

    case socket.assigns.pending_action do
      {event, params} ->
        socket = assign(socket, :pending_action, nil)
        handle_event(event, params, socket)

      nil ->
        {:noreply, socket}
    end
  end

  defp dev_card(assigns) do
    ~H"""
    <div class="relative">
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
    </div>
    """
  end

  defp get_total_paid_out do
    subtotal =
      Repo.one(
        from t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          select: sum(t.net_amount)
      ) || Money.new(0, :USD)

    subtotal |> Money.add!(PlatformStats.get().extra_paid_out) |> Money.round(currency_digits: 0)
  end

  defp get_completed_bounties_count do
    bounties_subtotal =
      Repo.one(
        from t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          where: not is_nil(t.bounty_id),
          select: count(fragment("DISTINCT (?, ?)", t.bounty_id, t.user_id))
      ) || 0

    tips_subtotal =
      Repo.one(
        from t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          where: not is_nil(t.tip_id),
          select: count(fragment("DISTINCT (?, ?)", t.tip_id, t.user_id))
      ) || 0

    bounties_subtotal + tips_subtotal + PlatformStats.get().extra_completed_bounties
  end

  defp get_contributors_count do
    subtotal =
      Repo.one(
        from t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          select: count(fragment("DISTINCT ?", t.user_id))
      ) || 0

    subtotal + PlatformStats.get().extra_contributors
  end

  defp get_countries_count do
    Repo.one(
      from u in User,
        join: t in Transaction,
        on: t.user_id == u.id,
        where: t.type == :credit,
        where: t.status == :succeeded,
        where: not is_nil(t.linked_transaction_id),
        where: not is_nil(u.country) and u.country != "",
        select: count(fragment("DISTINCT ?", u.country))
    ) || 0
  end

  defp logo_cloud(assigns) do
    assigns =
      assign(
        assigns,
        :orgs,
        Enum.map(
          [
            %{
              name: "ZIO",
              url: "https://zio.dev",
              args: %{
                src: ~p"/images/wordmarks/zio.png",
                class: "mt-4 max-h-10 brightness-0 invert"
              }
            },
            %{
              name: "Tailcall",
              url: "https://tailcall.run",
              component: &Wordmarks.tailcall/1,
              args: %{class: "max-h-12", fill: "#fff"}
            },
            %{name: "Cal.com", url: "https://cal.com", component: &Wordmarks.calcom/1},
            %{
              name: "Qdrant",
              url: "https://qdrant.tech",
              component: &Wordmarks.qdrant/1,
              args: %{class: "max-h-9"}
            },
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

  defp format_money(money),
    do: money |> Money.round(currency_digits: 0) |> Money.to_string!(no_fraction_if_integer: true)

  defp format_number(number), do: Number.Delimit.number_to_delimited(number, precision: 0)

  defmodule FaqItem do
    @moduledoc false
    defstruct [:id, :question, :answer]
  end

  defp get_faq_items do
    [
      %FaqItem{
        id: "platform-fee",
        question: "How do the platform fees work?",
        answer:
          "For organizations, we charge a 19% fee on bounties, which can drop to 7.5% with volume. For individual contributors, you receive 100% of the bounty amount with no fees deducted."
      },
      %FaqItem{
        id: "payment-methods",
        question: "What payment methods do you support?",
        answer:
          ~s(We support payments via Stripe for funding bounties. Contributors can receive payments directly to their bank accounts in <a href="#{AlgoraWeb.Constants.get(:docs_supported_countries_url)}" class="text-success hover:underline">#{ConnectCountries.count()} countries/regions</a> worldwide.)
      },
      %FaqItem{
        id: "payment-process",
        question: "How does the payment process work?",
        answer:
          "There's no upfront payment required for bounties. Organizations can either pay manually after merging pull requests, or save their card with Stripe to enable auto-pay on merge. Manual payments are processed through a secure Stripe hosted checkout page."
      },
      %FaqItem{
        id: "invoices-receipts",
        question: "Do you provide invoices and receipts?",
        answer:
          "Yes, users receive an invoice and receipt after each bounty payment. These documents are automatically generated and delivered to your email."
      },
      %FaqItem{
        id: "tax-forms",
        question: "How are tax forms handled?",
        answer:
          "We partner with Stripe to file and deliver 1099 forms for your US-based freelancers, simplifying tax compliance for organizations working with US contributors."
      },
      %FaqItem{
        id: "payout-time",
        question: "How long do payouts take?",
        answer:
          "Payout timing varies by country, typically ranging from 2-7 business days after a bounty is awarded. Initial payouts for new accounts may take 7-14 days. The exact timing depends on your location, banking system, and account history with Stripe, our payment processor."
      },
      %FaqItem{
        id: "minimum-bounty",
        question: "Is there a minimum bounty amount?",
        answer:
          "There's no strict minimum bounty amount. However, bounties with higher values tend to attract more attention and faster solutions from contributors."
      },
      %FaqItem{
        id: "enterprise-options",
        question: "Do you offer custom enterprise plans?",
        answer:
          ~s(Yes, for larger organizations with specific needs, we offer custom enterprise plans with additional features, dedicated support, and volume-based pricing. Please <a href="https://cal.com/ioannisflo" class="text-success hover:underline">schedule a call with a founder</a> to discuss your requirements.)
      },
      %FaqItem{
        id: "supported-countries",
        question: "Which countries are supported for contributors?",
        answer:
          ~s(We support contributors from #{ConnectCountries.count()} countries/regions worldwide. You can receive payments regardless of your location as long as you have a bank account in one of our supported countries. See the <a href="#{AlgoraWeb.Constants.get(:docs_supported_countries_url)}" class="text-success hover:underline">full list of supported countries</a>.)
      }
    ]
  end
end
