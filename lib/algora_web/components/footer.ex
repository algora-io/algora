defmodule AlgoraWeb.Components.Footer do
  @moduledoc false
  use AlgoraWeb.Component
  use AlgoraWeb, :verified_routes

  import AlgoraWeb.CoreComponents

  alias AlgoraWeb.Constants

  attr :class, :string, default: nil

  def footer(assigns) do
    ~H"""
    <footer aria-labelledby="footer-heading" class="relative overflow-hidden">
      <h2 id="footer-heading" class="sr-only">Footer</h2>

      <div class={
        classes([
          "relative mx-auto max-w-7xl px-6 lg:px-8 border-t border-white/10 pt-16",
          @class
        ])
      }>
        <div>
          <div class="grid grid-cols-2 gap-x-8 gap-y-12 sm:grid-cols-3 lg:grid-cols-5">
            <%!-- Col 1: Company + phone numbers --%>
            <div class="sm:col-span-1">
              <h3 class="text-sm font-semibold uppercase tracking-wider text-white">
                <.wordmark class="h-6 md:h-8 w-auto text-white" />
              </h3>
              <ul role="list" class="mt-6 space-y-3">
                <li class="text-sm font-medium text-muted-foreground">
                  Algora PBC © {Date.utc_today().year}
                </li>
                <li>
                  <.link
                    href="https://cal.com/ioannisflo"
                    class="flex items-center text-sm text-muted-foreground hover:text-white transition-colors"
                    rel="noopener"
                  >
                    <span class="tabler-calendar-clock size-3 md:size-4"></span>
                    <span class="ml-1.5">Schedule a call</span>
                  </.link>
                </li>
                <li>
                  <.link
                    href="tel:+16504202207"
                    class="flex items-center text-sm text-muted-foreground hover:text-white transition-colors"
                    target="_blank"
                  >
                    <span class="tabler-phone size-3 md:size-4"></span>
                    <span class="font-bold ml-1 hidden md:inline">US</span>
                    <span class="ml-1">+1 (650) 420-2207</span>
                  </.link>
                </li>
                <li>
                  <.link
                    href="tel:+306973184144"
                    class="flex items-center text-sm text-muted-foreground hover:text-white transition-colors"
                    target="_blank"
                  >
                    <span class="tabler-phone size-3 md:size-4"></span>
                    <span class="font-bold ml-1 hidden md:inline">EU</span>
                    <span class="ml-1">+30 (697) 318-4144</span>
                  </.link>
                </li>
              </ul>
            </div>

            <%!-- Col 2: Recruiting + customers --%>
            <div class="sm:col-span-1">
              <h3 class="text-sm font-semibold uppercase tracking-wider text-white">
                Recruiting
              </h3>
              <ul role="list" class="mt-6 space-y-3">
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    href="/coderabbit/jobs"
                    target="_blank"
                  >
                    CodeRabbit
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    href="/lovable/jobs"
                    target="_blank"
                  >
                    Lovable
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    href="/comfy/jobs"
                    target="_blank"
                  >
                    ComfyUI
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    href="/firecrawl/jobs"
                    target="_blank"
                  >
                    Firecrawl (YC S22)
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    href="/airspace-intelligence/jobs"
                    target="_blank"
                  >
                    Air Space Intelligence
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    href="/textql/jobs"
                    target="_blank"
                  >
                    TextQL
                  </.link>
                </li>
              </ul>
            </div>

            <%!-- Col 3: Bounties --%>
            <div class="sm:col-span-1">
              <h3 class="text-sm font-semibold uppercase tracking-wider text-white">
                Bounties
              </h3>
              <ul role="list" class="mt-6 space-y-3">
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    navigate={~p"/challenges/jules"}
                  >
                    Jules
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    navigate={~p"/challenges/turso"}
                  >
                    Turso
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    navigate={~p"/challenges/atopile"}
                  >
                    Atopile (YC W24)
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    navigate={~p"/challenges/golem"}
                  >
                    Golem Cloud
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    navigate={~p"/challenges/tsperf"}
                  >
                    TSPerf
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    navigate={~p"/challenges/prettier"}
                  >
                    Prettier
                  </.link>
                </li>
              </ul>
            </div>

            <%!-- Col 4: Connect --%>
            <div class="sm:col-span-1">
              <h3 class="text-sm font-semibold uppercase tracking-wider text-white">
                Community
              </h3>
              <ul role="list" class="mt-6 space-y-3">
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    href="https://www.youtube.com/watch?v=ZXz74ZewxwY&list=PLRIG8mKLBXFotOxF234rEIREidMRh98Hv&t=229s"
                    rel="noopener"
                    target="_blank"
                  >
                    OSS Founder Podcast
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    href={Constants.get(:github_url)}
                    rel="noopener"
                    target="_blank"
                  >
                    GitHub
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    href={Constants.get(:twitter_url)}
                    rel="noopener"
                    target="_blank"
                  >
                    X (Twitter)
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    href={Constants.get(:linkedin_url)}
                    rel="noopener"
                    target="_blank"
                  >
                    LinkedIn
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    href={Constants.get(:discord_url)}
                    rel="noopener"
                    target="_blank"
                  >
                    Discord
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    href={Constants.get(:youtube_url)}
                    rel="noopener"
                    target="_blank"
                  >
                    YouTube
                  </.link>
                </li>
              </ul>
            </div>

            <%!-- Col 5: Legal --%>
            <div class="sm:col-span-1">
              <h3 class="text-sm font-semibold uppercase tracking-wider text-white">
                Legal
              </h3>
              <ul role="list" class="mt-6 space-y-3">
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    href={Constants.get(:terms_url)}
                  >
                    Terms of Service
                  </.link>
                </li>
                <li>
                  <.link
                    class="text-sm text-muted-foreground hover:text-white transition-colors"
                    href={Constants.get(:privacy_url)}
                  >
                    Privacy Policy
                  </.link>
                </li>
              </ul>
            </div>
          </div>
        </div>

        <%!-- Full-width algora wordmark: gradient fades top-to-bottom, bottom clipped so page can't scroll to show full wordmark --%>
        <div class="mt-4 sm:mt-8 md:mt-12 relative w-full left-1/2 -translate-x-1/2 h-[28vw] overflow-hidden pointer-events-none select-none">
          <div
            class="absolute inset-x-0 top-0 w-full min-h-[36vw]"
            style={"background: linear-gradient(to bottom, rgba(161,161,170,0.2) 0%, rgba(113,113,122,0.08) 50%, transparent 100%); -webkit-mask-image: url(#{~p"/images/wordmarks/algora.svg"}); mask-image: url(#{~p"/images/wordmarks/algora.svg"}); -webkit-mask-size: 100% auto; mask-size: 100% auto; -webkit-mask-repeat: no-repeat; mask-repeat: no-repeat; -webkit-mask-position: center top; mask-position: center top;"}
          >
          </div>
        </div>
      </div>
    </footer>
    """
  end
end
