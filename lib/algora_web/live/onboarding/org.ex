defmodule AlgoraWeb.Onboarding.OrgLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

  require Logger

  defp placeholder_text do
    """
    - GitHub looks like a green carpet, red flag if wearing suit
    - Great communication skills, can talk to customers
    - Must be a shark, aggressive, has urgency and agency
    - Has contributions to open source inference engines (like vLLM)
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="bg-black relative overflow-hidden min-h-screen flex flex-col">
      <header class="w-full border-b border-white/20">
        <div class="flex items-center gap-8 bg-background">
          <div>
            <.wordmark class="h-8 w-auto ml-24" />
          </div>
          <div class="h-full flex flex-col bg-black border-l border-white/20 pl-8 py-8 -mt-5">
            <span class="text-xs text-muted-foreground font-medium">Trusted by</span>
            <div class="mt-1 flex items-center justify-center gap-12">
              <img src="/images/wordmarks/keep.png" alt="Keep" class="h-10 saturate-0" />
              <img src="/images/wordmarks/triggerdotdev.png" alt="Trigger.dev" class="h-6 saturate-0" />
              <img src="/images/wordmarks/traceloop.png" alt="Traceloop" class="h-6 saturate-0" />
              <img src="/images/wordmarks/million.png" alt="Million" class="h-6 saturate-0" />
              <img src="/images/wordmarks/moonrepo.svg" alt="moon" class="h-5" />
              <img
                src="/images/wordmarks/dittofeed.png"
                alt="Dittofeed"
                class="h-6 brightness-0 invert"
              />
              <img
                src={~p"/images/wordmarks/highlight.png"}
                alt="Highlight"
                class="h-6 saturate-0"
                loading="lazy"
              />
            </div>
          </div>
        </div>
      </header>

      <div class="flex-1 flex items-center justify-center">
        <div class="w-full max-w-[28rem] text-left -mt-4">
          <form class="flex flex-col gap-6">
            <.input name="email" value="" label="Work email" placeholder="you@company.com" />
            <.input
              type="textarea"
              name="job_description"
              value=""
              label="Job description / careers URL"
              rows="4"
              placeholder="Tell us about the role and your requirements..."
            />
            <.input
              type="textarea"
              name="job_description"
              value=""
              label="Describe your ideal candidate, heuristics, green/red flags etc."
              rows="4"
              placeholder={placeholder_text()}
            />
            <div class="flex flex-col gap-4">
              <.button class="w-full">Receive your candidates</.button>
              <div class="text-xs text-muted-foreground text-center">
                No credit card required - only pay when you hire
              </div>
            </div>
          </form>
        </div>
      </div>

      <footer class="w-full py-8 border-t border-white/20">
        <div class="container mx-auto px-4">
          <div class="flex flex-col md:flex-row items-center justify-between gap-6">
            <div class="text-sm text-muted-foreground">
              © 2025 Algora PBC. All rights reserved.
            </div>
            <div class="flex items-center gap-4">
              <.button variant="outline">Schedule a call</.button>
              <div class="flex gap-2">
                <.link
                  class="flex w-max items-center gap-2 rounded-lg border border-gray-700 py-2 pl-2 pr-3.5 text-xs text-muted-foreground hover:text-foreground transition-colors hover:border-gray-600"
                  href="tel:+16504202207"
                >
                  <.icon name="tabler-phone-filled" class="size-4" /> US
                  <span>+1 (650) 420-2207</span>
                </.link>
                <.link
                  class="flex w-max items-center gap-2 rounded-lg border border-gray-700 py-2 pl-2 pr-3.5 text-xs text-muted-foreground hover:text-foreground transition-colors hover:border-gray-600"
                  href="tel:+306973184144"
                >
                  <.icon name="tabler-phone-filled" class="size-4" /> EU
                  <span>+30 (697) 318-4144</span>
                </.link>
              </div>
            </div>
          </div>
        </div>
      </footer>
    </main>
    """
  end
end
