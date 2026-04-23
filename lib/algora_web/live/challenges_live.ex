defmodule AlgoraWeb.ChallengesLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias AlgoraWeb.Components.Footer
  alias AlgoraWeb.Components.Header

  def render(assigns) do
    ~H"""
    <style>
      .dot-grid {
        background-image: radial-gradient(circle, rgba(255,255,255,0.1) 1px, transparent 1px);
        background-size: 28px 28px;
      }
    </style>
    <div class="relative min-h-screen bg-background dot-grid">
      <Header.header />

      <div class="pointer-events-none absolute inset-0 overflow-hidden" aria-hidden="true">
        <div class="absolute top-1/5 -right-48 w-[500px] h-[500px] rounded-full bg-white/[3%] blur-[100px]">
        </div>
        <div class="absolute top-1/5 -left-48 w-[500px] h-[500px] rounded-full bg-white/[3%] blur-[100px]">
        </div>
      </div>
      <main class="relative z-10 mx-auto max-w-7xl px-6 lg:px-8 pt-28">
        <%!-- Page header --%>
        <div class="mb-14 text-center">
          <h1 class="text-5xl font-black font-display tracking-tighter sm:text-6xl lg:text-7xl text-foreground">
            Challenges
          </h1>
        </div>

        <%!-- Active challenges --%>
        <div class="mb-6 flex items-center gap-4">
          <div class="h-px flex-1 bg-border/60"></div>
          <span class="flex items-center gap-1.5 text-xs font-medium uppercase tracking-widest text-muted-foreground">
            <span class="size-1.5 rounded-full bg-emerald-500"></span> Active
          </span>
          <div class="h-px flex-1 bg-border/60"></div>
        </div>
        <div class="flex flex-col gap-6 md:grid md:grid-cols-3">
          <.challenge_card
            image="/images/challenges/jules/og.png"
            href={~p"/challenges/jules"}
            status={:active}
          />
          <.challenge_card
            image="/images/challenges/limbo/og.png"
            href={~p"/challenges/turso"}
            status={:active}
          />
        </div>

        <%!-- Divider --%>
        <div class="my-10 flex items-center gap-4">
          <div class="h-px flex-1 bg-border/60"></div>
          <span class="text-xs font-medium uppercase tracking-widest text-muted-foreground">
            Completed
          </span>
          <div class="h-px flex-1 bg-border/60"></div>
        </div>

        <%!-- Completed challenges --%>
        <div class="flex flex-col gap-6 md:grid md:grid-cols-3">
          <.challenge_card
            image="/images/challenges/golem/og.png"
            href={~p"/challenges/golem"}
            status={:completed}
          />
          <.challenge_card
            image="/images/challenges/tsperf/og.png"
            href={~p"/challenges/tsperf"}
            status={:completed}
          />
          <.challenge_card
            image="/images/challenges/prettier/og.png"
            href={~p"/challenges/prettier"}
            status={:completed}
          />
        </div>
      </main>

      <div class="bg-black mt-12 md:mt-28">
        <Footer.footer class="pt-12 md:pt-28" />
      </div>
    </div>
    """
  end

  defp challenge_card(assigns) do
    ~H"""
    <div class="group relative flex-1">
      <.link
        class={[
          "relative flex aspect-[1200/630] w-full rounded-2xl border border-border bg-cover overflow-hidden transition-all duration-300 hover:no-underline",
          if(@status == :active,
            do: "hover:border-white/40 hover:shadow-lg hover:shadow-black/20",
            else:
              "opacity-50 grayscale group-hover:opacity-100 group-hover:grayscale-0 group-hover:border-white/40"
          )
        ]}
        style={"background-image:url(#{@image})"}
        navigate={@href}
      >
        <%= if @status == :active do %>
          <div class="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300">
          </div>
          <div class="absolute bottom-3 right-3 flex items-center gap-1.5 rounded-full bg-black/60 backdrop-blur-sm px-2.5 py-1 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
            <span class="text-xs font-semibold text-white">View challenge</span>
            <.icon name="tabler-arrow-right" class="size-3 text-white" />
          </div>
        <% end %>
      </.link>
      <%= if @status == :completed do %>
        <div class="absolute top-3 right-3 z-10 flex items-center gap-1.5 rounded-full bg-emerald-950/50 group-hover:bg-emerald-950/70 transition-colors ring-1 ring-emerald-500/40 backdrop-blur-sm px-2.5 py-1 pointer-events-none">
          <.icon name="tabler-check" class="size-3 text-emerald-400" />
          <span class="text-xs font-semibold text-emerald-400">Rewarded</span>
        </div>
      <% end %>
    </div>
    """
  end
end
