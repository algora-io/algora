defmodule AlgoraWeb.Challenges.PrimeintellectLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Bounties
  alias Algora.Bounties.Bounty
  alias Algora.Organizations
  alias AlgoraWeb.Components.Header

  @impl true
  def mount(_params, _session, socket) do
    primeintellect_org = Organizations.get_org_by_handle!("primeintellect-ai")

    bounties =
      Bounties.list_bounties(
        owner_id: primeintellect_org.id,
        status: :open,
        limit: 100
      )

    total_bounty_amount =
      bounties
      |> Enum.map(& &1.amount)
      |> Enum.reduce(Money.zero(:USD), &Money.add!/2)

    {:ok,
     socket
     |> assign(:page_title, "PrimeIntellect RL Environment Challenge")
     |> assign(
       :page_description,
       "Build RL environments for training AGI models and earn up to $1,000 per environment!"
     )
     |> assign(:page_image, "#{AlgoraWeb.Endpoint.url()}/images/challenges/primeintellect/og.png")
     |> assign(:bounties, bounties)
     |> assign(:bounties_count, length(bounties))
     |> assign(:total_bounty_amount, total_bounty_amount)
     |> assign(:primeintellect_org, primeintellect_org)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative bg-background">
      <div class="absolute top-0 z-10 w-full">
        <Header.header class="max-w-[100rem]" hide_banner />
      </div>
      <main class="relative z-0">
        <article>
          <div class="text-white">
            <div class="relative z-20">
              <section class="mb-24 md:mb-36 min-h-[calc(100svh-36px)] md:min-h-0">
                <div class="relative z-20 mx-auto max-w-[100rem] px-6 lg:px-8">
                  <div class="max-w-5xl pt-24 2xl:pt-72">
                    <a
                      rel="noopener"
                      target="_blank"
                      href="https://primeintellect.ai"
                      class="inline-flex items-center bg-[#1a1a2e]/75 hover:bg-[#09090b] ring-1 ring-[#10b981] hover:ring-[#34d399] py-2 px-4 rounded-full font-medium text-emerald-400/90 hover:text-emerald-400 text-base transition-colors"
                    >
                      <span class="hidden sm:inline">Challenge brought to you by</span><span class="inline sm:hidden">Challenge by</span>
                      <img
                        src={~p"/images/wordmarks/primeintellect-ai.svg"}
                        alt="PrimeIntellect"
                        class="ml-2 h-5"
                        style="aspect-ratio: 945/147;"
                      />
                    </a>
                    <h1 class="mt-6 mb-2 text-[1.4rem] font-black tracking-tighter mix-blend-exclusion sm:text-5xl/[3rem] md:text-6xl/[4rem] lg:text-7xl/[5rem]">
                      Build RL environments for AGI<br />
                      <span style="background: radial-gradient(53.44% 245.78% at 13.64% 46.56%, rgb(16, 185, 129) 0%, rgb(52, 211, 153) 100%) text; -webkit-text-fill-color: transparent;">
                        Earn <span class="font-display">$1,000</span> per contribution
                      </span>
                    </h1>
                    <p class="max-w-xl xl:max-w-2xl mt-4 text-base font-medium tracking-tight text-white/90 shadow-black [text-shadow:_0_1px_0_var(--tw-shadow-color)] md:mt-6 md:text-lg md:text-white/80">
                      PrimeIntellect is pioneering open-source AGI through distributed reinforcement learning training by building the infrastructure to train the next generation of AI models using community-contributed RL environments and verifiers.
                      <br /><br />
                      Join us in creating the diverse ecosystem of evaluation environments needed to train truly capable AI. Build environments that test reasoning, coding, math, science, and more. Help shape the future of AGI training and earn
                      <span class="font-display font-bold text-foreground">$1,000</span>
                      for each accepted RL environment. Together, we're making AGI development open and accessible.
                    </p>
                  </div>
                </div>
                <div class="hidden lg:block top-[0px] absolute inset-0 z-10 h-[calc(100svh-0px)] md:h-[750px] 2xl:h-[900px] bg-gradient-to-r from-background from-[30%] to-transparent to-[90%]">
                </div>
                <div class="hidden lg:block top-[0px] absolute inset-0 z-10 h-[calc(100svh-0px)] md:h-[750px] 2xl:h-[900px] bg-gradient-to-t from-background from-1% to-transparent to-[30%]">
                </div>
                <div class="hidden lg:block top-[0px] absolute inset-0 z-10 h-[calc(100svh-0px)] md:h-[750px] 2xl:h-[900px] bg-gradient-to-b from-background from-1% to-transparent to-[30%]">
                </div>
                <div class="block lg:hidden top-[0px] absolute inset-0 z-10 h-[calc(100svh-0px)] md:h-[750px] 2xl:h-[900px] bg-gradient-to-b from-background from-1% to-transparent to-100%">
                </div>
                <div class="block lg:hidden top-[0px] absolute inset-0 z-10 h-[calc(100svh-0px)] md:h-[750px] 2xl:h-[900px] bg-gradient-to-t from-background from-1% to-transparent to-100%">
                </div>
                <div class="top-[0px] absolute inset-0 z-0 h-[calc(100svh-0px)] md:h-[750px] 2xl:h-[900px]">
                  <img
                    src={~p"/images/challenges/primeintellect/bg.webp"}
                    alt="Background"
                    class="h-full w-full object-cover object-[60%_100%] md:object-[50%_100%] lg:object-[40%_100%] xl:object-[29%_100%] 2xl:object-[20%_100%]"
                    style="aspect-ratio: 2688/1536;"
                  />
                </div>
              </section>
              <section class="md:mb-18 mb-12 xl:pt-20 2xl:pt-52">
                <div class="relative z-50 mx-auto max-w-7xl px-6 pt-6 lg:px-8">
                  <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                    How to participate
                  </h2>
                  <p class="text-center mt-4 text-base font-medium text-gray-200">
                    Got questions?
                    <a
                      target="_blank"
                      class="font-semibold text-white underline"
                      href="https://discord.gg/primeintellect"
                    >
                      Join us on Discord!
                    </a>
                  </p>
                  <ul class="mt-4 md:mt-8 space-y-4 md:space-y-2 mx-auto max-w-6xl">
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-1" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        <a
                          rel="noopener"
                          target="_blank"
                          class="font-semibold text-white underline inline-flex"
                          href="https://github.com/willccbb/verifiers"
                        >
                          Fork the verifiers repository
                        </a>
                        and set up your local development environment
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-2" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Explore existing environments in the
                        <a
                          rel="noopener"
                          target="_blank"
                          class="font-semibold text-white underline inline-flex"
                          href="https://github.com/PrimeIntellect-ai/genesys"
                        >
                          genesys repository
                        </a>
                        and understand the RL environment format
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-3" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Choose an environment to build from our bounty list below - focus on evaluation tasks that test specific cognitive abilities
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-4" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Build your environment with proper reward functions, evaluation metrics, and integration with the RL training pipeline
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-5" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Submit a PR with comprehensive documentation, examples, and test cases - once merged, receive your bounty reward of
                        <span class="font-display font-bold text-emerald-400">$1,000</span>
                      </span>
                    </li>
                  </ul>
                </div>
              </section>
              <section class="mx-auto my-24 max-w-7xl md:my-36">
                <h2 class="flex justify-center text-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                  Available Environment Bounties
                </h2>
                <p class="text-center mt-4 text-base font-medium text-gray-200 mb-8">
                  {@bounties_count} active bounties available totaling {Money.to_string!(
                    @total_bounty_amount
                  )} in rewards. Select a bounty to start building. Each environment should integrate with our RL training infrastructure.
                </p>
                <div class="mx-auto grid gap-6 px-6 sm:grid-cols-2 lg:grid-cols-3 lg:px-8">
                  <%= for {bounty, index} <- Enum.with_index(@bounties) do %>
                    <a
                      href={Bounty.url(bounty)}
                      target="_blank"
                      rel="noopener"
                      class="group relative overflow-hidden rounded-lg border border-border bg-card p-6 transition-all hover:border-emerald-500/50 hover:no-underline block"
                    >
                      <p class="text-sm text-muted-foreground line-clamp-3">
                        {bounty.ticket.title}
                      </p>
                      <div class="mt-4 flex items-center gap-2">
                        <span class="font-display rounded-full bg-emerald-500/10 px-2 py-1 text-xs font-bold text-emerald-500 ring-emerald-500/50 ring-1">
                          {Money.to_string!(bounty.amount)}
                        </span>
                        <span class="font-display rounded-full bg-emerald-500/10 px-2 py-1 text-xs font-bold text-emerald-500 ring-emerald-500/50 ring-1">
                          Active
                        </span>
                      </div>
                    </a>
                  <% end %>
                </div>
                <div class="text-center mt-8">
                  <p class="text-base font-medium text-gray-200">
                    Want to build a different environment? Propose your idea in our
                    <a
                      target="_blank"
                      class="font-semibold text-white underline"
                      href="https://discord.gg/primeintellect"
                    >
                      Discord community
                    </a>
                    <br />
                    <a
                      target="_blank"
                      class="font-semibold text-blue-400 underline inline-flex items-center gap-1 mt-2"
                      href="/primeintellect-ai"
                    >
                      View all 60 available bounties →
                    </a>
                  </p>
                </div>
              </section>
              <section class="mx-auto my-24 max-w-7xl md:my-36">
                <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                  Community Showcase
                </h2>
                <p class="text-center mt-4 text-base font-medium text-gray-200 mb-8">
                  Environments built by our community contributors
                </p>
                <div class="mx-auto grid gap-6 px-6 sm:grid-cols-2 lg:grid-cols-3 lg:px-8">
                  <div class="group relative overflow-hidden rounded-lg border border-border bg-card p-6">
                    <div class="flex items-center gap-4 mb-4">
                      <div class="w-12 h-12 rounded-lg bg-gradient-to-br from-green-400 to-green-600 flex items-center justify-center">
                        <.icon name="tabler-clock" class="w-6 h-6 text-white" />
                      </div>
                      <div>
                        <h3 class="text-lg font-semibold text-foreground">operating-hours</h3>
                        <p class="text-sm text-muted-foreground">by @jared</p>
                      </div>
                    </div>
                    <p class="text-sm text-muted-foreground">
                      Time-based reasoning and scheduling environment with business hours scenarios and temporal calculation verification.
                    </p>
                    <div class="mt-4 flex items-center gap-2">
                      <span class="font-display rounded-full bg-green-500/10 px-2 py-1 text-xs font-bold text-green-500 ring-green-500/50 ring-1">
                        Completed
                      </span>
                      <span class="font-display rounded-full bg-emerald-500/10 px-2 py-1 text-xs font-bold text-emerald-500 ring-emerald-500/50 ring-1">
                        $240
                      </span>
                    </div>
                  </div>
                  <div class="group relative overflow-hidden rounded-lg border border-border bg-card p-6">
                    <div class="flex items-center gap-4 mb-4">
                      <div class="w-12 h-12 rounded-lg bg-gradient-to-br from-purple-400 to-purple-600 flex items-center justify-center">
                        <.icon name="tabler-puzzle" class="w-6 h-6 text-white" />
                      </div>
                      <div>
                        <h3 class="text-lg font-semibold text-foreground">arc-agi</h3>
                        <p class="text-sm text-muted-foreground">by @richard</p>
                      </div>
                    </div>
                    <p class="text-sm text-muted-foreground">
                      Abstract and Reasoning Corpus environment with visual pattern recognition and abstract reasoning challenges.
                    </p>
                    <div class="mt-4 flex items-center gap-2">
                      <span class="font-display rounded-full bg-green-500/10 px-2 py-1 text-xs font-bold text-green-500 ring-green-500/50 ring-1">
                        Completed
                      </span>
                      <span class="font-display rounded-full bg-emerald-500/10 px-2 py-1 text-xs font-bold text-emerald-500 ring-emerald-500/50 ring-1">
                        $1,000
                      </span>
                    </div>
                  </div>
                  <div class="group relative overflow-hidden rounded-lg border border-border bg-card p-6">
                    <div class="flex items-center gap-4 mb-4">
                      <div class="w-12 h-12 rounded-lg bg-gradient-to-br from-emerald-400 to-emerald-600 flex items-center justify-center">
                        <.icon name="tabler-search" class="w-6 h-6 text-white" />
                      </div>
                      <div>
                        <h3 class="text-lg font-semibold text-foreground">search-r1-ish</h3>
                        <p class="text-sm text-muted-foreground">by @carver</p>
                      </div>
                    </div>
                    <p class="text-sm text-muted-foreground">
                      Information retrieval environment with multi-step search tasks and query refinement capabilities.
                    </p>
                    <div class="mt-4 flex items-center gap-2">
                      <span class="font-display rounded-full bg-green-500/10 px-2 py-1 text-xs font-bold text-green-500 ring-green-500/50 ring-1">
                        Completed
                      </span>
                      <span class="font-display rounded-full bg-emerald-500/10 px-2 py-1 text-xs font-bold text-emerald-500 ring-emerald-500/50 ring-1">
                        $360
                      </span>
                    </div>
                  </div>
                </div>
              </section>
              <section class="md:mb-18 mb-12">
                <div class="relative z-50 mx-auto max-w-7xl px-6 pt-6 lg:px-8">
                  <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                    Community Discussions
                  </h2>
                  <div class="mx-auto mt-6 grid max-w-2xl grid-cols-1 grid-rows-1 gap-8 text-sm/6 text-foreground sm:grid-cols-2 xl:mx-0 xl:max-w-none xl:grid-flow-col xl:grid-cols-4">
                    <div class="sm:col-span-2 xl:col-start-2 xl:row-end-1">
                      <figure class="mt-6 rounded-2xl bg-card shadow-lg border-2 border-border hover:border-blue-500/50 transition-colors">
                        <blockquote class="p-6 text-lg font-semibold tracking-tight text-foreground sm:p-12 sm:text-xl/8 whitespace-pre-line -mt-16">
                          <p>
                            The most impactful thing the open-source community can do is to crowdsource tasks & verifier environments. This is a highly parallelizable task, which favors a large community of collaborators.
                          </p>
                        </blockquote>
                        <figcaption class="flex items-center gap-x-2 p-6 sm:p-12 -mt-12 md:-mt-24">
                          <.icon name="tabler-brand-x" class="size-6" />
                          <div>
                            <div class="font-semibold text-foreground">@karpathy</div>
                          </div>
                        </figcaption>
                      </figure>
                    </div>
                    <div class="space-y-8 xl:contents xl:space-y-0">
                      <div class="space-y-8 xl:row-span-2">
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-blue-500/50 transition-colors">
                          <blockquote class="text-foreground whitespace-pre-line -mt-12">
                            <p>
                              building RL envs is nice. doing the same with verifiers/PI is almost addictive. feels like a game lmao, just built my first couple envs on this ecosystem and i don't think i can or want to stop
                            </p>
                          </blockquote>
                          <figcaption class="flex items-center gap-x-2">
                            <.icon name="tabler-brand-x" class="size-6" />
                            <div>
                              <div class="font-semibold text-foreground">
                                @LatentLich
                              </div>
                            </div>
                          </figcaption>
                        </figure>
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-blue-500/50 transition-colors">
                          <blockquote class="text-foreground whitespace-pre-line -mt-12">
                            <p>
                              Love the focus on diverse evaluation environments - this is how we get truly capable AGI.
                            </p>
                          </blockquote>
                          <figcaption class="flex items-center gap-x-2">
                            <.icon name="tabler-brand-discord" class="size-6" />
                            <div>
                              <div class="font-semibold text-foreground">
                                ai_researcher
                              </div>
                            </div>
                          </figcaption>
                        </figure>
                      </div>
                    </div>
                    <div class="space-y-8 xl:contents xl:space-y-0">
                      <div class="space-y-8 xl:row-span-2">
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-blue-500/50 transition-colors">
                          <blockquote class="text-foreground whitespace-pre-line -mt-12">
                            <p>
                              Open source RL training infrastructure is the future - excited to contribute environments!
                            </p>
                          </blockquote>
                          <figcaption class="flex items-center gap-x-2">
                            <.icon name="github" class="size-6" />
                            <div>
                              <div class="font-semibold text-foreground">
                                ml_engineer
                              </div>
                            </div>
                          </figcaption>
                        </figure>
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-blue-500/50 transition-colors">
                          <blockquote class="text-foreground whitespace-pre-line -mt-12">
                            <p>
                              The bounty system makes contributing environments sustainable and rewarding.
                            </p>
                          </blockquote>
                          <figcaption class="flex items-center gap-x-2">
                            <.icon name="github" class="size-6" />
                            <div>
                              <div class="font-semibold text-foreground">
                                contributor
                              </div>
                            </div>
                          </figcaption>
                        </figure>
                      </div>
                    </div>
                  </div>
                </div>
              </section>
              <section class="mx-auto my-24 max-w-7xl md:my-36">
                <div class="relative z-50 mx-auto max-w-7xl px-6 pt-6 lg:px-8">
                  <div class="grid grid-cols-1 gap-6 md:gap-12 sm:grid-cols-2">
                    <div class="flex flex-col gap-6 md:gap-12">
                      <h2 class="text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                        Start contributing
                      </h2>
                      <div class="flex gap-4 sm:gap-6">
                        <.link
                          class="rounded-xl border-2 border-emerald-500 p-3 text-emerald-500 transition-colors hover:border-emerald-400 hover:text-emerald-400 sm:p-5"
                          href="https://discord.gg/primeintellect"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">Discord</span>
                          <.icon name="tabler-brand-discord-filled" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                        <.link
                          class="rounded-xl border-2 border-emerald-500 p-3 text-emerald-500 transition-colors hover:border-emerald-400 hover:text-emerald-400 sm:p-5"
                          href="https://x.com/primeintellect"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">X (formerly Twitter)</span>
                          <.icon name="tabler-brand-x" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                        <.link
                          class="rounded-xl border-2 border-emerald-500 p-3 text-emerald-500 transition-colors hover:border-emerald-400 hover:text-emerald-400 sm:p-5"
                          href="https://github.com/PrimeIntellect-ai"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">GitHub</span>
                          <.icon name="github" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                      </div>
                    </div>
                    <a
                      rel="noopener"
                      target="_blank"
                      href="https://github.com/PrimeIntellect-ai/genesys"
                      class="group/card h-full border border-white/10 bg-black md:gap-8 group relative flex-1 overflow-hidden rounded-xl bg-cover shadow-[0px_3.26536px_2.21381px_0px_rgba(16,_185,_129,_0.08),_0px_7.84712px_5.32008px_0px_rgba(16,_185,_129,_0.11),_0px_14.77543px_10.01724px_0px_rgba(16,_185,_129,_0.14),_0px_26.35684px_17.86905px_0px_rgba(16,_185,_129,_0.16),_0px_49.29758px_33.42209px_0px_rgba(16,_185,_129,_0.19),_0px_118px_80px_0px_rgba(16,_185,_129,_0.27)] hover:no-underline"
                    >
                      <img
                        src="https://fly.storage.tigris.dev/algora-console/repositories/PrimeIntellect-ai/genesys/og.png"
                        alt="PrimeIntellect genesys repository"
                        class="rounded-lg aspect-[1200/630] w-full h-full bg-muted"
                      />
                    </a>
                  </div>
                </div>
              </section>
            </div>
          </div>
        </article>
      </main>
      <footer aria-labelledby="footer-heading">
        <h2 id="footer-heading" class="sr-only">Footer</h2>
        <div class="mx-auto max-w-7xl px-6 pb-8 lg:px-8">
          <div class="flex pt-8 border-white/10 flex-col gap-8 md:items-start md:justify-between md:flex-row border-t">
            <div class="flex flex-col gap-4 md:gap-2">
              <div class="text-sm font-medium leading-5 text-gray-400 md:text-base">
                © 2025 Algora, Public Benefit Corporation
              </div>

              <div class="flex flex-col gap-2">
                <a
                  href="tel:+16504202207"
                  class="flex w-max items-center gap-2 rounded-full border border-gray-700 py-2 pl-2 pr-3.5 text-xs text-muted-foreground hover:text-foreground transition-colors hover:border-gray-600"
                >
                  <span class="tabler-phone-filled size-4"></span>
                  <span>+1 (650) 420-2207</span>
                </a>
              </div>
            </div>
          </div>
        </div>
      </footer>
    </div>
    """
  end
end
