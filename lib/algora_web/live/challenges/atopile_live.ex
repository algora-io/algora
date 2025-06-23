defmodule AlgoraWeb.Challenges.AtopileLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias AlgoraWeb.Components.Header

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Atopile Ecosystem Challenge")
     |> assign(
       :page_description,
       "Expand the atopile ecosystem - build packages, modules, utilities, and tools to win $1,000!"
     )
     |> assign(:page_image, "https://github.com/atopile/atopile/raw/main/docs/assets/logo-horizontal-color.png")}
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
                      href="https://atopile.io"
                      class="inline-flex items-center bg-[#090a0e]/75 hover:bg-[#000] ring-1 ring-[#f0551c] hover:ring-[#ff6b33] py-2 px-4 rounded-full font-medium text-orange-500/90 hover:text-orange-500 text-sm sm:text-base transition-colors"
                    >
                      Challenge brought to you by
                      <img
                        src="/images/wordmarks/atopile.svg"
                        alt="atopile"
                        class="ml-2 h-4 sm:h-5"
                        style="aspect-ratio: 414/98;"
                      />
                    </a>
                    <h1 class="mt-6 mb-2 text-[1.2rem] font-black tracking-tighter mix-blend-exclusion sm:text-5xl/[3rem] md:text-6xl/[4rem] lg:text-6xl/[4rem]">
                      Build the Future of Hardware Design<br />
                      <span style="background: radial-gradient(53.44% 245.78% at 13.64% 46.56%, rgb(240, 85, 28) 0%, rgb(234, 88, 12) 100%) text; -webkit-text-fill-color: transparent;">
                        Expand atopile to win <span class="font-display">$1,000</span>
                      </span>
                    </h1>
                    <p class="max-w-xl xl:max-w-2xl mt-4 text-base font-medium tracking-tight text-white/90 shadow-black [text-shadow:_0_1px_0_var(--tw-shadow-color)] md:mt-6 md:text-lg md:text-white/80">
                      Atopile is revolutionizing how we build electronics by bringing modern software development practices to hardware design. We need passionate builders to expand our ecosystem with packages, modules, utilities, and tools.<br /><br />
                      Publish packages, modules, utilities, or tools that expand the atopile ecosystem. Every accepted published contribution will go in the atopile directory, you'll receive credits, and earn a
                      <span class="font-display font-bold text-foreground">$1,000</span>
                      reward. To participate, you need electrical engineering knowledge (college students welcome!) and passion for building tools for builders.
                    </p>
                  </div>
                </div>
                <div class="hidden lg:block top-[0px] absolute inset-0 z-10 h-[calc(100svh-0px)] md:h-[750px] 2xl:h-[900px] bg-gradient-to-r from-background from-[1%] to-transparent to-[69%]">
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
                    src={~p"/images/challenges/atopile/tmps18ne6vg.png"}
                    alt="Background"
                    class="h-full w-full object-cover object-[60%_50%]"
                    style="aspect-ratio: 1932/672;"
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
                      href="https://x.com/atopile_io"
                    >
                      Reach out on X!
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
                          href="https://atopile.io/atopile/quickstart"
                        >
                          Set up your development environment
                        </a>
                        and familiarize yourself with atopile's syntax and workflow
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-2" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        <a
                          rel="noopener"
                          target="_blank"
                          class="font-semibold text-white underline inline-flex"
                          href="https://packages.atopile.io/"
                        >
                          Explore packages
                        </a>
                        to see examples and identify gaps
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-3" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Create a new package, module, utility, or tool that extends atopile's capabilities. This could be:
                        <ul class="list-disc list-inside ml-4 mt-2 space-y-1">
                          <li>Hardware modules (power supplies, motor drivers, sensors)</li>
                          <li>Development tools and utilities</li>
                          <li>Testing frameworks for hardware</li>
                          <li>Integration tools with other EDA software</li>
                          <li>Educational examples and tutorials</li>
                        </ul>
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-4" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        <a
                          rel="noopener"
                          target="_blank"
                          class="font-semibold text-white underline inline-flex"
                          href="https://atopile.io/atopile/guides/publish"
                        >
                          Publish your package
                        </a>
                        to the atopile registry. Include comprehensive documentation and examples
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-5" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        If your contribution is accepted and published, you'll receive
                        <span class="font-display font-bold text-orange-500">$1,000</span>
                        and recognition in the atopile community
                      </span>
                    </li>
                  </ul>
                </div>
              </section>
              <section class="md:mb-18 mb-12 xl:pt-20 2xl:pt-52">
                <div class="relative z-50 mx-auto max-w-7xl px-6 pt-6 lg:px-8">
                  <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                    Example packages
                  </h2>
                  <p class="text-center mt-4 text-base font-medium text-gray-200">
                    Get inspired by existing packages in the
                    <a
                      target="_blank"
                      class="font-semibold text-white underline"
                      href="https://packages.atopile.io/"
                    >
                      atopile registry
                    </a>
                  </p>
                  <div class="mt-8 grid grid-cols-1 gap-6 md:grid-cols-3">
                    <div class="group relative overflow-hidden rounded-xl bg-white/5 border border-white/10 p-6 transition-all hover:border-[#f0551c]/50 hover:bg-white/10">
                      <div class="flex items-center justify-between mb-4">
                        <h3 class="text-lg font-semibold">
                          <a
                            href="https://packages.atopile.io/packages/atopile/buttons/releases/latest"
                            target="_blank"
                            rel="noopener"
                            class="text-white hover:text-[#f0551c] transition-colors"
                          >
                            atopile/buttons
                          </a>
                        </h3>
                        <span class="px-2 py-1 text-xs font-medium bg-[#f0551c]/20 text-[#f0551c] rounded-full">
                          v0.1.7
                        </span>
                      </div>
                      <p class="text-sm text-gray-400 mb-4">
                        A collection of buttons for convenience
                      </p>
                      <a
                        href="https://github.com/atopile/packages"
                        target="_blank"
                        rel="noopener"
                        class="flex items-center gap-2 text-xs text-[#f0551c] hover:text-[#ff6b33] transition-colors"
                      >
                        <.icon name="github" class="size-4" />
                        <span>Repository</span>
                      </a>
                    </div>
                    <div class="group relative overflow-hidden rounded-xl bg-white/5 border border-white/10 p-6 transition-all hover:border-[#f0551c]/50 hover:bg-white/10">
                      <div class="flex items-center justify-between mb-4">
                        <h3 class="text-lg font-semibold">
                          <a
                            href="https://packages.atopile.io/packages/atopile/addressable-leds/releases/latest"
                            target="_blank"
                            rel="noopener"
                            class="text-white hover:text-[#f0551c] transition-colors"
                          >
                            atopile/addressable-leds
                          </a>
                        </h3>
                        <span class="px-2 py-1 text-xs font-medium bg-[#f0551c]/20 text-[#f0551c] rounded-full">
                          v0.2.2
                        </span>
                      </div>
                      <p class="text-sm text-gray-400 mb-4">
                        SK6805 addressable RGB LEDs with integrated controller for creating colorful LED effects and...
                      </p>
                      <a
                        href="https://github.com/atopile/packages"
                        target="_blank"
                        rel="noopener"
                        class="flex items-center gap-2 text-xs text-[#f0551c] hover:text-[#ff6b33] transition-colors"
                      >
                        <.icon name="github" class="size-4" />
                        <span>Repository</span>
                      </a>
                    </div>
                    <div class="group relative overflow-hidden rounded-xl bg-white/5 border border-white/10 p-6 transition-all hover:border-[#f0551c]/50 hover:bg-white/10">
                      <div class="flex items-center justify-between mb-4">
                        <h3 class="text-lg font-semibold">
                          <a
                            href="https://packages.atopile.io/packages/atopile/indicator-leds/releases/latest"
                            target="_blank"
                            rel="noopener"
                            class="text-white hover:text-[#f0551c] transition-colors"
                          >
                            atopile/indicator-leds
                          </a>
                        </h3>
                        <span class="px-2 py-1 text-xs font-medium bg-[#f0551c]/20 text-[#f0551c] rounded-full">
                          v0.1.1
                        </span>
                      </div>
                      <p class="text-sm text-gray-400 mb-4">Indicator LEDs for convenience</p>
                      <a
                        href="https://github.com/atopile/packages"
                        target="_blank"
                        rel="noopener"
                        class="flex items-center gap-2 text-xs text-[#f0551c] hover:text-[#ff6b33] transition-colors"
                      >
                        <.icon name="github" class="size-4" />
                        <span>Repository</span>
                      </a>
                    </div>
                  </div>
                </div>
              </section>
              <section class="mx-auto my-24 max-w-7xl md:my-36">
                <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                  Media
                </h2>
                <div class="mx-auto grid gap-6 px-6 sm:grid-cols-2 lg:px-8">
                  <a class="block pt-6 md:pt-12" href="https://www.youtube.com/watch?v=7-Q0XVpfW3Y">
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
                              src={~p"/images/challenges/atopile/thumbnail1.png"}
                              alt="atopile product demo"
                            />
                          </div>
                        </div>
                      </div>
                    </div>
                  </a>
                  <a class="block pt-6 md:pt-12" href="https://www.youtube.com/watch?v=glofO5vRMw8">
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
                              src="https://i.ytimg.com/vi/glofO5vRMw8/maxresdefault.jpg"
                              alt="1. Installing atopile"
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
                  <div class="mx-auto mt-6 grid max-w-2xl grid-cols-1 grid-rows-1 gap-8 text-sm/6 text-foreground sm:grid-cols-2 xl:mx-0 xl:max-w-none xl:grid-flow-col xl:grid-cols-4">
                    <div class="sm:col-span-2 xl:col-start-2 xl:row-end-1">
                      <a
                        href="https://news.ycombinator.com/item?id=39263854"
                        target="_blank"
                        rel="noopener"
                        class="group relative overflow-hidden rounded-lg bg-background transition-all"
                      >
                        <img
                          src={~p"/images/challenges/atopile/hn-post.webp"}
                          alt="Hacker News discussion"
                          class="w-full object-cover rounded-lg"
                        />
                      </a>
                      <figure class="mt-6 rounded-2xl bg-card shadow-lg border-2 border-border hover:border-[#37363d] transition-colors">
                        <.link
                          href="https://news.ycombinator.com/item?id=39263854"
                          target="_blank"
                          rel="noopener"
                        >
                          <blockquote class="p-6 text-lg font-semibold tracking-tight text-foreground sm:p-12 sm:text-xl/8 whitespace-pre-line -mt-16">
                            <p>
                              99% of people who put a regulator into their schematic will want an appropriate input and output capacitor... It'll be very exciting if we can move towards a more modular world, where designs can be composed.
                            </p>
                          </blockquote>
                          <figcaption class="flex items-center gap-x-2 p-6 sm:p-12 -mt-12 md:-mt-24">
                            <.icon name="tabler-brand-ycombinator" class="size-6" />
                            <div>
                              <div class="font-semibold text-foreground">Michael T</div>
                            </div>
                          </figcaption>
                        </.link>
                      </figure>
                    </div>
                    <div class="space-y-8 xl:contents xl:space-y-0">
                      <div class="space-y-8 xl:row-span-2">
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#37363d] transition-colors">
                          <.link
                            href="https://news.ycombinator.com/item?id=39263854"
                            target="_blank"
                            rel="noopener"
                          >
                            <blockquote class="text-foreground whitespace-pre-line -mt-12">
                              <p>
                                Looks really useful! As a hardware designer I've had plenty of copy pasting bits of schematics to duplicate common functionality. Seems like this could be really helpful in preventing mistakes and increasing quality.
                              </p>
                            </blockquote>
                            <figcaption class="flex items-center gap-x-2">
                              <.icon name="tabler-brand-ycombinator" class="size-6" />
                              <div>
                                <div class="font-semibold text-foreground">
                                  Liftyee
                                </div>
                              </div>
                            </figcaption>
                          </.link>
                        </figure>
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#37363d] transition-colors">
                          <.link
                            href="https://news.ycombinator.com/item?id=39263854"
                            target="_blank"
                            rel="noopener"
                          >
                            <blockquote class="text-foreground whitespace-pre-line -mt-12">
                              <p>
                                LOVE IT LOVE IT LOVE IT!!! I'm doing a lot of home automation work, and I absolutely hate that I need to use breadboards, hunt for pre-assembled components, or to spend days designing a PCB.
                              </p>
                            </blockquote>
                            <figcaption class="flex items-center gap-x-2">
                              <.icon name="tabler-brand-ycombinator" class="size-6" />
                              <div>
                                <div class="font-semibold text-foreground">
                                  Cyberax
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
                            href="https://news.ycombinator.com/item?id=39263854"
                            target="_blank"
                            rel="noopener"
                          >
                            <blockquote class="text-foreground whitespace-pre-line -mt-12">
                              <p>
                                This has sooo much promise... Imagine optimizing for cost, removing redundancy, simplifying footprints, and prioritizing in-stock inventory over new order components.
                              </p>
                            </blockquote>
                            <figcaption class="flex items-center gap-x-2">
                              <.icon name="tabler-brand-ycombinator" class="size-6" />
                              <div>
                                <div class="font-semibold text-foreground">
                                  Mikeortman
                                </div>
                              </div>
                            </figcaption>
                          </.link>
                        </figure>
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#37363d] transition-colors">
                          <.link
                            href="https://news.ycombinator.com/item?id=39263854"
                            target="_blank"
                            rel="noopener"
                          >
                            <blockquote class="text-foreground whitespace-pre-line -mt-12">
                              <p>
                                We are hoping that ato modules can become a convenient language for the community to share modules with each other, in a similar fashion to python and pypi.
                              </p>
                            </blockquote>
                            <figcaption class="flex items-center gap-x-2">
                              <.icon name="tabler-brand-ycombinator" class="size-6" />
                              <div>
                                <div class="font-semibold text-foreground">
                                  atopile team
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
                          class="rounded-xl border-2 border-[#f0551c] p-3 text-[#f0551c] transition-colors hover:border-[#ff6b33] hover:text-[#ff6b33] sm:p-5"
                          href="https://x.com/atopile_io"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">X (formerly Twitter)</span>
                          <.icon name="tabler-brand-x" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                        <.link
                          class="rounded-xl border-2 border-[#f0551c] p-3 text-[#f0551c] transition-colors hover:border-[#ff6b33] hover:text-[#ff6b33] sm:p-5"
                          href="https://linkedin.com/company/atopile"
                          rel="noopener"
                          target="_blank"
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
                        <.link
                          class="rounded-xl border-2 border-[#f0551c] p-3 text-[#f0551c] transition-colors hover:border-[#ff6b33] hover:text-[#ff6b33] sm:p-5"
                          href="https://github.com/atopile/atopile"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">GitHub</span>
                          <.icon name="github" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                        <.link
                          class="rounded-xl border-2 border-[#f0551c] p-3 text-[#f0551c] transition-colors hover:border-[#ff6b33] hover:text-[#ff6b33] sm:p-5"
                          href="https://www.youtube.com/@atopile_io"
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
                      href="https://github.com/atopile/atopile"
                      class="group/card h-full border border-white/10 bg-black md:gap-8 group relative flex-1 overflow-hidden rounded-xl bg-cover shadow-[0px_3.26536px_2.21381px_0px_rgba(84,_58,_42,_0.08),_0px_7.84712px_5.32008px_0px_rgba(84,_58,_42,_0.11),_0px_14.77543px_10.01724px_0px_rgba(84,_58,_42,_0.14),_0px_26.35684px_17.86905px_0px_rgba(84,_58,_42,_0.16),_0px_49.29758px_33.42209px_0px_rgba(84,_58,_42,_0.19),_0px_118px_80px_0px_rgba(84,_58,_42,_0.27)] hover:no-underline"
                    >
                      <img
                        src="https://fly.storage.tigris.dev/algora-console/repositories/atopile/atopile/og.png"
                        alt="atopile"
                        class="rounded-lg aspect-[1200/630] w-full h-full bg-muted object-cover"
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
