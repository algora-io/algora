defmodule AlgoraWeb.Challenges.ClickhouseLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Activities
  alias Algora.Jobs
  alias AlgoraWeb.Components.Header

  @impl true
  def mount(_params, _session, socket) do
    jobs = Jobs.list_jobs(handle: "clickhouse", limit: 3)

    {:ok,
     socket
     |> assign(:page_title, "ClickHouse Challenge")
     |> assign(
       :page_description,
       "Contribute to ClickHouse to win interviews and bounties!"
     )
     |> assign(:page_image, "#{AlgoraWeb.Endpoint.url()}/images/challenges/clickhouse/og.png")
     |> assign(:jobs, jobs)
     |> assign(:show_submit_drawer, false)
     |> assign(:repo_pr_link, "")
     |> assign(:resume_url, "")
     |> assign(:linkedin_url, "")}
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
              <section class="mb-12 min-h-[calc(100svh-36px)] md:min-h-0">
                <div class="relative z-20 mx-auto max-w-[100rem] px-6 lg:px-8">
                  <div class="max-w-5xl pt-24 2xl:pt-72">
                    <a
                      rel="noopener"
                      target="_blank"
                      href="https://clickhouse.com"
                      class="inline-flex items-center bg-black/20 hover:bg-black/30 ring-1 ring-white/30 hover:ring-white/40 py-2 px-4 rounded-full font-medium text-white/90 hover:text-white text-sm sm:text-base transition-colors"
                    >
                      Challenge brought to you by
                      <img
                        src={~p"/images/wordmarks/clickhouse.svg"}
                        alt="ClickHouse"
                        class="h-6 sm:h-8 -mr-4"
                        style="aspect-ratio: 1200/300;"
                      />
                    </a>
                    <h1 class="mt-6 mb-2 text-2xl font-black tracking-tighter mix-blend-exclusion sm:text-5xl/[3rem] md:text-6xl/[4rem] lg:text-7xl/[5rem]">
                      Contribute to
                      <span style="background: radial-gradient(53.44% 245.78% at 13.64% 46.56%, rgb(255, 215, 0) 0%, rgb(255, 204, 0) 100%) text; -webkit-text-fill-color: transparent;">
                        ClickHouse
                      </span>
                      <br /> Win interviews & bounties
                    </h1>
                    <p class="max-w-xl xl:max-w-2xl mt-4 text-base font-medium tracking-tight text-white/90 shadow-black [text-shadow:_0_1px_0_var(--tw-shadow-color)] md:mt-6 md:text-lg md:text-white/80">
                      ClickHouse is building the world's fastest real-time analytics database. From Postgres migrations to AI-powered query generation, we're pushing the boundaries of what's possible with databases.
                      <br /><br />
                      Join us in this public take-home challenge where you can showcase your skills. Top 10 submissions get guaranteed interviews, and the top 3 winners receive bounties!
                    </p>
                  </div>
                </div>
                <div class="hidden lg:block top-[0px] absolute inset-0 z-10 h-[600px] md:h-[750px] 2xl:h-[900px] bg-gradient-to-r from-background from-[42%] to-transparent to-[69%]">
                </div>
                <div class="hidden lg:block top-[0px] absolute inset-0 z-10 h-[600px] md:h-[750px] 2xl:h-[900px] bg-gradient-to-t from-background from-[5%] to-transparent to-[30%]">
                </div>
                <div class="hidden lg:block top-[0px] absolute inset-0 z-10 h-[600px] md:h-[750px] 2xl:h-[900px] bg-gradient-to-b from-background from-[5%] to-transparent to-[30%]">
                </div>
                <div class="block lg:hidden top-[250px] absolute inset-0 z-10 h-[600px] md:h-[750px] 2xl:h-[900px] bg-gradient-to-b from-background from-[1%] to-transparent to-[70%]">
                </div>
                <div class="block lg:hidden top-[250px] absolute inset-0 z-10 h-[600px] md:h-[750px] 2xl:h-[900px] bg-gradient-to-t from-background from-[1%] to-transparent to-[50%]">
                </div>
                <div class="top-[250px] sm:top-[0px] absolute inset-0 z-0 h-[600px] md:h-[750px] 2xl:h-[900px]">
                  <img
                    src={~p"/images/challenges/clickhouse/bg.png"}
                    alt="Background"
                    class="h-full w-full object-cover object-[90%_100%] md:object-[50%_100%] lg:object-[40%_100%] xl:object-[29%_100%] 2xl:object-[20%_100%]"
                    style="aspect-ratio: 4096/1326;"
                  />
                </div>
              </section>
              <section class="mx-auto max-w-[100rem] my-12 z-20 relative">
                <div class="mx-auto grid gap-4 px-6 sm:grid-cols-1 lg:grid-cols-3 lg:px-8">
                  <div class="group relative overflow-hidden rounded-2xl bg-gradient-to-b from-[#ffcc00]/20 to-[#ffcc00]/5 p-[1px] transition-all hover:from-[#ffcc00]/40 hover:to-[#ffcc00]/10">
                    <div class="relative overflow-hidden rounded-2xl bg-black/50 backdrop-blur-xl p-6 h-full flex flex-col">
                      <div class="absolute top-0 right-0 w-32 h-32 bg-[#ffcc00]/10 rounded-full blur-3xl group-hover:bg-[#ffcc00]/20 transition-all">
                      </div>
                      <div class="relative flex-1 flex flex-col">
                        <div class="flex items-start justify-between mb-4">
                          <div class="flex items-center gap-3">
                            <div class="w-10 h-10 rounded-xl bg-[#ffcc00]/10 flex items-center justify-center ring-1 ring-[#ffcc00]/20">
                              <.icon name="tabler-database" class="w-5 h-5 text-[#ffcc00]" />
                            </div>
                            <div>
                              <p class="text-xs font-medium text-white/50 uppercase tracking-wider">
                                Challenge 1
                              </p>
                              <h3 class="text-lg font-bold text-white">Postgres Migrations</h3>
                            </div>
                          </div>
                        </div>
                        <p class="text-sm text-white/60 leading-relaxed mb-4 flex-1">
                          Improve PeerDB for Postgres-to-Postgres migrations by adding schema, trigger, and index migration support with comprehensive tests.
                        </p>
                        <a
                          target="_blank"
                          rel="noopener"
                          class="inline-flex items-center gap-2 text-sm text-[#ffcc00] hover:text-[#ffd700] transition-colors font-medium mt-auto"
                          href="https://github.com/PeerDB-io/peerdb"
                        >
                          <.icon name="github" class="w-4 h-4 shrink-0" /> View Repository →
                        </a>
                      </div>
                    </div>
                  </div>
                  <div class="group relative overflow-hidden rounded-2xl bg-gradient-to-b from-[#ffcc00]/20 to-[#ffcc00]/5 p-[1px] transition-all hover:from-[#ffcc00]/40 hover:to-[#ffcc00]/10">
                    <div class="relative overflow-hidden rounded-2xl bg-black/50 backdrop-blur-xl p-6 h-full flex flex-col">
                      <div class="absolute top-0 right-0 w-32 h-32 bg-[#ffcc00]/10 rounded-full blur-3xl group-hover:bg-[#ffcc00]/20 transition-all">
                      </div>
                      <div class="relative flex-1 flex flex-col">
                        <div class="flex items-start justify-between mb-4">
                          <div class="flex items-center gap-3">
                            <div class="w-10 h-10 rounded-xl bg-[#ffcc00]/10 flex items-center justify-center ring-1 ring-[#ffcc00]/20">
                              <.icon name="tabler-robot" class="w-5 h-5 text-[#ffcc00]" />
                            </div>
                            <div>
                              <p class="text-xs font-medium text-white/50 uppercase tracking-wider">
                                Challenge 2
                              </p>
                              <h3 class="text-lg font-bold text-white">AI-Powered Queries</h3>
                            </div>
                          </div>
                        </div>
                        <p class="text-sm text-white/60 leading-relaxed mb-4 flex-1">
                          Build a Postgres extension using the ClickHouse AI SDK (C++) that exposes a function like pg_gen_query() to generate SQL from natural language.
                        </p>
                        <div class="flex items-center justify-between">
                          <a
                            target="_blank"
                            rel="noopener"
                            class="inline-flex items-center gap-2 text-sm text-[#ffcc00] hover:text-[#ffd700] transition-colors font-medium mt-auto"
                            href="https://github.com/ClickHouse/ai-sdk-cpp"
                          >
                            <.icon name="github" class="w-4 h-4 shrink-0" /> View Repository →
                          </a>
                          <a
                            target="_blank"
                            rel="noopener"
                            class="inline-flex items-center gap-2 text-sm text-[#ffcc00] hover:text-[#ffd700] transition-colors font-medium mt-auto"
                            href="https://clickhouse.com/docs/interfaces/cli#ai-sql-generation"
                          >
                            <.icon name="tabler-book" class="w-4 h-4 shrink-0" /> View Docs →
                          </a>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div class="group relative overflow-hidden rounded-2xl bg-gradient-to-b from-[#ffcc00]/20 to-[#ffcc00]/5 p-[1px] transition-all hover:from-[#ffcc00]/40 hover:to-[#ffcc00]/10">
                    <div class="relative overflow-hidden rounded-2xl bg-black/50 backdrop-blur-xl p-6 h-full flex flex-col">
                      <div class="absolute top-0 right-0 w-32 h-32 bg-[#ffcc00]/10 rounded-full blur-3xl group-hover:bg-[#ffcc00]/20 transition-all">
                      </div>
                      <div class="relative flex-1 flex flex-col">
                        <div class="flex items-start justify-between mb-4">
                          <div class="flex items-center gap-3">
                            <div class="w-10 h-10 rounded-xl bg-[#ffcc00]/10 flex items-center justify-center ring-1 ring-[#ffcc00]/20">
                              <.icon name="tabler-chart-bar" class="w-5 h-5 text-[#ffcc00]" />
                            </div>
                            <div>
                              <p class="text-xs font-medium text-white/50 uppercase tracking-wider">
                                Challenge 3
                              </p>
                              <h3 class="text-lg font-bold text-white">Analytics Platform</h3>
                            </div>
                          </div>
                        </div>
                        <p class="text-sm text-white/60 leading-relaxed mb-4 flex-1">
                          Fork NextFaster and make it work with ClickHouse instead of Postgres. Add analytics features like dashboards, real-time metrics, and query optimization insights.
                        </p>
                        <a
                          target="_blank"
                          rel="noopener"
                          class="inline-flex items-center gap-2 text-sm text-[#ffcc00] hover:text-[#ffd700] transition-colors font-medium mt-auto"
                          href="https://github.com/ethanniser/NextFaster"
                        >
                          <.icon name="github" class="w-4 h-4 shrink-0" /> View Repository →
                        </a>
                      </div>
                    </div>
                  </div>
                </div>
              </section>
              <section class="md:mb-18 mb-12 xl:pt-20 2xl:pt-52">
                <div class="relative z-50 mx-auto max-w-7xl px-6 pt-6 lg:px-8">
                  <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                    How to participate
                  </h2>
                  <p class="text-center mt-4 text-sm sm:text-base font-medium text-gray-200">
                    Got questions? Reach out to
                    <a
                      target="_blank"
                      class="font-semibold text-white underline"
                      href="mailto:kaushik@clickhouse.com"
                    >
                      kaushik@clickhouse.com
                    </a>
                    and
                    <a
                      target="_blank"
                      class="font-semibold text-white underline"
                      href="mailto:sai.srirampur@clickhouse.com"
                    >
                      sai.srirampur@clickhouse.com
                    </a>
                  </p>
                  <ul class="mt-4 md:mt-8 space-y-4 md:space-y-2 mx-auto max-w-4xl">
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-1" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Pick one of the three challenges above that interests you most
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-2" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Create a PR or your own public GitHub repository with your solution
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-3" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Record a short 30-60 second demo video showing your work
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-4" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        <button
                          phx-click="open_submit_drawer"
                          class="font-semibold text-[#ffcc00] hover:text-[#ffd700] underline transition-colors inline-flex"
                        >
                          Submit your work
                        </button>
                        by November 17, 2025, 10 AM PST
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-5" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Top 10 submissions get guaranteed interviews. Top 3 receive <span class="font-display font-bold text-[#ffcc00]">$300</span>, <span class="font-display font-bold text-[#ffcc00]">$200</span>, and
                        <span class="font-display font-bold text-[#ffcc00]">$100</span>
                        respectively
                      </span>
                    </li>
                  </ul>
                </div>
              </section>
              <section class="md:mb-18 mb-12">
                <div class="relative z-50 mx-auto max-w-7xl px-6 pt-6 lg:px-8">
                  <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                    Open Roles
                  </h2>
                  <p class="text-center mt-4 text-sm sm:text-base font-medium text-gray-200 mb-8">
                    Join the ClickHouse team
                  </p>
                  <%= if Enum.empty?(@jobs) do %>
                    <div class="mx-auto max-w-4xl text-center">
                      <p class="text-muted-foreground mb-4">No positions available at the moment</p>
                      <a
                        href={AlgoraWeb.Endpoint.url() <> "/clickhouse/jobs"}
                        class="inline-flex items-center gap-2 text-sm text-[#ffcc00] hover:text-[#ffd700] transition-colors font-medium"
                      >
                        View all ClickHouse opportunities →
                      </a>
                    </div>
                  <% else %>
                    <div class="mx-auto max-w-4xl space-y-4">
                      <%= for job <- @jobs do %>
                        <.link
                          href={"/clickhouse/job/#{job.id}"}
                          class="block rounded-lg border border-border bg-card p-6 hover:border-[#ffcc00]/50 transition-colors"
                        >
                          <h3 class="text-lg font-semibold text-foreground mb-2">
                            {job.title}
                          </h3>
                          <p class="text-sm text-muted-foreground mb-3">
                            {job.description}
                          </p>
                          <div class="flex flex-wrap gap-2 mb-3">
                            <%= for tech <- job.tech_stack do %>
                              <.tech_badge tech={tech} />
                            <% end %>
                          </div>
                          <%= if job.location do %>
                            <div class="flex items-center gap-2 text-sm text-muted-foreground">
                              <.icon name="tabler-map-pin" class="w-4 h-4 shrink-0" />
                              <span>{job.location}</span>
                            </div>
                          <% end %>
                        </.link>
                      <% end %>
                    </div>
                    <div class="text-center mt-8">
                      <a
                        href={AlgoraWeb.Endpoint.url() <> "/clickhouse/jobs"}
                        class="inline-flex items-center gap-2 text-sm text-[#ffcc00] hover:text-[#ffd700] transition-colors font-medium"
                      >
                        View all ClickHouse opportunities →
                      </a>
                    </div>
                  <% end %>
                </div>
              </section>
              <section class="md:mb-18 mb-12">
                <div class="relative z-50 mx-auto max-w-7xl px-6 pt-6 lg:px-8">
                  <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                    Why ClickHouse?
                  </h2>
                  <div class="mx-auto mt-6 grid max-w-2xl grid-cols-1 grid-rows-1 gap-8 text-sm/6 text-foreground sm:grid-cols-2 xl:mx-0 xl:max-w-none xl:grid-flow-col xl:grid-cols-4">
                    <div class="sm:col-span-2 xl:col-start-2 xl:row-end-1 space-y-8">
                      <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#ffcc00]/50 transition-colors">
                        <blockquote class="p-6 text-lg font-semibold tracking-tight text-foreground sm:p-12 sm:text-xl/8 whitespace-pre-line -mt-16">
                          <p>
                            It's so goddamn fast. They've made massive steps to make it work like you'd expect a database to work. I think it has a very bright future.
                          </p>
                        </blockquote>
                        <figcaption class="flex items-center gap-x-2 p-6 sm:p-12 -mt-12 md:-mt-24">
                          <.icon name="tabler-brand-reddit" class="size-6" />
                          <div>
                            <div class="font-semibold text-foreground">mailed</div>
                          </div>
                        </figcaption>
                      </figure>
                      <figure class="rounded-2xl bg-card shadow-lg border-2 border-border hover:border-[#ffcc00]/50 transition-colors">
                        <blockquote class="p-6 text-lg font-semibold tracking-tight text-foreground sm:p-12 sm:text-xl/8 whitespace-pre-line -mt-16">
                          <p>
                            We've been using it since 2019...query speeds that seem unreal compared to MySQL and pg.
                          </p>
                        </blockquote>
                        <figcaption class="flex items-center gap-x-2 p-6 sm:p-12 -mt-12 md:-mt-24">
                          <.icon name="tabler-brand-ycombinator" class="size-6" />
                          <div>
                            <div class="font-semibold text-foreground">Smrchy</div>
                          </div>
                        </figcaption>
                      </figure>
                    </div>
                    <div class="space-y-8 xl:contents xl:space-y-0">
                      <div class="space-y-8 xl:row-span-2">
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#ffcc00]/50 transition-colors">
                          <blockquote class="text-foreground whitespace-pre-line -mt-12">
                            <p>
                              Mind boggling fast...no issues whatsoever with migration from HBase to single-node ClickHouse.
                            </p>
                          </blockquote>
                          <figcaption class="flex items-center gap-x-2">
                            <.icon name="tabler-brand-ycombinator" class="size-6" />
                            <div>
                              <div class="font-semibold text-foreground">
                                parth_patil
                              </div>
                            </div>
                          </figcaption>
                        </figure>
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#ffcc00]/50 transition-colors">
                          <blockquote class="text-foreground whitespace-pre-line -mt-12">
                            <p>
                              It can ingest data at a really high rate because of the way that it accepts large inserts and merges them in the background.
                            </p>
                          </blockquote>
                          <figcaption class="flex items-center gap-x-2">
                            <.icon name="tabler-brand-reddit" class="size-6" />
                            <div>
                              <div class="font-semibold text-foreground">
                                chrisbisnett
                              </div>
                            </div>
                          </figcaption>
                        </figure>
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#ffcc00]/50 transition-colors">
                          <blockquote class="text-foreground whitespace-pre-line -mt-12">
                            <p>
                              Performance was easily an order of magnitude or two better than anything except ES in real-time analytics benchmarking.
                            </p>
                          </blockquote>
                          <figcaption class="flex items-center gap-x-2">
                            <.icon name="tabler-brand-ycombinator" class="size-6" />
                            <div>
                              <div class="font-semibold text-foreground">
                                fiddlerwoaroof
                              </div>
                            </div>
                          </figcaption>
                        </figure>
                      </div>
                    </div>
                    <div class="space-y-8 xl:contents xl:space-y-0">
                      <div class="space-y-8 xl:row-span-2">
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#ffcc00]/50 transition-colors">
                          <blockquote class="text-foreground whitespace-pre-line -mt-12">
                            <p>
                              Built large-scale system with tons of text searches, complex joins and performance that rivals BigQuery.
                            </p>
                          </blockquote>
                          <figcaption class="flex items-center gap-x-2">
                            <.icon name="tabler-brand-ycombinator" class="size-6" />
                            <div>
                              <div class="font-semibold text-foreground">
                                DevKoala
                              </div>
                            </div>
                          </figcaption>
                        </figure>
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#ffcc00]/50 transition-colors">
                          <blockquote class="text-foreground whitespace-pre-line -mt-12">
                            <p>
                              Happy with both the performance and how well it scales.
                            </p>
                          </blockquote>
                          <figcaption class="flex items-center gap-x-2">
                            <.icon name="tabler-brand-ycombinator" class="size-6" />
                            <div>
                              <div class="font-semibold text-foreground">
                                ddbennett
                              </div>
                            </div>
                          </figcaption>
                        </figure>
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#ffcc00]/50 transition-colors">
                          <blockquote class="text-foreground whitespace-pre-line -mt-12">
                            <p>
                              ClickHouse does particularly well for high volume, large data use cases where you want quick analytics results.
                            </p>
                          </blockquote>
                          <figcaption class="flex items-center gap-x-2">
                            <.icon name="tabler-brand-reddit" class="size-6" />
                            <div>
                              <div class="font-semibold text-foreground">
                                AffectionateCamera57
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
                    <div class="flex flex-col items-center sm:items-start gap-6 md:gap-12">
                      <h2 class="text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                        Start building
                      </h2>
                      <div class="flex gap-4 sm:gap-6">
                        <.link
                          class="rounded-xl border-2 border-[#ffcc00] p-3 text-[#ffcc00] transition-colors hover:border-[#ffd700] hover:text-[#ffd700] sm:p-5"
                          href="https://github.com/ClickHouse/ClickHouse"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">GitHub</span>
                          <.icon name="github" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                        <.link
                          class="rounded-xl border-2 border-[#ffcc00] p-3 text-[#ffcc00] transition-colors hover:border-[#ffd700] hover:text-[#ffd700] sm:p-5"
                          href="https://x.com/clickhousedb"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">X (formerly Twitter)</span>
                          <.icon name="tabler-brand-x" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                        <.link
                          class="rounded-xl border-2 border-[#ffcc00] p-3 text-[#ffcc00] transition-colors hover:border-[#ffd700] hover:text-[#ffd700] sm:p-5"
                          href="https://clickhouse.com/slack"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">Slack</span>
                          <.icon name="tabler-brand-slack" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                        <.link
                          class="rounded-xl border-2 border-[#ffcc00] p-3 text-[#ffcc00] transition-colors hover:border-[#ffd700] hover:text-[#ffd700] sm:p-5"
                          href="https://www.youtube.com/@ClickHouseDB"
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
                      href="https://github.com/ClickHouse/ClickHouse"
                      class="group/card h-full border border-white/10 bg-black md:gap-8 group relative flex-1 overflow-hidden rounded-xl bg-cover shadow-[0px_20px_60px_0px_rgba(255,_204,_0,_0.20)] hover:shadow-[0px_25px_70px_0px_rgba(255,_204,_0,_0.30)] transition-shadow hover:no-underline"
                    >
                      <img
                        src={~p"/images/challenges/clickhouse/repo.png"}
                        alt="ClickHouse"
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

    <.drawer
      show={@show_submit_drawer}
      on_cancel="close_submit_drawer"
      direction="right"
      class="min-w-[50vw]"
    >
      <.drawer_header>
        <.drawer_title>Submit your work</.drawer_title>
        <.drawer_description>
          Share your work with the ClickHouse team
        </.drawer_description>
      </.drawer_header>
      <.drawer_content>
        <form phx-submit="submit_challenge" class="space-y-6">
          <.input
            label="Repository or PR Link"
            type="text"
            id="repo_pr_link"
            name="repo_pr_link"
            value={@repo_pr_link}
            placeholder="https://github.com/username/repo or PR link"
            required
            phx-change="update_field"
          />

          <.input
            label="Resume URL"
            type="text"
            id="resume_url"
            name="resume_url"
            value={@resume_url}
            placeholder="https://example.com/resume.pdf"
            phx-change="update_field"
          />

          <.input
            label="LinkedIn URL"
            type="text"
            id="linkedin_url"
            name="linkedin_url"
            value={@linkedin_url}
            placeholder="https://linkedin.com/in/username"
            phx-change="update_field"
          />

          <div class="flex gap-4">
            <.button type="button" class="flex-1" variant="outline" phx-click="close_submit_drawer">
              Cancel
            </.button>
            <.button type="submit" class="flex-1">
              Submit
            </.button>
          </div>
        </form>
      </.drawer_content>
    </.drawer>
    """
  end

  @impl true
  def handle_event("open_submit_drawer", _params, socket) do
    {:noreply, assign(socket, :show_submit_drawer, true)}
  end

  @impl true
  def handle_event("close_submit_drawer", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_submit_drawer, false)
     |> assign(:repo_pr_link, "")
     |> assign(:resume_url, "")
     |> assign(:linkedin_url, "")}
  end

  @impl true
  def handle_event("update_field", %{"repo_pr_link" => value}, socket) do
    {:noreply, assign(socket, :repo_pr_link, value)}
  end

  def handle_event("update_field", %{"resume_url" => value}, socket) do
    {:noreply, assign(socket, :resume_url, value)}
  end

  def handle_event("update_field", %{"linkedin_url" => value}, socket) do
    {:noreply, assign(socket, :linkedin_url, value)}
  end

  @impl true
  def handle_event("submit_challenge", params, socket) do
    submission_data = %{
      repo_pr_link: params["repo_pr_link"],
      resume_url: params["resume_url"],
      linkedin_url: params["linkedin_url"],
      submitted_at: DateTime.to_iso8601(DateTime.utc_now()),
      challenge: "ClickHouse Database Engineering"
    }

    json_data = Jason.encode!(submission_data, pretty: true)
    Activities.alert("ClickHouse Challenge Submission:\n```json\n#{json_data}\n```", :critical)

    {:noreply,
     socket
     |> assign(:show_submit_drawer, false)
     |> assign(:repo_pr_link, "")
     |> assign(:resume_url, "")
     |> assign(:linkedin_url, "")
     |> put_flash(:info, "Your submission has been received! The ClickHouse team will review it shortly.")}
  end
end
