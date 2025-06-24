defmodule AlgoraWeb.Challenges.ActivepiecesLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias AlgoraWeb.Components.Header

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Activepieces MCP Challenge")
     |> assign(
       :page_description,
       "Build MCPs for Activepieces and earn $200 per integration!"
     )
     |> assign(:page_image, "#{AlgoraWeb.Endpoint.url()}/images/challenges/activepieces/og.png")}
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
                      href="https://activepieces.com"
                      class="inline-flex items-center bg-[#1a1a2e]/75 hover:bg-[#09090b] ring-1 ring-[#843ee5] hover:ring-[#9f5aea] py-2 px-4 rounded-full font-medium text-violet-400/90 hover:text-violet-400 text-base transition-colors"
                    >
                      <span class="hidden sm:inline">Challenge brought to you by</span><span class="inline sm:hidden">Challenge by</span>
                      <img
                        src={~p"/images/wordmarks/activepieces-dark.png"}
                        alt="Activepieces"
                        class="ml-2 h-5"
                        style="aspect-ratio: 945/147;"
                      />
                    </a>
                    <h1 class="mt-6 mb-2 text-[1.4rem] font-black tracking-tighter mix-blend-exclusion sm:text-5xl/[3rem] md:text-6xl/[4rem] lg:text-7xl/[5rem]">
                      Expand Activepieces with MCPs<br />
                      <span style="background: radial-gradient(53.44% 245.78% at 13.64% 46.56%, rgb(132, 62, 229) 0%, rgb(159, 90, 234) 100%) text; -webkit-text-fill-color: transparent;">
                        Earn <span class="font-display">$200</span> per integration
                      </span>
                    </h1>
                    <p class="max-w-xl xl:max-w-2xl mt-4 text-base font-medium tracking-tight text-white/90 shadow-black [text-shadow:_0_1px_0_var(--tw-shadow-color)] md:mt-6 md:text-lg md:text-white/80">
                      Activepieces is revolutionizing workflow automation with an open-source, AI-first platform that already supports 280+ integrations. With 60% of pieces contributed by the community, we're building the most extensible automation ecosystem.
                      <br /><br />
                      Now we're expanding into the MCP (Model Context Protocol) ecosystem, enabling LLMs like Claude to directly interact with your favorite tools. Build MCPs that bridge the gap between AI and automation, and earn
                      <span class="font-display font-bold text-foreground">$200</span>
                      for each accepted MCP integration. Join us in making AI more capable and connected.
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
                    src={~p"/images/challenges/activepieces/bg.png"}
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
                      href="https://discord.gg/2jUXBKDdP8"
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
                          href="https://github.com/activepieces/activepieces"
                        >
                          Fork the Activepieces repository
                        </a>
                        and set up your local development environment
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-2" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Learn about
                        <a
                          rel="noopener"
                          target="_blank"
                          class="font-semibold text-white underline inline-flex"
                          href="https://modelcontextprotocol.io"
                        >
                          Model Context Protocol (MCP)
                        </a>
                        and explore existing
                        <a
                          rel="noopener"
                          target="_blank"
                          class="font-semibold text-white underline inline-flex"
                          href="https://www.activepieces.com/mcp"
                        >
                          Activepieces MCPs
                        </a>
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-3" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Choose a service to integrate from the list below and build an MCP that enables LLMs to interact with that service through Activepieces
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-4" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Submit a PR with your MCP implementatio including comprehensive documentation and examples
                      </span>
                    </li>
                    <li class="flex w-full items-start pt-2 text-left text-white">
                      <.icon name="tabler-square-rounded-number-5" class="size-8 mr-2 shrink-0" />
                      <span class="text-base font-medium leading-7">
                        Once your MCP is reviewed and merged, receive your bounty reward up to
                        <span class="font-display font-bold text-violet-400">$200</span>
                      </span>
                    </li>
                  </ul>
                </div>
              </section>
              <section class="mx-auto my-24 max-w-7xl md:my-36">
                <h2 class="flex justify-center text-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                  Available MCP Bounties
                </h2>
                <p class="text-center mt-4 text-base font-medium text-gray-200 mb-8">
                  Ready to contribute? Select a bounty to start building. Each bounty includes detailed requirements and compensation.
                </p>
                <div class="mx-auto grid gap-6 px-6 sm:grid-cols-2 lg:grid-cols-3 lg:px-8">
                  <a
                    href="https://github.com/activepieces/activepieces/issues/8135"
                    target="_blank"
                    rel="noopener"
                    class="group relative overflow-hidden rounded-lg border border-border bg-card p-6 transition-all hover:border-[#843ee5]/50 hover:no-underline block"
                  >
                    <div class="flex items-center gap-4 mb-4">
                      <img
                        src="https://github.com/canva.png"
                        alt="Canva"
                        class="w-12 h-12 rounded-lg"
                      />
                      <div>
                        <h3 class="text-lg font-semibold text-foreground">Canva MCP</h3>
                        <p class="text-sm text-muted-foreground">Design creation</p>
                      </div>
                    </div>
                    <p class="text-sm text-muted-foreground">
                      Create designs, manage templates, and automate graphic design workflows
                    </p>
                    <div class="mt-4 flex items-center gap-2">
                      <span class="font-display rounded-full bg-violet-500/10 px-2 py-1 text-xs font-bold text-violet-500 ring-violet-500/50 ring-1">
                        $100
                      </span>
                      <span class="font-display rounded-full bg-emerald-500/10 px-2 py-1 text-xs font-bold text-emerald-500 ring-emerald-500/50 ring-1">
                        Active
                      </span>
                    </div>
                  </a>
                  <a
                    href="https://github.com/activepieces/activepieces/issues/8072"
                    target="_blank"
                    rel="noopener"
                    class="group relative overflow-hidden rounded-lg border border-border bg-card p-6 transition-all hover:border-violet-500/50 hover:no-underline block"
                  >
                    <div class="flex items-center gap-4 mb-4">
                      <img
                        src="https://github.com/google.png"
                        alt="Gmail"
                        class="w-12 h-12 rounded-lg"
                      />
                      <div>
                        <h3 class="text-lg font-semibold text-foreground">Gmail MCP</h3>
                        <p class="text-sm text-muted-foreground">Email management</p>
                      </div>
                    </div>
                    <p class="text-sm text-muted-foreground">
                      Send emails, manage inbox, and automate email workflows through AI
                    </p>
                    <div class="mt-4 flex items-center gap-2">
                      <span class="font-display rounded-full bg-violet-500/10 px-2 py-1 text-xs font-bold text-violet-500 ring-violet-500/50 ring-1">
                        $200
                      </span>
                      <span class="font-display rounded-full bg-emerald-500/10 px-2 py-1 text-xs font-bold text-emerald-500 ring-emerald-500/50 ring-1">
                        Active
                      </span>
                    </div>
                  </a>
                  <a
                    href="https://github.com/activepieces/activepieces/issues/8021"
                    target="_blank"
                    rel="noopener"
                    class="group relative overflow-hidden rounded-lg border border-border bg-card p-6 transition-all hover:border-violet-500/50 hover:no-underline block"
                  >
                    <div class="flex items-center gap-4 mb-4">
                      <img
                        src="https://github.com/skyvern-ai.png"
                        alt="Skyvern"
                        class="w-12 h-12 rounded-lg"
                      />
                      <div>
                        <h3 class="text-lg font-semibold text-foreground">Skyvern MCP</h3>
                        <p class="text-sm text-muted-foreground">Web automation</p>
                      </div>
                    </div>
                    <p class="text-sm text-muted-foreground">
                      Automate web interactions and workflows using AI-powered browser automation
                    </p>
                    <div class="mt-4 flex items-center gap-2">
                      <span class="font-display rounded-full bg-violet-500/10 px-2 py-1 text-xs font-bold text-violet-500 ring-violet-500/50 ring-1">
                        $100
                      </span>
                      <span class="font-display rounded-full bg-emerald-500/10 px-2 py-1 text-xs font-bold text-emerald-500 ring-emerald-500/50 ring-1">
                        Active
                      </span>
                    </div>
                  </a>
                  <a
                    href="https://github.com/activepieces/activepieces/issues/8018"
                    target="_blank"
                    rel="noopener"
                    class="group relative overflow-hidden rounded-lg border border-border bg-card p-6 transition-all hover:border-violet-500/50 hover:no-underline block"
                  >
                    <div class="flex items-center gap-4 mb-4">
                      <img
                        src="https://github.com/dimo-network.png"
                        alt="DIMO"
                        class="w-12 h-12 rounded-lg"
                      />
                      <div>
                        <h3 class="text-lg font-semibold text-foreground">DIMO MCP</h3>
                        <p class="text-sm text-muted-foreground">Vehicle data</p>
                      </div>
                    </div>
                    <p class="text-sm text-muted-foreground">
                      Access vehicle data and manage connected car integrations through DIMO network
                    </p>
                    <div class="mt-4 flex items-center gap-2">
                      <span class="font-display rounded-full bg-violet-500/10 px-2 py-1 text-xs font-bold text-violet-500 ring-violet-500/50 ring-1">
                        $200
                      </span>
                      <span class="font-display rounded-full bg-emerald-500/10 px-2 py-1 text-xs font-bold text-emerald-500 ring-emerald-500/50 ring-1">
                        Active
                      </span>
                    </div>
                  </a>
                  <a
                    href="https://github.com/activepieces/activepieces/issues/7931"
                    target="_blank"
                    rel="noopener"
                    class="group relative overflow-hidden rounded-lg border border-border bg-card p-6 transition-all hover:border-violet-500/50 hover:no-underline block"
                  >
                    <div class="flex items-center gap-4 mb-4">
                      <img
                        src="https://github.com/deepgram.png"
                        alt="Deepgram"
                        class="w-12 h-12 rounded-lg"
                      />
                      <div>
                        <h3 class="text-lg font-semibold text-foreground">Deepgram MCP</h3>
                        <p class="text-sm text-muted-foreground">Speech recognition</p>
                      </div>
                    </div>
                    <p class="text-sm text-muted-foreground">
                      Transcribe audio, analyze speech, and integrate voice recognition capabilities
                    </p>
                    <div class="mt-4 flex items-center gap-2">
                      <span class="font-display rounded-full bg-violet-500/10 px-2 py-1 text-xs font-bold text-violet-500 ring-violet-500/50 ring-1">
                        $50
                      </span>
                      <span class="font-display rounded-full bg-emerald-500/10 px-2 py-1 text-xs font-bold text-emerald-500 ring-emerald-500/50 ring-1">
                        Active
                      </span>
                    </div>
                  </a>
                  <a
                    href="https://github.com/activepieces/activepieces/issues/7927"
                    target="_blank"
                    rel="noopener"
                    class="group relative overflow-hidden rounded-lg border border-border bg-card p-6 transition-all hover:border-violet-500/50 hover:no-underline block"
                  >
                    <div class="flex items-center gap-4 mb-4">
                      <img
                        src="/images/logos/airparser.jpeg"
                        alt="Airparser"
                        class="w-12 h-12 rounded-lg"
                      />
                      <div>
                        <h3 class="text-lg font-semibold text-foreground">Airparser MCP</h3>
                        <p class="text-sm text-muted-foreground">Document parsing</p>
                      </div>
                    </div>
                    <p class="text-sm text-muted-foreground">
                      Extract data from documents and automate document processing workflows
                    </p>
                    <div class="mt-4 flex items-center gap-2">
                      <span class="font-display rounded-full bg-violet-500/10 px-2 py-1 text-xs font-bold text-violet-500 ring-violet-500/50 ring-1">
                        $50
                      </span>
                      <span class="font-display rounded-full bg-emerald-500/10 px-2 py-1 text-xs font-bold text-emerald-500 ring-emerald-500/50 ring-1">
                        Active
                      </span>
                    </div>
                  </a>
                  <a
                    href="https://github.com/activepieces/activepieces/issues/7925"
                    target="_blank"
                    rel="noopener"
                    class="group relative overflow-hidden rounded-lg border border-border bg-card p-6 transition-all hover:border-violet-500/50 hover:no-underline block"
                  >
                    <div class="flex items-center gap-4 mb-4">
                      <img src="/images/logos/memdotai.jpeg" alt="Mem" class="w-12 h-12 rounded-lg" />
                      <div>
                        <h3 class="text-lg font-semibold text-foreground">Mem MCP</h3>
                        <p class="text-sm text-muted-foreground">AI knowledge base</p>
                      </div>
                    </div>
                    <p class="text-sm text-muted-foreground">
                      Manage personal knowledge base and AI-powered note organization
                    </p>
                    <div class="mt-4 flex items-center gap-2">
                      <span class="font-display rounded-full bg-violet-500/10 px-2 py-1 text-xs font-bold text-violet-500 ring-violet-500/50 ring-1">
                        $30
                      </span>
                      <span class="font-display rounded-full bg-emerald-500/10 px-2 py-1 text-xs font-bold text-emerald-500 ring-emerald-500/50 ring-1">
                        Active
                      </span>
                    </div>
                  </a>
                  <a
                    href="https://github.com/activepieces/activepieces/issues/7923"
                    target="_blank"
                    rel="noopener"
                    class="group relative overflow-hidden rounded-lg border border-border bg-card p-6 transition-all hover:border-violet-500/50 hover:no-underline block"
                  >
                    <div class="flex items-center gap-4 mb-4">
                      <img
                        src="/images/logos/chatbase.jpeg"
                        alt="Chatbase"
                        class="w-12 h-12 rounded-lg"
                      />
                      <div>
                        <h3 class="text-lg font-semibold text-foreground">Chatbase MCP</h3>
                        <p class="text-sm text-muted-foreground">AI chatbot platform</p>
                      </div>
                    </div>
                    <p class="text-sm text-muted-foreground">
                      Create and manage AI chatbots, train on custom data, and handle conversations
                    </p>
                    <div class="mt-4 flex items-center gap-2">
                      <span class="font-display rounded-full bg-violet-500/10 px-2 py-1 text-xs font-bold text-violet-500 ring-violet-500/50 ring-1">
                        $50
                      </span>
                      <span class="font-display rounded-full bg-emerald-500/10 px-2 py-1 text-xs font-bold text-emerald-500 ring-emerald-500/50 ring-1">
                        Active
                      </span>
                    </div>
                  </a>
                  <a
                    href="https://github.com/activepieces/activepieces/issues/7921"
                    target="_blank"
                    rel="noopener"
                    class="group relative overflow-hidden rounded-lg border border-border bg-card p-6 transition-all hover:border-violet-500/50 hover:no-underline block"
                  >
                    <div class="flex items-center gap-4 mb-4">
                      <img
                        src="https://github.com/smartsheet.png"
                        alt="Smartsheet"
                        class="w-12 h-12 rounded-lg"
                      />
                      <div>
                        <h3 class="text-lg font-semibold text-foreground">Smartsheet MCP</h3>
                        <p class="text-sm text-muted-foreground">Project management</p>
                      </div>
                    </div>
                    <p class="text-sm text-muted-foreground">
                      Manage projects, update sheets, and automate Smartsheet workflows
                    </p>
                    <div class="mt-4 flex items-center gap-2">
                      <span class="font-display rounded-full bg-violet-500/10 px-2 py-1 text-xs font-bold text-violet-500 ring-violet-500/50 ring-1">
                        $100
                      </span>
                      <span class="font-display rounded-full bg-emerald-500/10 px-2 py-1 text-xs font-bold text-emerald-500 ring-emerald-500/50 ring-1">
                        Active
                      </span>
                    </div>
                  </a>
                  <a
                    href="https://github.com/activepieces/activepieces/issues/7919"
                    target="_blank"
                    rel="noopener"
                    class="group relative overflow-hidden rounded-lg border border-border bg-card p-6 transition-all hover:border-violet-500/50 hover:no-underline block"
                  >
                    <div class="flex items-center gap-4 mb-4">
                      <img
                        src="https://github.com/crisp-im.png"
                        alt="Crisp"
                        class="w-12 h-12 rounded-lg"
                      />
                      <div>
                        <h3 class="text-lg font-semibold text-foreground">Crisp MCP</h3>
                        <p class="text-sm text-muted-foreground">Customer support</p>
                      </div>
                    </div>
                    <p class="text-sm text-muted-foreground">
                      Manage customer conversations, automate support workflows, and handle live chat
                    </p>
                    <div class="mt-4 flex items-center gap-2">
                      <span class="font-display rounded-full bg-violet-500/10 px-2 py-1 text-xs font-bold text-violet-500 ring-violet-500/50 ring-1">
                        $100
                      </span>
                      <span class="font-display rounded-full bg-emerald-500/10 px-2 py-1 text-xs font-bold text-emerald-500 ring-emerald-500/50 ring-1">
                        Active
                      </span>
                    </div>
                  </a>
                </div>
                <div class="text-center mt-8">
                  <p class="text-base font-medium text-gray-200">
                    Don't see your favorite tool? Propose a new MCP integration in our
                    <a
                      target="_blank"
                      class="font-semibold text-white underline"
                      href="https://discord.gg/2jUXBKDdP8"
                    >
                      Discord community
                    </a>
                  </p>
                </div>
              </section>
              <section class="mx-auto my-24 max-w-7xl md:my-36">
                <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                  Media
                </h2>
                <div class="mx-auto grid gap-6 px-6 sm:grid-cols-2 lg:px-8">
                  <a class="block pt-6 md:pt-12" href="https://www.youtube.com/watch?v=60EswP3aa0M">
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
                              src="https://i.ytimg.com/vi/60EswP3aa0M/maxresdefault.jpg"
                              alt="atopile product demo"
                            />
                          </div>
                        </div>
                      </div>
                    </div>
                  </a>
                  <a class="block pt-6 md:pt-12" href="https://www.youtube.com/watch?v=O_rmtv-6xl8">
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
                              src="https://i.ytimg.com/vi/O_rmtv-6xl8/maxresdefault.jpg"
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
                        href="https://news.ycombinator.com/item?id=34723989"
                        target="_blank"
                        rel="noopener"
                        class="group relative overflow-hidden rounded-lg bg-background transition-all"
                      >
                        <img
                          src={~p"/images/challenges/activepieces/hn-post.png"}
                          alt="Hacker News discussion"
                          class="w-full object-cover rounded-lg"
                        />
                      </a>
                      <figure class="mt-6 rounded-2xl bg-card shadow-lg border-2 border-border hover:border-[#843ee5]/50 transition-colors">
                        <.link
                          href="https://news.ycombinator.com/item?id=34723989"
                          target="_blank"
                          rel="noopener"
                        >
                          <blockquote class="p-6 text-lg font-semibold tracking-tight text-foreground sm:p-12 sm:text-xl/8 whitespace-pre-line -mt-16">
                            <p>
                              Huge TAM so there's lots of room for a healthy ecosystem of competitors in no code low code... UX is important. Spend the resources as you scale to understand how your users are leveraging your product for their workflows; it should be magical to them.
                            </p>
                          </blockquote>
                          <figcaption class="flex items-center gap-x-2 p-6 sm:p-12 -mt-12 md:-mt-24">
                            <.icon name="tabler-brand-ycombinator" class="size-6" />
                            <div>
                              <div class="font-semibold text-foreground">toomuchtodo</div>
                            </div>
                          </figcaption>
                        </.link>
                      </figure>
                    </div>
                    <div class="space-y-8 xl:contents xl:space-y-0">
                      <div class="space-y-8 xl:row-span-2">
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#843ee5]/50 transition-colors">
                          <.link
                            href="https://news.ycombinator.com/item?id=34723989"
                            target="_blank"
                            rel="noopener"
                          >
                            <blockquote class="text-foreground whitespace-pre-line -mt-12">
                              <p>
                                Ah man this is fantastic... Love what you are doing with authentication/connections to other services.
                              </p>
                            </blockquote>
                            <figcaption class="flex items-center gap-x-2">
                              <.icon name="tabler-brand-ycombinator" class="size-6" />
                              <div>
                                <div class="font-semibold text-foreground">
                                  WatchDog
                                </div>
                              </div>
                            </figcaption>
                          </.link>
                        </figure>
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#843ee5]/50 transition-colors">
                          <.link
                            href="https://news.ycombinator.com/item?id=34723989"
                            target="_blank"
                            rel="noopener"
                          >
                            <blockquote class="text-foreground whitespace-pre-line -mt-12">
                              <p>
                                Excited about this open source alternative!
                              </p>
                            </blockquote>
                            <figcaption class="flex items-center gap-x-2">
                              <.icon name="tabler-brand-ycombinator" class="size-6" />
                              <div>
                                <div class="font-semibold text-foreground">
                                  edotrajan
                                </div>
                              </div>
                            </figcaption>
                          </.link>
                        </figure>
                      </div>
                    </div>
                    <div class="space-y-8 xl:contents xl:space-y-0">
                      <div class="space-y-8 xl:row-span-2">
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#843ee5]/50 transition-colors">
                          <.link
                            href="https://news.ycombinator.com/item?id=34723989"
                            target="_blank"
                            rel="noopener"
                          >
                            <blockquote class="text-foreground whitespace-pre-line -mt-12">
                              <p>
                                Having a large Open Source ecosystem increases the size of the pie.
                              </p>
                            </blockquote>
                            <figcaption class="flex items-center gap-x-2">
                              <.icon name="tabler-brand-ycombinator" class="size-6" />
                              <div>
                                <div class="font-semibold text-foreground">
                                  ensignavenger
                                </div>
                              </div>
                            </figcaption>
                          </.link>
                        </figure>
                        <figure class="rounded-2xl bg-card p-6 shadow-lg border-2 border-border hover:border-[#843ee5]/50 transition-colors">
                          <.link
                            href="https://news.ycombinator.com/item?id=34723989"
                            target="_blank"
                            rel="noopener"
                          >
                            <blockquote class="text-foreground whitespace-pre-line -mt-12">
                              <p>
                                MIT license builds the trust to use it and contribute to it.
                              </p>
                            </blockquote>
                            <figcaption class="flex items-center gap-x-2">
                              <.icon name="tabler-brand-ycombinator" class="size-6" />
                              <div>
                                <div class="font-semibold text-foreground">
                                  vishalchandra
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
                          class="rounded-xl border-2 border-[#843ee5] p-3 text-[#843ee5] transition-colors hover:border-[#9f5aea] hover:text-[#9f5aea] sm:p-5"
                          href="https://discord.gg/2jUXBKDdP8"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">Discord</span>
                          <.icon name="tabler-brand-discord-filled" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                        <.link
                          class="rounded-xl border-2 border-[#843ee5] p-3 text-[#843ee5] transition-colors hover:border-[#9f5aea] hover:text-[#9f5aea] sm:p-5"
                          href="https://x.com/activepieces"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">X (formerly Twitter)</span>
                          <.icon name="tabler-brand-x" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                        <.link
                          class="rounded-xl border-2 border-[#843ee5] p-3 text-[#843ee5] transition-colors hover:border-[#9f5aea] hover:text-[#9f5aea] sm:p-5"
                          href="https://github.com/activepieces/activepieces"
                          rel="noopener"
                          target="_blank"
                        >
                          <span class="sr-only">GitHub</span>
                          <.icon name="github" class="h-6 w-6 sm:h-12 sm:w-12" />
                        </.link>
                        <.link
                          class="rounded-xl border-2 border-[#843ee5] p-3 text-[#843ee5] transition-colors hover:border-[#9f5aea] hover:text-[#9f5aea] sm:p-5"
                          href="https://www.youtube.com/@activepiecesco"
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
                      href="https://github.com/activepieces/activepieces"
                      class="group/card h-full border border-white/10 bg-black md:gap-8 group relative flex-1 overflow-hidden rounded-xl bg-cover shadow-[0px_3.26536px_2.21381px_0px_rgba(49,_8,_105,_0.08),_0px_7.84712px_5.32008px_0px_rgba(49,_8,_105,_0.11),_0px_14.77543px_10.01724px_0px_rgba(49,_8,_105,_0.14),_0px_26.35684px_17.86905px_0px_rgba(49,_8,_105,_0.16),_0px_49.29758px_33.42209px_0px_rgba(49,_8,_105,_0.19),_0px_118px_80px_0px_rgba(49,_8,_105,_0.27)] hover:no-underline"
                    >
                      <img
                        src="https://fly.storage.tigris.dev/algora-console/repositories/activepieces/activepieces/og.png"
                        alt="activepieces"
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
