defmodule AlgoraWeb.Challenges.LimboLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias AlgoraWeb.Components.Header

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Limbo Challenge")
     |> assign(:page_description, "Turso rewrote SQLite in Rust - find a bug to win $1,000!")
     |> assign(:page_image, "#{AlgoraWeb.Endpoint.url()}/images/challenges/limbo/og.png")}
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
                  <div class="max-w-5xl pt-28 md:pt-36 2xl:pt-72">
                    <a
                      rel="noopener"
                      target="_blank"
                      href="https://turso.tech"
                      class="inline-flex items-center bg-[#1b252e]/75 hover:bg-[#11181f] ring-1 ring-[#4ff7d3] hover:ring-[#75ffe1] py-2 px-4 rounded-full font-medium text-[#4ff7d3]/90 hover:text-[#4ff7d3] text-sm sm:text-base transition-colors"
                    >
                      Challenge brought to you by
                      <img
                        src={~p"/images/wordmarks/turso-aqua.svg"}
                        alt="Turso"
                        class="ml-1 h-6 sm:h-7"
                        style="aspect-ratio: 821/240;"
                      />
                    </a>
                    <h1 class="mt-8 mb-2 text-[1.4rem] font-black tracking-tighter mix-blend-exclusion sm:text-5xl/[3rem] md:text-6xl/[4rem] lg:text-7xl/[5rem]">
                      Turso is rewriting SQLite in Rust<br />
                      <span style="background: radial-gradient(53.44% 245.78% at 13.64% 46.56%, rgb(110, 231, 183) 0%, rgb(45, 212, 191) 100%) text; -webkit-text-fill-color: transparent;">
                        Find a bug to win <span class="font-display">$1,000</span>
                      </span>
                    </h1>
                    <p class="max-w-xl xl:max-w-2xl mt-6 text-base font-medium tracking-tight text-white/90 shadow-black [text-shadow:_0_1px_0_var(--tw-shadow-color)] md:mt-8 md:text-lg md:text-white/80">
                      SQLite, while legendary, has remained closed to community contributions. We at Turso are changing that by building a modern
                      SQLite alternative in Rust - one that's open source and community-driven. Our goal isn't just features, but
                      rock-solid reliability through <a
                        href="https://turso.tech/blog/a-deep-look-into-our-new-massive-multitenant-architecture"
                        class="font-semibold text-white underline"
                      >Deterministic Simulation Testing</a>. <br /><br />
                      We are so confident in DST's ability to find the rarest bugs, that we are offering cash bounties for those who can find cases where a bug survived this testing. In this initial phase of the project, we will offer
                      <span class="font-display font-bold text-foreground">$1,000</span>
                      for any bugs that lead to data corruption. After our first official release, we will expand the scope of bugs and size of the bounty.
                    </p>
                  </div>
                </div>
                <div class="hidden lg:block top-[0px] absolute inset-0 z-10 h-[calc(100svh-0px)] md:h-[750px] 2xl:h-[900px] bg-gradient-to-r from-background from-1% to-transparent to-[69%]">
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
                    src={~p"/images/challenges/limbo/bg.webp"}
                    alt="Background"
                    class="h-full w-full object-cover object-[60%_100%] md:object-[50%_100%] lg:object-[40%_100%] xl:object-[29%_100%] 2xl:object-[20%_100%]"
                    style="aspect-ratio: 4096/1326;"
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
                      href="https://discord.gg/jgjmyYgHwB"
                    >
                      Join us on Discord!
                    </a>
                  </p>
                  <ul class="mt-4 md:mt-8 space-y-4 md:space-y-2 mx-auto max-w-3xl">
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-1" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        <a
                          rel="noopener"
                          target="_blank"
                          class="font-semibold text-white underline inline-flex"
                          href="https://github.com/tursodatabase/limbo/blob/main/CONTRIBUTING.md"
                        >
                          Set up your development environment
                        </a>
                        and build the Limbo CLI locally
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-2" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Explore the
                        <a
                          rel="noopener"
                          target="_blank"
                          class="font-semibold text-white underline inline-flex"
                          href="https://github.com/tursodatabase/limbo/tree/main/simulator"
                        >
                          simulator
                        </a>
                        directory to understand our Deterministic Simulation Testing framework
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-3" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Discover a seed value through the simulator that exposes a bug which leads to data corruption
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-4" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Submit a PR improving the DST to catch the bug for an
                        <span class="font-display font-bold text-[#4ff7d3]">$800</span>
                        reward
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-5" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Fix the identified bug for an additional
                        <span class="font-display font-bold text-[#4ff7d3]">$200</span>
                        reward
                      </span>
                    </li>
                  </ul>
                </div>
              </section>
              <section class="mx-auto my-24 max-w-7xl md:my-36">
                <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                  Media
                </h2>
                <div class="mx-auto grid gap-6 px-6 sm:grid-cols-2 lg:px-8">
                  <a class="block pt-6 md:pt-12" href="https://www.youtube.com/watch?v=c9SM0Ra_o84">
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
                          <div class="relative flex aspect-[16/9] h-full w-full items-center justify-center text-balance bg-gray-950 text-center text-xl font-medium text-red-100 sm:text-2xl">
                            <img
                              src="https://i.ytimg.com/vi/c9SM0Ra_o84/maxresdefault.jpg"
                              alt="Turso is rewriting SQLite in Rust | Glauber Costa"
                            />
                          </div>
                        </div>
                      </div>
                    </div>
                  </a>
                  <a class="block pt-6 md:pt-12" href="https://www.youtube.com/watch?v=PPjXM8G8ax0">
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
                          <div class="relative flex aspect-[16/9] h-full w-full items-center justify-center text-balance bg-gray-950 text-center text-xl font-medium text-red-100 sm:text-2xl">
                            <img
                              src={~p"/images/challenges/limbo/primeagen.png"}
                              alt="The SQLite Rewrite In Rust"
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
                    Discussions
                  </h2>
                  <div class="mt-6 md:mt-12 grid grid-cols-1 gap-6 sm:grid-cols-2">
                    <a
                      href="https://news.ycombinator.com/item?id=42378843"
                      target="_blank"
                      rel="noopener"
                      class="group relative overflow-hidden rounded-lg border border-border bg-background transition-all hover:border-[#37363d]"
                    >
                      <img
                        src={~p"/images/challenges/limbo/hn-post.png"}
                        alt="Hacker News discussion"
                        class="w-full object-cover"
                      />
                    </a>
                    <a
                      href="https://www.reddit.com/r/programming/comments/1hb6vg1/introducing_limbo_a_complete_rewrite_of_sqlite_in/"
                      target="_blank"
                      rel="noopener"
                      class="group relative overflow-hidden rounded-lg border border-border bg-background transition-all hover:border-[#37363d]"
                    >
                      <img
                        src={~p"/images/challenges/limbo/reddit-post.png"}
                        alt="Reddit discussion"
                        class="w-full object-cover"
                      />
                    </a>
                  </div>
                  <div class="mx-auto mt-6 grid max-w-2xl grid-cols-1 grid-rows-1 gap-8 text-sm/6 text-foreground sm:grid-cols-2 xl:mx-0 xl:max-w-none xl:grid-flow-col xl:grid-cols-4">
                    <figure class="rounded-2xl bg-card shadow-lg border-2 border-border hover:border-[#37363d] transition-colors sm:col-span-2 xl:col-start-2 xl:row-end-1">
                      <.link
                        href="https://www.reddit.com/r/programming/comments/1hb6vg1/introducing_limbo_a_complete_rewrite_of_sqlite_in/"
                        target="_blank"
                        rel="noopener"
                      >
                        <blockquote class="p-6 text-lg font-semibold tracking-tight text-foreground sm:p-12 sm:text-xl/8 whitespace-pre-line -mt-16">
                          <p>
                            SQLite is the most well tested software on Earth, any rewrite WILL contain bugs that don't exist in SQLite.

                            Not only has SQLite been tested to run on almost any conceivable device, but its testsuite must be able to reproduce the issue before any bug is closed. This together with its 20 yr+ age makes SQLite closest to perfection of any program written.

                            Making it "more secure" using Rust simply doesn't make sense when you're competing with perfection.
                          </p>
                        </blockquote>
                        <figcaption class="flex items-center gap-x-2 p-6 sm:p-12 -mt-12 md:-mt-24">
                          <.icon name="tabler-brand-reddit" class="size-6" />
                          <div>
                            <div class="font-semibold text-foreground">Dako1905</div>
                          </div>
                        </figcaption>
                      </.link>
                    </figure>
                    <div class="space-y-8 xl:contents xl:space-y-0">
                      <div class="space-y-8 xl:row-span-2">
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#37363d] transition-colors">
                          <.link
                            href="https://news.ycombinator.com/item?id=42378843"
                            target="_blank"
                            rel="noopener"
                          >
                            <blockquote class="text-foreground whitespace-pre-line -mt-12">
                              <p>
                                Given the code quality and rigid testing, SQLite is probably the last project that should be rewritten. It'd be great to see all other C code rewritten first!
                              </p>
                            </blockquote>
                            <figcaption class="flex items-center gap-x-2">
                              <.icon name="tabler-brand-ycombinator" class="size-6" />
                              <div>
                                <div class="font-semibold text-foreground">
                                  danieljanes
                                </div>
                              </div>
                            </figcaption>
                          </.link>
                        </figure>
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#37363d] transition-colors">
                          <.link
                            href="https://news.ycombinator.com/item?id=42378843"
                            target="_blank"
                            rel="noopener"
                          >
                            <blockquote class="text-foreground whitespace-pre-line -mt-12">
                              <p>
                                This is going to sound pedantic, but SQLite is not Open Source. It's Public Domain. The distinction is subtle, but it is important.
                              </p>
                            </blockquote>
                            <figcaption class="flex items-center gap-x-2">
                              <.icon name="tabler-brand-ycombinator" class="size-6" />
                              <div>
                                <div class="font-semibold text-foreground">
                                  bruce511
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
                            href="https://www.reddit.com/r/programming/comments/1hb6vg1/introducing_limbo_a_complete_rewrite_of_sqlite_in/"
                            target="_blank"
                            rel="noopener"
                          >
                            <blockquote class="text-foreground whitespace-pre-line -mt-12">
                              <p>
                                > SQLite's test suite is proprietary

                                huh TIL. Kinda makes sense, but also kinda sucks. So if you try to contribute to SQLite you can't run the tests yourself to see if you broke anything?"
                              </p>
                            </blockquote>
                            <figcaption class="flex items-center gap-x-2">
                              <.icon name="tabler-brand-reddit" class="size-6" />
                              <div>
                                <div class="font-semibold text-foreground">
                                  larikang
                                </div>
                              </div>
                            </figcaption>
                          </.link>
                        </figure>
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#37363d] transition-colors">
                          <.link
                            href="https://www.reddit.com/r/programming/comments/1hb6vg1/introducing_limbo_a_complete_rewrite_of_sqlite_in/"
                            target="_blank"
                            rel="noopener"
                          >
                            <blockquote class="text-foreground whitespace-pre-line -mt-12">
                              <p>
                                well you can't contribute to SQLite, the code is "open-source" but the project is maintained by a set number of people
                              </p>
                            </blockquote>
                            <figcaption class="flex items-center gap-x-2">
                              <.icon name="tabler-brand-reddit" class="size-6" />
                              <div>
                                <div class="font-semibold text-foreground">
                                  PhyToonToon
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
                          class="rounded-xl border-2 border-[#1ebba2] p-3 text-[#4ff7d3] transition-colors hover:border-[#4ff7d3] hover:text-[#75ffe1] sm:p-5"
                          href="https://discord.gg/jgjmyYgHwB"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">Discord</span>
                          <.icon name="tabler-brand-discord-filled" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                        <.link
                          class="rounded-xl border-2 border-[#1ebba2] p-3 text-[#4ff7d3] transition-colors hover:border-[#4ff7d3] hover:text-[#75ffe1] sm:p-5"
                          href="https://x.com/tursodatabase"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">X (formerly Twitter)</span>
                          <.icon name="tabler-brand-x" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                        <.link
                          class="rounded-xl border-2 border-[#1ebba2] p-3 text-[#4ff7d3] transition-colors hover:border-[#4ff7d3] hover:text-[#75ffe1] sm:p-5"
                          href="https://github.com/tursodatabase/limbo"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">GitHub</span>
                          <.icon name="github" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                        <.link
                          class="rounded-xl border-2 border-[#1ebba2] p-3 text-[#4ff7d3] transition-colors hover:border-[#4ff7d3] hover:text-[#75ffe1] sm:p-5"
                          href="https://www.youtube.com/@tursodatabase"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">YouTube</span>
                          <.icon name="tabler-brand-youtube-filled" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                        <.link
                          class="rounded-xl border-2 border-[#1ebba2] p-3 text-[#4ff7d3] transition-colors hover:border-[#4ff7d3] hover:text-[#75ffe1] sm:p-5"
                          href="https://www.linkedin.com/company/turso"
                        >
                          <span class="sr-only">LinkedIn</span>
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                            fill="currentColor"
                            class="h-6 w-6 sm:h-12 sm:w-12"
                          >
                            <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M17 2a5 5 0 0 1 5 5v10a5 5 0 0 1 -5 5h-10a5 5 0 0 1 -5 -5v-10a5 5 0 0 1 5 -5zm-9 8a1 1 0 0 0 -1 1v5a1 1 0 0 0 2 0v-5a1 1 0 0 0 -1 -1m6 0a3 3 0 0 0 -1.168 .236l-.125 .057a1 1 0 0 0 -1.707 .707v5a1 1 0 0 0 2 0v-3a1 1 0 0 1 2 0v3a1 1 0 0 0 2 0v-3a3 3 0 0 0 -3 -3m-6 -3a1 1 0 0 0 -.993 .883l-.007 .127a1 1 0 0 0 1.993 .117l.007 -.127a1 1 0 0 0 -1 -1" />
                          </svg>
                        </.link>
                      </div>
                    </div>
                    <a
                      rel="noopener"
                      target="_blank"
                      href="https://github.com/tursodatabase/limbo"
                      class="group/card h-full border border-white/10 bg-black md:gap-8 group relative flex-1 overflow-hidden rounded-xl bg-cover shadow-[0px_3.26536px_2.21381px_0px_rgba(84,_58,_42,_0.08),_0px_7.84712px_5.32008px_0px_rgba(84,_58,_42,_0.11),_0px_14.77543px_10.01724px_0px_rgba(84,_58,_42,_0.14),_0px_26.35684px_17.86905px_0px_rgba(84,_58,_42,_0.16),_0px_49.29758px_33.42209px_0px_rgba(84,_58,_42,_0.19),_0px_118px_80px_0px_rgba(84,_58,_42,_0.27)] hover:no-underline"
                    >
                      <img
                        src="https://fly.storage.tigris.dev/algora-console/repositories/tursodatabase/limbo/og.png"
                        alt="limbo"
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
