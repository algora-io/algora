defmodule AlgoraWeb.Challenges.ElectricLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias AlgoraWeb.Components.Header

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Electric SQL Challenge")
     |> assign(:page_description, "Build something cool with Electric SQL's real-time sync engine - win $500!")
     |> assign(:page_image, "#{AlgoraWeb.Endpoint.url()}/images/challenges/electric/og.png")}
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
                      href="https://electric-sql.com"
                      class="inline-flex items-center bg-[#1a1a2e]/75 hover:bg-[#16213e] ring-1 ring-[#d1b9fe] hover:ring-[#d1b9fe] py-2 px-4 rounded-full font-medium text-[#d1b9fe]/90 hover:text-[#d1b9fe] text-sm sm:text-base transition-colors"
                    >
                      Challenge brought to you by
                      <img
                        src={~p"/images/wordmarks/electric.svg"}
                        alt="Electric SQL"
                        class="ml-1 h-6 sm:h-7"
                        style="aspect-ratio: 821/240;"
                      />
                    </a>
                    <h1 class="mt-6 mb-2 text-[1.4rem] font-black tracking-tighter mix-blend-exclusion sm:text-5xl/[3rem] md:text-6xl/[4rem] lg:text-6xl/[4rem]">
                      Vibesync with Electric SQL<br />
                      <span style="background: radial-gradient(53.44% 245.78% at 13.64% 46.56%, rgb(29, 254, 238) 0%, rgb(52, 211, 153) 100%) text; -webkit-text-fill-color: transparent;">
                        Win <span class="font-display">$500</span>
                      </span>
                    </h1>
                    <p class="max-w-xl xl:max-w-2xl mt-4 text-base font-medium tracking-tight text-white/90 shadow-black [text-shadow:_0_1px_0_var(--tw-shadow-color)] md:mt-6 md:text-lg md:text-white/80">
                      Electric SQL is a Postgres sync engine that makes real-time data synchronization simple. Build collaborative apps, AI agents with live data, reactive dashboards, or offline-first experiences.
                      <br /><br />
                      We're looking for creative applications that showcase the power of real-time sync - whether it's for <a
                        href="https://electric-sql.com/demos/ai-chat"
                        class="font-semibold text-white underline"
                      >agentic systems</a>, human-in-the-loop AI workflows, reactive data substrates for AI apps, or something else entirely. Show us what's possible when sync just works - from stress testing the engine to building the next generation of collaborative tools. The most innovative projects win <span class="font-display font-bold text-foreground">$500</span>.
                    </p>
                  </div>
                </div>
                <div class="hidden lg:block top-[0px] absolute inset-0 z-10 h-[calc(100svh-0px)] md:h-[750px] 2xl:h-[900px] bg-gradient-to-r from-background from-[25%] to-transparent to-[90%]">
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
                    src={~p"/images/challenges/electric/bg.png"}
                    alt="Background"
                    class="h-full w-full object-cover"
                    style="aspect-ratio: 16/9;"
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
                      href="https://discord.electric-sql.com"
                    >
                      Join us on Discord!
                    </a>
                  </p>
                  <ul class="mt-4 md:mt-8 space-y-4 md:space-y-2 mx-auto max-w-5xl">
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-1" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        <a
                          rel="noopener"
                          target="_blank"
                          class="font-semibold text-white underline inline-flex"
                          href="https://github.com/electric-sql/electric"
                        >
                          Explore Electric SQL
                        </a>
                        and set up your development environment using the quickstart guide
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-2" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Build something creative! Ideas include: AI agents with live data sync, collaborative tools, offline-first apps, reactive dashboards, human-in-the-loop agentic systems, or stress testing Electric's sync engine
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-3" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Document your project with a clear README explaining what you built, how it works, and why it showcases Electric SQL's capabilities
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-4" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Publish your project on GitHub and share it with the community on X. Tag
                        <a href="https://x.com/ElectricSQL" class="font-semibold text-white">
                          @ElectricSQL
                        </a>
                        and include a demo video or live link
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-5" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        The most innovative uses of Electric SQL's real-time sync capabilities win
                        <span class="font-display font-bold text-[#03d1a1]">$500</span>
                      </span>
                    </li>
                  </ul>
                </div>
              </section>
              <section class="md:mb-18 mb-12 xl:pt-20 2xl:pt-52">
                <div class="relative z-50 mx-auto max-w-7xl px-6 pt-6 lg:px-8">
                  <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                    Example Apps
                  </h2>
                  <p class="text-center mt-4 text-base font-medium text-gray-200">
                    Get inspired by what's possible with Electric SQL
                  </p>
                  <div class="mt-8 grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
                    <a
                      href="https://electric-sql.com/demos/ai-chat"
                      target="_blank"
                      rel="noopener"
                      class="group relative overflow-hidden rounded-xl bg-white/5 border border-white/10 p-6 transition-all hover:border-[#d1b9fe]/50 hover:bg-white/10 hover:no-underline"
                    >
                      <div class="flex items-center justify-center mb-4 h-12 w-12 mx-auto">
                        <img
                          src="https://electric-sql.com/img/home/sync-targets/agent.svg"
                          alt="Agents"
                          class="h-12 w-12"
                        />
                      </div>
                      <h3 class="text-lg font-semibold text-center mb-2 text-white">Agents</h3>
                      <p class="text-sm text-gray-400 text-center">
                        Keep AI agents and users in sync
                      </p>
                    </a>
                    <a
                      href="https://electric-sql.com/demos/linearlite"
                      target="_blank"
                      rel="noopener"
                      class="group relative overflow-hidden rounded-xl bg-white/5 border border-white/10 p-6 transition-all hover:border-[#d1b9fe]/50 hover:bg-white/10 hover:no-underline"
                    >
                      <div class="flex items-center justify-center mb-4 h-12 w-12 mx-auto">
                        <img
                          src="https://electric-sql.com/img/home/sync-targets/app.svg"
                          alt="Apps"
                          class="h-12 w-12"
                        />
                      </div>
                      <h3 class="text-lg font-semibold text-center mb-2 text-white">Apps</h3>
                      <p class="text-sm text-gray-400 text-center">
                        Make apps super fast and collaborative
                      </p>
                    </a>
                    <a
                      href="https://electric-sql.com/#dashboard-examples"
                      target="_blank"
                      rel="noopener"
                      class="group relative overflow-hidden rounded-xl bg-white/5 border border-white/10 p-6 transition-all hover:border-[#d1b9fe]/50 hover:bg-white/10 hover:no-underline"
                    >
                      <div class="flex items-center justify-center mb-4 h-12 w-12 mx-auto">
                        <img
                          src="https://electric-sql.com/img/home/sync-targets/dashboard.svg"
                          alt="Dashboards"
                          class="h-12 w-12"
                        />
                      </div>
                      <h3 class="text-lg font-semibold text-center mb-2 text-white">Dashboards</h3>
                      <p class="text-sm text-gray-400 text-center">
                        Build live, real-time dashboards
                      </p>
                    </a>
                    <a
                      href="https://electric-sql.com/docs/integrations/cloudflare"
                      target="_blank"
                      rel="noopener"
                      class="group relative overflow-hidden rounded-xl bg-white/5 border border-white/10 p-6 transition-all hover:border-[#d1b9fe]/50 hover:bg-white/10 hover:no-underline"
                    >
                      <div class="flex items-center justify-center mb-4 h-12 w-12 mx-auto">
                        <img
                          src="https://electric-sql.com/img/home/sync-targets/worker.svg"
                          alt="Workers"
                          class="h-12 w-12"
                        />
                      </div>
                      <h3 class="text-lg font-semibold text-center mb-2 text-white">Workers</h3>
                      <p class="text-sm text-gray-400 text-center">
                        Sync data into workers at the edge
                      </p>
                    </a>
                  </div>
                </div>
              </section>
              <section class="md:mb-18 mb-12 xl:pt-20 2xl:pt-52">
                <div class="relative z-50 mx-auto max-w-7xl px-6 pt-6 lg:px-8">
                  <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                    Use Your Stack
                  </h2>
                  <p class="text-center mt-4 text-base font-medium text-gray-200">
                    Electric SQL works with your favorite frameworks and tools
                  </p>
                  <div class="mt-8 grid grid-cols-2 gap-6 md:grid-cols-3 lg:grid-cols-6">
                    <a href="https://electric-sql.com/docs/integrations/supabase" target="_blank" rel="noopener" class="group relative overflow-hidden rounded-xl bg-white/5 border border-white/10 p-6 transition-all hover:border-[#d1b9fe]/50 hover:bg-white/10 flex flex-col items-center hover:no-underline">
                      <div class="flex items-center justify-center mb-3 h-12 w-12">
                        <img src="https://electric-sql.com/img/integrations/supabase.svg" alt="Supabase" class="h-12 w-12" />
                      </div>
                      <span class="text-sm font-medium text-center text-gray-300">Supabase</span>
                    </a>
                    <a href="https://electric-sql.com/docs/integrations/neon" target="_blank" rel="noopener" class="group relative overflow-hidden rounded-xl bg-white/5 border border-white/10 p-6 transition-all hover:border-[#d1b9fe]/50 hover:bg-white/10 flex flex-col items-center hover:no-underline">
                      <div class="flex items-center justify-center mb-3 h-12 w-12">
                        <img src="https://electric-sql.com/img/integrations/neon.svg" alt="Neon" class="h-12 w-12" />
                      </div>
                      <span class="text-sm font-medium text-center text-gray-300">Neon</span>
                    </a>
                    <a href="https://electric-sql.com/docs/integrations/phoenix" target="_blank" rel="noopener" class="group relative overflow-hidden rounded-xl bg-white/5 border border-white/10 p-6 transition-all hover:border-[#d1b9fe]/50 hover:bg-white/10 flex flex-col items-center hover:no-underline">
                      <div class="flex items-center justify-center mb-3 h-12 w-12">
                        <img src="https://electric-sql.com/img/integrations/phoenix.svg" alt="Phoenix" class="h-12 w-12" />
                      </div>
                      <span class="text-sm font-medium text-center text-gray-300">Phoenix</span>
                    </a>
                    <a href="https://electric-sql.com/docs/integrations/next" target="_blank" rel="noopener" class="group relative overflow-hidden rounded-xl bg-white/5 border border-white/10 p-6 transition-all hover:border-[#d1b9fe]/50 hover:bg-white/10 flex flex-col items-center hover:no-underline">
                      <div class="flex items-center justify-center mb-3 h-12 w-12">
                        <img src="https://electric-sql.com/img/integrations/next.svg" alt="Next.js" class="h-12 w-12" />
                      </div>
                      <span class="text-sm font-medium text-center text-gray-300">Next.js</span>
                    </a>
                    <a href="https://electric-sql.com/docs/integrations/tanstack" target="_blank" rel="noopener" class="group relative overflow-hidden rounded-xl bg-white/5 border border-white/10 p-6 transition-all hover:border-[#d1b9fe]/50 hover:bg-white/10 flex flex-col items-center hover:no-underline">
                      <div class="flex items-center justify-center mb-3 h-12 w-12">
                        <img src="https://electric-sql.com/img/integrations/tanstack.svg" alt="TanStack" class="h-12 w-12" />
                      </div>
                      <span class="text-sm font-medium text-center text-gray-300">TanStack</span>
                    </a>
                    <a href="https://electric-sql.com/docs/integrations/react" target="_blank" rel="noopener" class="group relative overflow-hidden rounded-xl bg-white/5 border border-white/10 p-6 transition-all hover:border-[#d1b9fe]/50 hover:bg-white/10 flex flex-col items-center hover:no-underline">
                      <div class="flex items-center justify-center mb-3 h-12 w-12">
                        <img src="https://electric-sql.com/img/integrations/react.svg" alt="React" class="h-12 w-12" />
                      </div>
                      <span class="text-sm font-medium text-center text-gray-300">React</span>
                    </a>
                  </div>
                </div>
              </section>
              <section class="mx-auto my-24 max-w-7xl md:my-36">
                <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                  Media
                </h2>
                <div class="mx-auto grid gap-6 px-6 sm:grid-cols-2 lg:px-8">
                  <a class="block pt-6 md:pt-12" href="https://www.youtube.com/watch?v=-8UMbnGtbKg">
                    <div class="relative z-30 mx-auto max-w-7xl">
                      <div class="relative mx-auto">
                        <div class="group/card h-full border border-white/10 bg-black md:gap-8 group relative flex-1 overflow-hidden rounded-xl bg-cover shadow-[0px_3.26536px_2.21381px_0px_rgba(69,_10,_10,_0.08),_0px_7.84712px_5.32008px_0px_rgba(69,_10,_10,_0.11),_0px_14.77543px_10.01724px_0px_rgba(69,_10,_10,_0.14),_0px_26.35684px_17.86905px_0px_rgba(69,_10,_10,_0.16),_0px_49.29758px_33.42209px_0px_rgba(69,_10,_10,_0.19),_0px_118px_80px_0px_rgba(69,_10,_10,_0.27)] ring-2 ring-red-500 hover:no-underline">
                          <div class="grid h-6 grid-cols-[1fr_auto_1fr] overflow-hidden border-b border-gray-800 ">
                            <div class="ml-2 flex items-center gap-1">
                              <div class="h-2 w-2 rounded-full bg-red-400"></div>
                              <div class="h-2 w-2 rounded-full bg-yellow-400"></div>
                              <div class="h-2 w-2 rounded-full bg-green-400"></div>
                            </div>
                            <div class="flex items-center justify-center">
                              <div class="text-xs text-gray-500">youtube.com</div>
                            </div>
                            <div></div>
                          </div>
                          <div class="relative flex aspect-[16/9] h-full w-full items-center justify-center text-balance bg-gray-950 text-center text-xl font-medium text-[#d1b9fe] sm:text-2xl">
                            <img
                              src="https://i.ytimg.com/vi/-8UMbnGtbKg/maxresdefault.jpg"
                              alt="How ElectricSQL Works"
                            />
                          </div>
                        </div>
                      </div>
                    </div>
                  </a>
                  <a class="block pt-6 md:pt-12" href="https://www.youtube.com/watch?v=Sn_Ig5n2Oc0">
                    <div class="relative z-30 mx-auto max-w-7xl">
                      <div class="relative mx-auto">
                        <div class="group/card h-full border border-white/10 bg-black md:gap-8 group relative flex-1 overflow-hidden rounded-xl bg-cover shadow-[0px_3.26536px_2.21381px_0px_rgba(69,_10,_10,_0.08),_0px_7.84712px_5.32008px_0px_rgba(69,_10,_10,_0.11),_0px_14.77543px_10.01724px_0px_rgba(69,_10,_10,_0.14),_0px_26.35684px_17.86905px_0px_rgba(69,_10,_10,_0.16),_0px_49.29758px_33.42209px_0px_rgba(69,_10,_10,_0.19),_0px_118px_80px_0px_rgba(69,_10,_10,_0.27)] ring-2 ring-red-500 hover:no-underline">
                          <div class="grid h-6 grid-cols-[1fr_auto_1fr] overflow-hidden border-b border-gray-800 ">
                            <div class="ml-2 flex items-center gap-1">
                              <div class="h-2 w-2 rounded-full bg-red-400"></div>
                              <div class="h-2 w-2 rounded-full bg-yellow-400"></div>
                              <div class="h-2 w-2 rounded-full bg-green-400"></div>
                            </div>
                            <div class="flex items-center justify-center">
                              <div class="text-xs text-gray-500">youtube.com</div>
                            </div>
                            <div></div>
                          </div>
                          <div class="relative flex aspect-[16/9] h-full w-full items-center justify-center text-balance bg-gray-950 text-center text-xl font-medium text-[#d1b9fe] sm:text-2xl">
                            <img
                              src="/images/challenges/electric/thumbnail1.png"
                              alt="ElectricSQL - Local-first SQL with Elixir by James Arthur | ElixirConf EU 2023"
                            />
                          </div>
                        </div>
                      </div>
                    </div>
                  </a>
                </div>
              </section>
              <section class="md:mb-18 mb-12">
                <div class="relative z-50 mx-auto max-w-7xl px-6 pt-6 lg:px-8">
                  <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                    Community Highlights
                  </h2>
                  <div class="mx-auto mt-6 grid max-w-2xl grid-cols-1 grid-rows-1 gap-8 text-sm/6 text-foreground sm:grid-cols-2 xl:mx-0 xl:max-w-none xl:grid-flow-col xl:grid-cols-4">
                    <div class="sm:col-span-2 xl:col-start-2 xl:row-end-1">
                      <a
                        href="https://news.ycombinator.com/item?id=37584049"
                        target="_blank"
                        rel="noopener"
                        class="group relative overflow-hidden rounded-lg bg-background transition-all"
                      >
                        <img
                          src={~p"/images/challenges/electric/hn-post.png"}
                          alt="Hacker News discussion"
                          class="w-full object-cover rounded-lg"
                        />
                      </a>
                      <figure class="mt-6 rounded-2xl bg-card shadow-lg border-2 border-border hover:border-[#37363d] transition-colors">
                        <.link
                          href="https://news.ycombinator.com/item?id=37584049"
                          target="_blank"
                          rel="noopener"
                        >
                          <blockquote class="p-6 text-lg font-semibold tracking-tight text-foreground sm:p-12 sm:text-xl/8 whitespace-pre-line -mt-16">
                            <p>
                              We're building an offline-first, mobile-first app and have high hopes for this project! The combination of SQLite's convenience on the client-side and PostgreSQL's flexibility on the server-side is a potent foundation.
                            </p>
                          </blockquote>
                          <figcaption class="flex items-center gap-x-2 p-6 sm:p-12 -mt-12 md:-mt-24">
                            <.icon name="tabler-brand-ycombinator" class="size-6" />
                            <div>
                              <div class="font-semibold text-foreground">gregzo & thanikkal</div>
                            </div>
                          </figcaption>
                        </.link>
                      </figure>
                    </div>
                    <div class="space-y-8 xl:contents xl:space-y-0">
                      <div class="space-y-8 xl:row-span-2">
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#37363d] transition-colors">
                          <.link
                            href="https://news.ycombinator.com/item?id=37584049"
                            target="_blank"
                            rel="noopener"
                          >
                            <blockquote class="text-foreground whitespace-pre-line -mt-12">
                              <p>
                                Synchronizing data with multiple users updating data in a distributed manner then reconciling it is not trivial.
                              </p>
                            </blockquote>
                            <figcaption class="flex items-center gap-x-2">
                              <.icon name="tabler-brand-ycombinator" class="size-6" />
                              <div>
                                <div class="font-semibold text-foreground">
                                  brigadier132
                                </div>
                              </div>
                            </figcaption>
                          </.link>
                        </figure>
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#37363d] transition-colors">
                          <.link
                            href="https://news.ycombinator.com/item?id=37584049"
                            target="_blank"
                            rel="noopener"
                          >
                            <blockquote class="text-foreground whitespace-pre-line -mt-12">
                              <p>
                                Reducing network reliance solves so many problems and corner-cases in my web app. Having access to local data makes everything very snappy too.
                              </p>
                            </blockquote>
                            <figcaption class="flex items-center gap-x-2">
                              <.icon name="tabler-brand-ycombinator" class="size-6" />
                              <div>
                                <div class="font-semibold text-foreground">
                                  mjadobson
                                </div>
                              </div>
                            </figcaption>
                          </.link>
                        </figure>
                      </div>
                    </div>
                    <div class="space-y-8 xl:contents xl:space-y-0">
                      <div class="space-y-8 xl:row-span-2">
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#37363d] transition-colors">
                          <.link
                            href="https://news.ycombinator.com/item?id=37584049"
                            target="_blank"
                            rel="noopener"
                          >
                            <blockquote class="text-foreground whitespace-pre-line -mt-12">
                              <p>
                                This looks amazing. Real-time sync has been such a pain point for our collaborative apps. Can't wait to try this out.
                              </p>
                            </blockquote>
                            <figcaption class="flex items-center gap-x-2">
                              <.icon name="tabler-brand-ycombinator" class="size-6" />
                              <div>
                                <div class="font-semibold text-foreground">
                                  devbuilder42
                                </div>
                              </div>
                            </figcaption>
                          </.link>
                        </figure>
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#37363d] transition-colors">
                          <.link
                            href="https://news.ycombinator.com/item?id=37584049"
                            target="_blank"
                            rel="noopener"
                          >
                            <blockquote class="text-foreground whitespace-pre-line -mt-12">
                              <p>
                                The local-first approach is the future. Finally something that makes it easy to build reactive apps with live data.
                              </p>
                            </blockquote>
                            <figcaption class="flex items-center gap-x-2">
                              <.icon name="tabler-brand-ycombinator" class="size-6" />
                              <div>
                                <div class="font-semibold text-foreground">
                                  reactivedev
                                </div>
                              </div>
                            </figcaption>
                          </.link>
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
                          class="rounded-xl border-2 border-[#d1b9fe] p-3 text-[#d1b9fe] transition-colors hover:border-[#d1b9fe] hover:text-[#d1b9fe] sm:p-5"
                          href="https://discord.electric-sql.com"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">Discord</span>
                          <.icon name="tabler-brand-discord-filled" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                        <.link
                          class="rounded-xl border-2 border-[#d1b9fe] p-3 text-[#d1b9fe] transition-colors hover:border-[#d1b9fe] hover:text-[#d1b9fe] sm:p-5"
                          href="https://x.com/ElectricSQL"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">X (formerly Twitter)</span>
                          <.icon name="tabler-brand-x" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                        <.link
                          class="rounded-xl border-2 border-[#d1b9fe] p-3 text-[#d1b9fe] transition-colors hover:border-[#d1b9fe] hover:text-[#d1b9fe] sm:p-5"
                          href="https://github.com/electric-sql/electric"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">GitHub</span>
                          <.icon name="github" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                        <.link
                          class="rounded-xl border-2 border-[#d1b9fe] p-3 text-[#d1b9fe] transition-colors hover:border-[#d1b9fe] hover:text-[#d1b9fe] sm:p-5"
                          href="https://www.youtube.com/@ElectricSQL"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">YouTube</span>
                          <.icon name="tabler-brand-youtube-filled" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                      </div>
                    </div>
                    <a
                      rel="noopener"
                      target="_blank"
                      href="https://github.com/electric-sql/electric"
                      class="group/card h-full border border-white/10 bg-black md:gap-8 group relative flex-1 overflow-hidden rounded-xl bg-cover shadow-[0px_3.26536px_2.21381px_0px_rgba(86,_72,_117,_0.08),_0px_7.84712px_5.32008px_0px_rgba(86,_72,_117,_0.11),_0px_14.77543px_10.01724px_0px_rgba(86,_72,_117,_0.14),_0px_26.35684px_17.86905px_0px_rgba(86,_72,_117,_0.16),_0px_49.29758px_33.42209px_0px_rgba(86,_72,_117,_0.19),_0px_118px_80px_0px_rgba(86,_72,_117,_0.27)] hover:no-underline"
                    >
                      <img
                        src="https://fly.storage.tigris.dev/algora-console/repositories/electric-sql/electric/og.png"
                        alt="electric"
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
