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

  defp pattern(assigns) do
    ~H"""
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
      <rect width="100%" height="100%" stroke-width="0" fill="url(#grid-pattern)" opacity="0.25" />
    </div>

    <div class="absolute inset-x-0 -z-10 transform overflow-hidden blur-3xl" aria-hidden="true">
      <div
        class="left-[calc(50%+3rem)] aspect-[1155/678] w-[36.125rem] relative -translate-x-1/2 bg-gradient-to-tr from-slate-400 to-secondary opacity-20 sm:left-[calc(50%+36rem)] sm:w-[72.1875rem]"
        style="clip-path: polygon(74.1% 44.1%, 100% 61.6%, 97.5% 26.9%, 85.5% 0.1%, 80.7% 2%, 72.5% 32.5%, 60.2% 62.4%, 52.4% 68.1%, 47.5% 58.3%, 45.2% 34.5%, 27.5% 76.7%, 0.1% 64.9%, 17.9% 100%, 27.6% 76.8%, 76.1% 97.7%, 74.1% 44.1%)"
      >
      </div>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Header.header />

      <main>
        <section class="relative isolate overflow-hidden min-h-screen bg-gradient-to-br from-black to-background">
          <.pattern />
          <!-- Hero content -->
          <div class="mx-auto max-w-7xl px-6 pt-24 pb-12 lg:px-8 xl:pt-20">
            <div class="mx-auto gap-x-14 lg:mx-0 lg:flex lg:max-w-none lg:items-center">
              <div class="xl:pb-20 relative w-full lg:max-w-xl lg:shrink-0 xl:max-w-2xl 2xl:max-w-3xl">
                <h1 class="font-display text-5xl font-semibold tracking-tight text-foreground sm:text-7xl">
                  The open source Upwork for engineers
                </h1>
                <p class="mt-8 font-display text-lg font-medium text-muted-foreground sm:max-w-md sm:text-2xl/8 lg:max-w-none">
                  Discover GitHub bounties, contract work and jobs
                </p>
                <p class="mt-4 font-display text-lg font-medium text-muted-foreground sm:max-w-md sm:text-2xl/8 lg:max-w-none">
                  Hire the top 1% open source developers
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
        </section>

        <section class="relative isolate bg-gradient-to-br from-black to-background border-t py-16 sm:py-32">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-4">
              Fund GitHub Issues
            </h2>
            <p class="text-center font-medium text-base text-muted-foreground mb-8">
              Support open source development with bounties on GitHub issues
            </p>

            <div class="grid grid-cols-1 gap-8">
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
                    Alex Klimaj, Founder of ARK Electronics & Andrew Wilkins, CEO of Ascend Engineering
                  </div>
                </div>
                <.button size="lg" variant="secondary">
                  <Logos.github class="size-4 mr-4 -ml-2" /> View issue
                </.button>
              </.link>

              <div class="relative grid grid-cols-5 items-center w-full gap-x-4 rounded-xl bg-card/50 p-12 ring-2 ring-success/20 hover:bg-card/70 transition-colors">
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

        <section class="relative isolate bg-gradient-to-br from-black to-background border-t py-16 sm:py-32">
          <.pattern />
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-4 leading-loose">
              Y Combinator companies use Algora<br />to build product and hire engineers
            </h2>
            <div class="mx-auto mt-8 max-w-2xl gap-8 text-sm leading-6 sm:mt-10">
              <.yc_logo_cloud />
            </div>
          </div>
        </section>

        <section class="relative isolate bg-gradient-to-br from-black to-background border-t py-16 sm:py-32">
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

        <section class="relative isolate bg-gradient-to-br from-black to-background border-t py-16 sm:py-32">
          <.pattern />
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

        <section class="relative isolate bg-background border-t py-16 sm:py-32">
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

        <div class="relative isolate bg-gradient-to-br from-black to-background">
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
            {:noreply, put_flash(socket, :warning, "You have already created a bounty for this ticket")}

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

  defp format_money(money), do: money |> Money.round(currency_digits: 0) |> Money.to_string!(no_fraction_if_integer: true)

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

  defp yc_logo_cloud(assigns) do
    ~H"""
    <div>
      <div class="grid grid-cols-3 lg:grid-cols-4 items-center justify-center gap-x-5 gap-y-4 sm:gap-x-10 sm:gap-y-8">
        <a class="relative flex items-center justify-center" href={~p"/org/browser-use"}>
          <img
            src="https://raw.githubusercontent.com/browser-use/browser-use/main/static/browser-use-dark.png"
            alt="Browser Use"
            class="col-auto w-full saturate-0"
          />
        </a>
        <a class="relative flex items-center justify-center" href={~p"/org/zio"}>
          <svg
            width="110"
            height="14"
            viewBox="0 0 123 16"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              fill-rule="evenodd"
              clip-rule="evenodd"
              d="M73.862 4.6368C74.3447 4.1028 75.3921 3.2509 77.1721 3.2509C79.7667 3.2509 81.7277 5.8024 81.7321 9.1846C81.7321 13.5714 79.7063 15.9195 76.5946 15.9195C74.6451 15.9195 73.915 14.6081 73.8687 14.5248C73.8674 14.5225 73.8664 14.5208 73.8664 14.5208H73.5431C73.1207 15.2456 72.3277 15.733 71.4183 15.733L68.4617 15.7288C68.3323 15.7288 68.2246 15.6228 68.2246 15.4957V15.0082C68.2246 14.9362 68.2548 14.8684 68.3109 14.826L68.8108 14.4276C69.3581 13.991 69.677 13.3341 69.677 12.6432L69.6814 3.0856C69.6814 2.3905 69.3624 1.7335 68.8108 1.297L68.4143 0.9833C68.2936 0.8858 68.2246 0.7417 68.2246 0.5891V0.5044C68.2246 0.2246 68.453 0 68.7375 0H71.8666C72.9656 0.0042 73.862 0.8816 73.862 1.9666V4.6368ZM75.3706 13.9232C76.1205 13.9232 76.6722 13.3341 77.0084 12.1685C77.323 11.0792 77.3574 9.795 77.3532 9.2906C77.3532 6.5695 76.6463 5.1327 75.3016 5.1327C74.5861 5.1327 73.8577 5.9168 73.8577 6.6882L73.8922 12.2702C73.8922 13.3425 74.6551 13.9232 75.3706 13.9232Z"
              fill="currentColor"
            >
            </path>
            <path
              fill-rule="evenodd"
              clip-rule="evenodd"
              d="M8.03335 0.2C3.60316 0.2 0 3.74183 0 8.09995C0 12.454 3.60316 16 8.03335 16C12.4635 16 16.0667 12.4582 16.0667 8.09995C16.0667 3.74183 12.4635 0.2 8.03335 0.2ZM11.0196 13.5382L10.9793 13.5892C10.5591 14.0952 10.045 14.261 9.68735 14.3077C9.59348 14.3205 9.49961 14.3248 9.4013 14.3248C8.42674 14.3248 7.44325 13.6742 6.5581 12.4369C5.83837 11.4292 5.21251 10.0856 4.79676 8.6527C4.05914 6.0973 4.14408 3.76731 5.01134 2.71287C5.43156 2.20686 5.94566 2.04104 6.30329 1.99429C7.31807 1.85816 8.35521 2.44071 9.294 3.67372C10.0718 4.69425 10.7424 6.10161 11.1895 7.64501C11.9181 10.1622 11.8466 12.4667 11.0196 13.5382Z"
              fill="currentColor"
            >
            </path>
            <path
              d="M42.4345 13.3935C42.1543 13.4825 41.8267 13.5292 41.469 13.5292C40.176 13.5292 39.4046 12.6476 39.4046 11.1726C39.4046 10.5101 39.4126 8.05114 39.4177 6.50448L39.4178 6.4819C39.4201 5.78395 39.4218 5.27668 39.4218 5.2134V4.9591C39.4218 4.9549 39.426 4.9548 39.426 4.9548H41.7406C42.0465 4.9548 42.2922 4.7133 42.2922 4.4123V4.0945C42.2922 3.7935 42.0465 3.5519 41.7406 3.5519H39.4088C39.4046 3.5519 39.4046 3.5477 39.4046 3.5477V1.1276C39.4046 0.775796 39.1158 0.491797 38.758 0.491797H38.4994C38.2495 0.491797 38.0125 0.606196 37.8658 0.805397C37.3831 1.4582 36.06 2.9501 33.7455 3.4587C33.53 3.5307 33.3835 3.7342 33.3835 3.9588V4.3742C33.3835 4.6709 33.6292 4.9125 33.9309 4.9125H35.198C35.2023 4.9125 35.2023 4.9167 35.2023 4.9167V11.961C35.2023 12.9061 35.4825 15.9832 39.1029 15.9832C41.0768 15.9832 42.3741 14.5506 42.8439 13.9361C42.9257 13.8259 42.9387 13.6775 42.8697 13.5546C42.7836 13.4105 42.6026 13.3427 42.4345 13.3935Z"
              fill="currentColor"
            >
            </path>
            <path
              fill-rule="evenodd"
              clip-rule="evenodd"
              d="M43.4471 9.63387C43.4471 6.13297 46.2399 3.28477 49.6707 3.28477C52.9677 3.28477 55.3598 5.95497 55.3555 9.62967C55.3555 9.71447 55.3555 9.80347 55.3512 9.88817C55.3468 10.0323 55.2218 10.1468 55.071 10.1468H47.8475L47.9596 10.4859C48.6017 12.4355 49.9336 13.3807 52.0368 13.3807C53.3384 13.3807 54.1357 13.1476 54.5581 12.9611C54.6659 12.9145 54.7866 12.9441 54.8641 13.0289L54.8685 13.0332C54.9503 13.1306 54.9547 13.2663 54.8771 13.3637C54.4116 13.9741 52.6446 15.9831 49.6707 15.9831C46.2399 15.9831 43.4471 13.1349 43.4471 9.63387ZM48.507 4.67497C47.6018 4.82327 47.2356 6.46357 47.5847 8.76927H51.3688C50.774 6.59917 49.6016 4.49697 48.507 4.67497Z"
              fill="currentColor"
            >
            </path>
            <path
              d="M105.626 8.70137L105.621 8.69968C104.213 8.1536 102.88 7.63637 102.88 6.47197C102.88 5.60736 103.501 5.02666 104.428 5.02666C105.751 5.02666 106.307 6.15407 106.484 6.63727C106.518 6.73477 106.621 6.80256 106.733 6.80687C106.837 6.80687 107.466 6.80686 108.013 6.81106C108.483 6.81106 108.862 6.43386 108.858 5.97606L108.845 4.36976C108.841 3.91626 108.466 3.54746 108.005 3.54746H107.72C107.358 3.54746 107.018 3.71706 106.806 4.00946L106.471 4.47147C106.471 4.47147 105.548 3.29316 103.174 3.29316C100.527 3.29316 98.2902 5.04786 98.2902 7.12896C98.2902 9.97589 100.72 10.7794 102.68 11.4272L102.691 11.431C103.945 11.8421 105.023 12.1981 105.023 13.0458C105.023 13.4654 104.772 13.9655 103.583 13.9655C102.109 13.9655 100.876 12.7279 100.54 12.1642C100.493 12.0837 100.402 12.0328 100.307 12.0328L99.2168 12.0371C98.7944 12.0371 98.454 12.3761 98.454 12.7915V14.9997C98.454 15.4151 98.7944 15.7499 99.2168 15.7542H99.5271C99.8202 15.7542 100.096 15.6312 100.286 15.4151L100.88 14.7369C100.88 14.7369 102.075 15.9957 104.531 15.9957C107.501 15.9957 109.651 14.6267 109.651 12.7406C109.651 10.2654 107.514 9.43466 105.626 8.70137Z"
              fill="currentColor"
            >
            </path>
            <path
              d="M25.3246 3.54336H31.2853C31.5999 3.54336 31.8585 3.79346 31.8542 4.10286C31.8542 4.27236 31.7766 4.43346 31.643 4.53946L31.3888 4.74286C30.7638 5.23876 30.3974 5.98896 30.3974 6.78156V12.4823C30.3974 13.2748 30.7638 14.025 31.3931 14.5252L31.643 14.7244C31.7766 14.8303 31.8542 14.9914 31.8542 15.1609C31.8542 15.4746 31.5956 15.7246 31.281 15.7246H28.514C27.5917 15.7246 26.803 15.1948 26.4323 14.4319L26.1522 14.4362C26.1522 14.4362 24.7471 15.9874 22.5533 15.9874C19.9501 15.9874 18.3037 14.2412 18.3037 11.4354V6.56966C18.2865 5.89576 17.9718 5.26416 17.4374 4.84036L17.0624 4.54366C16.9288 4.43766 16.8512 4.27666 16.8512 4.10706C16.8512 3.79346 17.1098 3.54336 17.4245 3.54336H20.7345C21.7042 3.54336 22.493 4.31906 22.493 5.27266V11.5117C22.493 11.5133 22.4928 11.5149 22.4926 11.5165C22.4923 11.5184 22.4919 11.5202 22.4914 11.522L22.4908 11.5243C22.4897 11.5285 22.4886 11.5328 22.4886 11.5371C22.4973 12.9993 23.2472 13.9445 24.3979 13.9445C25.4841 13.9445 26.1521 12.9866 26.2082 12.9019V6.78576C26.2082 5.99316 25.8418 5.23876 25.2126 4.74286L24.9626 4.54366C24.829 4.43766 24.7514 4.27666 24.7514 4.10706C24.7514 3.79346 25.01 3.54336 25.3246 3.54336Z"
              fill="currentColor"
            >
            </path>
            <path
              d="M65.4149 3.25098C63.9496 3.25098 62.885 4.23428 62.2816 5.45488L61.9928 5.45918L61.9885 5.45488C61.8118 4.37408 60.8635 3.54758 59.7128 3.54758H56.9458C56.6312 3.54758 56.3726 3.79768 56.3726 4.11138C56.3726 4.28088 56.4502 4.44198 56.5838 4.54788L56.9587 4.84458C57.5105 5.28118 57.8294 5.93808 57.8294 6.63318V12.6475C57.8294 13.3384 57.5105 13.9953 56.9631 14.4319L56.5838 14.7328C56.4502 14.8388 56.3726 14.9998 56.3726 15.1694C56.3726 15.4788 56.6269 15.7331 56.9458 15.7331H62.9066C63.2212 15.7331 63.4798 15.483 63.4798 15.1694C63.4798 14.9998 63.4022 14.8388 63.2686 14.7328L62.8935 14.4361C62.3419 13.9996 62.023 13.3426 62.023 12.6475V7.05278C62.023 6.71798 62.3074 6.25598 62.704 6.25598C62.9887 6.25598 63.1994 6.52205 63.4552 6.84495C63.8498 7.34321 64.3516 7.97678 65.3977 7.97678C66.751 7.97678 67.7595 6.93408 67.7595 5.60328C67.7553 4.01388 66.6993 3.25098 65.4149 3.25098Z"
              fill="currentColor"
            >
            </path>
            <path
              fill-rule="evenodd"
              clip-rule="evenodd"
              d="M117.099 3.28477C113.668 3.28477 110.875 6.13297 110.875 9.63387C110.875 13.1349 113.668 15.9831 117.099 15.9831C120.072 15.9831 121.84 13.9741 122.305 13.3637C122.383 13.2663 122.379 13.1306 122.296 13.0332L122.292 13.0289C122.215 12.9441 122.094 12.9145 121.986 12.9611C121.564 13.1476 120.767 13.3807 119.465 13.3807C117.361 13.3807 116.03 12.4355 115.388 10.4859L115.276 10.1468H122.499C122.65 10.1468 122.775 10.0323 122.779 9.88817C122.783 9.80347 122.783 9.71447 122.783 9.62967C122.787 5.95497 120.392 3.28477 117.099 3.28477ZM115.008 8.76927C114.66 6.46357 115.026 4.82327 115.931 4.67497C117.026 4.49697 118.197 6.59917 118.792 8.76927H115.008Z"
              fill="currentColor"
            >
            </path>
            <path
              fill-rule="evenodd"
              clip-rule="evenodd"
              d="M96.6568 4.54368L96.4068 4.74288C95.7776 5.23878 95.4156 5.98898 95.4156 6.78578V12.6433C95.4156 13.3384 95.7345 13.9911 96.2819 14.4277L96.6611 14.7286C96.7948 14.8345 96.8724 14.9956 96.8724 15.1651C96.8724 15.4788 96.6138 15.7288 96.2991 15.7288L92.8813 15.7458C92.4891 15.7458 92.1356 15.5169 91.9805 15.1609L91.5408 14.1522L91.2133 14.1564C91.2133 14.1564 91.2114 14.1593 91.2088 14.1635C91.1314 14.288 90.0758 15.9874 88.0067 15.9874C85.4078 15.9874 83.451 13.4359 83.451 10.0494C83.451 5.92118 85.5242 3.25098 88.7308 3.25098C90.4763 3.25098 91.5279 4.68778 91.5366 4.70048L91.7176 4.95478L92.1787 4.03928C92.3296 3.73408 92.6054 3.54338 92.9718 3.54338H96.2948C96.6138 3.54338 96.868 3.79768 96.868 4.10708C96.868 4.27668 96.7904 4.43768 96.6568 4.54368ZM87.8214 9.61278C87.8214 12.2449 88.5153 13.6351 89.8255 13.6351C90.4978 13.6351 91.1788 12.9357 91.2262 12.2152V11.27L91.2004 6.73068C91.2004 5.69228 90.4591 5.13278 89.7609 5.13278C89.0281 5.13278 88.4894 5.70498 88.1618 6.83238C87.8559 7.88348 87.8214 9.12538 87.8214 9.61278Z"
              fill="currentColor"
            >
            </path>
          </svg>
        </a>
        <a class="relative flex items-center justify-center" href={~p"/org/triggerdotdev"}>
          <img
            src="https://algora.io/banners/triggerdotdev.png"
            alt="Trigger.dev"
            class="col-auto w-full saturate-0"
          />
        </a>
        <a class="relative flex items-center justify-center" href={~p"/org/tembo"}>
          <img
            src="https://cdn.prod.website-files.com/664553b7af7a800a7911b9f0/664553f95f4ec29495eb8eb9_traceloop%20logo%20dark%20bg.png"
            alt="Traceloop"
            class="w-[13rem] col-auto saturate-0"
          />
        </a>
        <a class="relative flex items-center justify-center" href={~p"/org/maybe-finance"}>
          <span class="self-center ml-2 rtl:ml-0 rtl:mr-2 text-lg md:text-2xl font-bold whitespace-nowrap">
            <img
              src="https://cdn.trieve.ai/trieve-logo.png"
              alt="Trieve logo"
              class="h-12 w-12 inline"
            /> Trieve
          </span>
        </a>
        <a class="relative flex items-center justify-center" href={~p"/org/golemcloud"}>
          <span class="self-center ml-2 rtl:ml-0 rtl:mr-2 text-lg md:text-2xl font-bold whitespace-nowrap">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              xmlns:xlink="http://www.w3.org/1999/xlink"
              viewBox="0 0 40 40"
            >
              <g id="ss11151339769_1">
                <path d="M 0 40 L 0 0 L 40 0 L 40 40 Z" fill="transparent" /><path
                  d="M 34.95 0 L 5.05 0 C 2.262 0 0 2.262 0 5.05 L 0 34.95 C 0 37.738 2.262 40 5.05 40 L 34.95 40 C 37.738 40 40 37.738 40 34.95 L 40 5.05 C 40 2.262 37.738 0 34.95 0 Z M 8.021 14.894 C 8.021 12.709 9.794 10.935 11.979 10.935 L 19.6 10.935 C 19.712 10.935 19.815 11.003 19.862 11.106 C 19.909 11.209 19.888 11.329 19.812 11.415 L 18.141 13.229 C 17.85 13.544 17.441 13.726 17.012 13.726 L 12 13.726 C 11.344 13.726 10.812 14.259 10.812 14.915 L 10.812 17.909 C 10.812 18.294 10.5 18.606 10.115 18.606 L 8.721 18.606 C 8.335 18.606 8.024 18.294 8.024 17.909 L 8.024 14.894 Z M 31.729 25.106 C 31.729 27.291 29.956 29.065 27.771 29.065 L 24.532 29.065 C 22.347 29.065 20.574 27.291 20.574 25.106 L 20.574 19.438 C 20.574 19.053 20.718 18.682 20.979 18.397 L 22.868 16.347 C 22.947 16.262 23.071 16.232 23.182 16.274 C 23.291 16.318 23.365 16.421 23.365 16.538 L 23.365 25.088 C 23.365 25.744 23.897 26.276 24.553 26.276 L 27.753 26.276 C 28.409 26.276 28.941 25.744 28.941 25.088 L 28.941 14.915 C 28.941 14.259 28.409 13.726 27.753 13.726 L 24.032 13.726 C 23.606 13.726 23.2 13.906 22.909 14.218 L 11.812 26.276 L 18.479 26.276 C 18.865 26.276 19.176 26.588 19.176 26.974 L 19.176 28.368 C 19.176 28.753 18.865 29.065 18.479 29.065 L 9.494 29.065 C 8.679 29.065 8.018 28.403 8.018 27.588 L 8.018 26.85 C 8.018 26.479 8.156 26.124 8.409 25.85 L 20.85 12.335 C 21.674 11.441 22.829 10.935 24.044 10.935 L 27.768 10.935 C 29.953 10.935 31.726 12.709 31.726 14.894 L 31.726 25.106 Z"
                  fill="rgb(0,0,0)"
                />
              </g>
            </svg>
            Twenty
          </span>
        </a>
        <a class="relative flex items-center justify-center" href={~p"/org/aidenybai"}>
          <img
            src="https://algora.io/banners/million.png"
            alt="Million"
            class="col-auto w-44 saturate-0"
          />
        </a>
        <a class="relative flex items-center justify-center" href={~p"/org/tailcallhq"}>
          <Wordmarks.tailcall class="w-[10rem] col-auto" fill="white" alt="Tailcall" />
        </a>
        <a class="relative flex items-center justify-center" href={~p"/org/highlight"}>
          <img
            src="https://algora.io/banners/highlight.png"
            alt="Highlight"
            class="col-auto w-44 saturate-0"
          />
        </a>
        <a class="relative flex items-center justify-center" href={~p"/org/dittofeed"}>
          <img
            src="https://algora.io/banners/dittofeed.png"
            alt="Dittofeed"
            class="col-auto w-40 brightness-0 invert"
          />
        </a>
      </div>
    </div>
    """
  end
end
