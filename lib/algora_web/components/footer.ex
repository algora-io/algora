defmodule AlgoraWeb.Components.Footer do
  @moduledoc false
  use AlgoraWeb.Component
  use AlgoraWeb, :verified_routes

  import AlgoraWeb.CoreComponents

  attr :class, :string, default: nil

  def footer(assigns) do
    ~H"""
    <footer aria-labelledby="footer-heading" class="relative overflow-hidden">
      <h2 id="footer-heading" class="sr-only">Footer</h2>

      <div class={
        classes([
          "relative mx-auto max-w-7xl px-6 lg:px-8 border-t border-white/10 pt-8",
          @class
        ])
      }>
        <div class="flex flex-wrap items-center gap-x-3 gap-y-2 text-sm text-muted-foreground">
          <span>Algora PBC © {Date.utc_today().year}</span>
          <span class="text-white/20 hidden sm:inline">·</span>
          <.link
            href="https://cal.com/ioannisflo"
            rel="noopener"
            class="flex items-center gap-1.5 hover:text-white transition-colors"
          >
            <span class="tabler-calendar-clock size-3.5 shrink-0"></span>
            Schedule a call
          </.link>
          <span class="text-white/20">·</span>
          <.link href="tel:+16504202207" class="hover:text-white transition-colors">
            +1 (650) 420-2207
          </.link>
          <span class="text-white/20">·</span>
          <.link href="tel:+306973184144" class="hover:text-white transition-colors">
            +30 (697) 318-4144
          </.link>
        </div>

        <%!-- Full-width algora wordmark --%>
        <div class="mt-8 relative w-full left-1/2 -translate-x-1/2 h-[28vw] overflow-hidden pointer-events-none select-none">
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
