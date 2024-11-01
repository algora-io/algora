defmodule AlgoraWeb.DevLive do
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Money
  alias Algora.Bounties

  def mount(_params, _session, socket) do
    project = %{
      title: "Build Real-time Chat Application",
      description: "Build a real-time chat application using Phoenix and LiveView.",
      tech_stack: ["Elixir", "Phoenix", "PostgreSQL", "TailwindCSS"],
      country: "US",
      hourly_rate: Decimal.new("50")
    }

    matching_devs =
      Accounts.list_matching_devs(
        limit: 5,
        country: project.country,
        skills: project.tech_stack
      )

    {:ok,
     assign(socket,
       page_title: "Project",
       project: project,
       matching_devs: matching_devs,
       bounties: Bounties.list_bounties(%{limit: 8})
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen w-full flex-col bg-muted/40" data-phx-id="m1-phx-GAPTpMFHc9kS4XZh">
      <aside class="fixed inset-y-0 left-0 z-10 hidden w-14 flex-col border-r bg-slate-950 sm:flex">
        <nav class="flex flex-col items-center gap-4 px-2 sm:py-5">
          <a
            href="#"
            class="group flex h-9 w-9 shrink-0 items-center justify-center gap-2 rounded-full bg-primary text-lg font-semibold text-primary-foreground md:h-8 md:w-8 md:text-base"
            data-phx-id="m2-phx-GAPTpMFHc9kS4XZh"
          >
            <img src={@current_org.avatar_url} alt={@current_org.name} class="w-8 h-8 rounded-full" />
          </a>
          <div class="relative inline-block group/tooltip" data-phx-id="m3-phx-GAPTpMFHc9kS4XZh">
            <tooltip_trigger>
              <a
                href="#"
                class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground md:h-8 md:w-8"
                data-phx-id="m4-phx-GAPTpMFHc9kS4XZh"
              >
                <svg
                  class="h-5 w-5"
                  xmlns="http://www.w3.org/2000/svg"
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
                  <polyline points="9 22 9 12 15 12 15 22"></polyline>
                </svg>
                <span class="sr-only"> Dashboard </span>
              </a>
            </tooltip_trigger>
            <div
              data-side="right"
              class="absolute hidden px-3 py-1.5 ml-2 rounded-md bg-popover text-popover-foreground whitespace-nowrap overflow-hidden shadow-md z-50 left-full top-1/2 text-sm w-auto -translate-y-1/2 animate-in border data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 fade-in-0 group-hover/tooltip:block slide-in-from-top-1/2 tooltip-content zoom-in-95"
              data-phx-id="m5-phx-GAPTpMFHc9kS4XZh"
            >
              Dashboard
            </div>
          </div>
          <div class="relative inline-block group/tooltip" data-phx-id="m6-phx-GAPTpMFHc9kS4XZh">
            <tooltip_trigger>
              <a
                href="#"
                class="flex h-9 w-9 items-center justify-center rounded-lg bg-accent text-accent-foreground transition-colors hover:text-foreground md:h-8 md:w-8"
                data-phx-id="m7-phx-GAPTpMFHc9kS4XZh"
              >
                <svg
                  class="h-5 w-5"
                  xmlns="http://www.w3.org/2000/svg"
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <circle cx="8" cy="21" r="1"></circle>
                  <circle cx="19" cy="21" r="1"></circle>
                  <path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12">
                  </path>
                </svg>
                <span class="sr-only"> Orders </span>
              </a>
            </tooltip_trigger>
            <div
              data-side="right"
              class="absolute hidden px-3 py-1.5 ml-2 rounded-md bg-popover text-popover-foreground whitespace-nowrap overflow-hidden shadow-md z-50 left-full top-1/2 text-sm w-auto -translate-y-1/2 animate-in border data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 fade-in-0 group-hover/tooltip:block slide-in-from-top-1/2 tooltip-content zoom-in-95"
              data-phx-id="m8-phx-GAPTpMFHc9kS4XZh"
            >
              Orders
            </div>
          </div>
          <div class="relative inline-block group/tooltip" data-phx-id="m9-phx-GAPTpMFHc9kS4XZh">
            <tooltip_trigger>
              <a
                href="#"
                class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground md:h-8 md:w-8"
                data-phx-id="m10-phx-GAPTpMFHc9kS4XZh"
              >
                <svg
                  class="h-5 w-5"
                  xmlns="http://www.w3.org/2000/svg"
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <path d="m7.5 4.27 9 5.15"></path>
                  <path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z">
                  </path>
                  <path d="m3.3 7 8.7 5 8.7-5"></path>
                  <path d="M12 22V12"></path>
                </svg>
                <span class="sr-only"> Products </span>
              </a>
            </tooltip_trigger>
            <div
              data-side="right"
              class="absolute hidden px-3 py-1.5 ml-2 rounded-md bg-popover text-popover-foreground whitespace-nowrap overflow-hidden shadow-md z-50 left-full top-1/2 text-sm w-auto -translate-y-1/2 animate-in border data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 fade-in-0 group-hover/tooltip:block slide-in-from-top-1/2 tooltip-content zoom-in-95"
              data-phx-id="m11-phx-GAPTpMFHc9kS4XZh"
            >
              Products
            </div>
          </div>
          <div class="relative inline-block group/tooltip" data-phx-id="m12-phx-GAPTpMFHc9kS4XZh">
            <tooltip_trigger>
              <a
                href="#"
                class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground md:h-8 md:w-8"
                data-phx-id="m13-phx-GAPTpMFHc9kS4XZh"
              >
                <svg
                  class="h-5 w-5"
                  xmlns="http://www.w3.org/2000/svg"
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path>
                  <circle cx="9" cy="7" r="4"></circle>
                  <path d="M22 21v-2a4 4 0 0 0-3-3.87"></path>
                  <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                </svg>
                <span class="sr-only"> Customers </span>
              </a>
            </tooltip_trigger>
            <div
              data-side="right"
              class="absolute hidden px-3 py-1.5 ml-2 rounded-md bg-popover text-popover-foreground whitespace-nowrap overflow-hidden shadow-md z-50 left-full top-1/2 text-sm w-auto -translate-y-1/2 animate-in border data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 fade-in-0 group-hover/tooltip:block slide-in-from-top-1/2 tooltip-content zoom-in-95"
              data-phx-id="m14-phx-GAPTpMFHc9kS4XZh"
            >
              Customers
            </div>
          </div>
          <div class="relative inline-block group/tooltip" data-phx-id="m15-phx-GAPTpMFHc9kS4XZh">
            <tooltip_trigger>
              <a
                href="#"
                class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground md:h-8 md:w-8"
                data-phx-id="m16-phx-GAPTpMFHc9kS4XZh"
              >
                <svg
                  class="h-5 w-5"
                  xmlns="http://www.w3.org/2000/svg"
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <path d="M3 3v18h18"></path>
                  <path d="m19 9-5 5-4-4-3 3"></path>
                </svg>
                <span class="sr-only"> Analytics </span>
              </a>
            </tooltip_trigger>
            <div
              data-side="right"
              class="absolute hidden px-3 py-1.5 ml-2 rounded-md bg-popover text-popover-foreground whitespace-nowrap overflow-hidden shadow-md z-50 left-full top-1/2 text-sm w-auto -translate-y-1/2 animate-in border data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 fade-in-0 group-hover/tooltip:block slide-in-from-top-1/2 tooltip-content zoom-in-95"
              data-phx-id="m17-phx-GAPTpMFHc9kS4XZh"
            >
              Analytics
            </div>
          </div>
        </nav>
        <nav class="mt-auto flex flex-col items-center gap-4 px-2 sm:py-5">
          <div class="relative inline-block group/tooltip" data-phx-id="m18-phx-GAPTpMFHc9kS4XZh">
            <tooltip_trigger>
              <a
                href="#"
                class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground md:h-8 md:w-8"
                data-phx-id="m19-phx-GAPTpMFHc9kS4XZh"
              >
                <svg
                  class="h-5 w-5"
                  xmlns="http://www.w3.org/2000/svg"
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z">
                  </path>
                  <circle cx="12" cy="12" r="3"></circle>
                </svg>
                <span class="sr-only"> Settings </span>
              </a>
            </tooltip_trigger>
            <div
              data-side="right"
              class="absolute hidden px-3 py-1.5 ml-2 rounded-md bg-popover text-popover-foreground whitespace-nowrap overflow-hidden shadow-md z-50 left-full top-1/2 text-sm w-auto -translate-y-1/2 animate-in border data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 fade-in-0 group-hover/tooltip:block slide-in-from-top-1/2 tooltip-content zoom-in-95"
              data-phx-id="m20-phx-GAPTpMFHc9kS4XZh"
            >
              Settings
            </div>
          </div>
        </nav>
      </aside>
      <div class="flex flex-col sm:gap-4 sm:py-4 sm:pl-14">
        <header class="sticky top-0 z-30 flex h-14 items-center gap-4 border-b bg-background px-4 sm:static sm:h-auto sm:border-0 sm:bg-transparent sm:px-6">
          <div class="inline-block" data-phx-id="m21-phx-GAPTpMFHc9kS4XZh">
            <div
              class="inner-block"
              phx-click="[[&quot;exec&quot;,{&quot;attr&quot;:&quot;phx-show-sheet&quot;,&quot;to&quot;:&quot;#side&quot;}]]"
              data-phx-id="m22-phx-GAPTpMFHc9kS4XZh"
            >
              <button
                class="inline-flex rounded-md border-input bg-background transition-colors whitespace-nowrap items-center justify-center font-medium shadow-sm text-sm w-9 h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 sm:hidden disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground border"
                data-phx-id="m23-phx-GAPTpMFHc9kS4XZh"
              >
                <svg
                  class="h-5 w-5"
                  xmlns="http://www.w3.org/2000/svg"
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <rect width="18" height="18" x="3" y="3" rx="2"></rect>
                  <path d="M9 3v18"></path>
                </svg>
                <span class="sr-only"> Toggle Menu </span>
              </button>
            </div>
            <div
              class="sheet-content relative z-50"
              id="side"
              phx-show-sheet="[[&quot;show&quot;,{&quot;time&quot;:600,&quot;to&quot;:&quot;#side .sheet-overlay&quot;,&quot;transition&quot;:[[&quot;transition&quot;,&quot;ease-in-out&quot;],[&quot;opacity-0&quot;],[&quot;opacity-100&quot;]]}],[&quot;show&quot;,{&quot;time&quot;:600,&quot;to&quot;:&quot;#side .sheet-content-wrap&quot;,&quot;transition&quot;:[[&quot;transition&quot;,&quot;ease-in-out&quot;],[&quot;-translate-x-full&quot;],[&quot;translate-x-0&quot;]]}],[&quot;add_class&quot;,{&quot;names&quot;:[&quot;overflow-hidden&quot;],&quot;to&quot;:&quot;body&quot;}],[&quot;focus_first&quot;,{&quot;to&quot;:&quot;#side .sheet-content-wrap&quot;}]]"
              phx-hide-sheet="[[&quot;hide&quot;,{&quot;time&quot;:400,&quot;to&quot;:&quot;#side .sheet-overlay&quot;,&quot;transition&quot;:[[&quot;transition&quot;,&quot;ease-in-out&quot;],[&quot;opacity-100&quot;],[&quot;opacity-0&quot;]]}],[&quot;hide&quot;,{&quot;time&quot;:400,&quot;to&quot;:&quot;#side .sheet-content-wrap&quot;,&quot;transition&quot;:[[&quot;transition&quot;,&quot;ease-in-out&quot;],[&quot;translate-x-0&quot;],[&quot;-translate-x-full&quot;]]}],[&quot;remove_class&quot;,{&quot;names&quot;:[&quot;overflow-hidden&quot;],&quot;to&quot;:&quot;body&quot;}],[&quot;pop_focus&quot;,{}]]"
              data-phx-id="m24-phx-GAPTpMFHc9kS4XZh"
            >
              <div
                class="fixed hidden bg-black/80 z-50 inset-0 sheet-overlay"
                aria-hidden="true"
                data-phx-id="m25-phx-GAPTpMFHc9kS4XZh"
              >
              </div>
              <div
                id="sheet-side"
                phx-hook="Phoenix.FocusWrap"
                class="fixed hidden bg-background transition shadow-lg z-50 left-0 inset-y-0 w-3/4 h-full sm:max-w-xs border-r sheet-content-wrap"
                role="sheet"
                phx-click-away="[[&quot;exec&quot;,{&quot;attr&quot;:&quot;phx-hide-sheet&quot;,&quot;to&quot;:&quot;#side&quot;}]]"
                phx-key="escape"
                phx-window-keydown="[[&quot;exec&quot;,{&quot;attr&quot;:&quot;phx-hide-sheet&quot;,&quot;to&quot;:&quot;#side&quot;}]]"
                data-phx-id="m26-phx-GAPTpMFHc9kS4XZh"
              >
                <span id="sheet-side-start" tabindex="0" aria-hidden="true"></span>
                <div class="relative h-full">
                  <div class="p-6 overflow-y-auto h-full sm:max-w-xs">
                    <nav class="grid gap-6 text-lg font-medium">
                      <a
                        href="#"
                        class="group flex h-10 w-10 shrink-0 items-center justify-center gap-2 rounded-full bg-primary text-lg font-semibold text-primary-foreground md:text-base"
                        data-phx-id="m27-phx-GAPTpMFHc9kS4XZh"
                      >
                        <svg
                          class="h-5 w-5 transition-all group-hover:scale-110"
                          xmlns="http://www.w3.org/2000/svg"
                          width="24"
                          height="24"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                        >
                          <path d="m7.5 4.27 9 5.15"></path>
                          <path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z">
                          </path>
                          <path d="m3.3 7 8.7 5 8.7-5"></path>
                          <path d="M12 22V12"></path>
                        </svg>
                        <span class="sr-only"> Acme Inc </span>
                      </a>
                      <a
                        href="#"
                        class="flex items-center gap-4 px-2.5 text-muted-foreground hover:text-foreground"
                        data-phx-id="m28-phx-GAPTpMFHc9kS4XZh"
                      >
                        <home class="h-5 w-5"></home>
                        Dashboard
                      </a>
                      <a
                        href="#"
                        class="flex items-center gap-4 px-2.5 text-foreground"
                        data-phx-id="m29-phx-GAPTpMFHc9kS4XZh"
                      >
                        <svg
                          class="h-5 w-5"
                          xmlns="http://www.w3.org/2000/svg"
                          width="24"
                          height="24"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                        >
                          <circle cx="8" cy="21" r="1"></circle>
                          <circle cx="19" cy="21" r="1"></circle>
                          <path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12">
                          </path>
                        </svg>
                        Orders
                      </a>
                      <a
                        href="#"
                        class="flex items-center gap-4 px-2.5 text-muted-foreground hover:text-foreground"
                        data-phx-id="m30-phx-GAPTpMFHc9kS4XZh"
                      >
                        <svg
                          class="h-5 w-5"
                          xmlns="http://www.w3.org/2000/svg"
                          width="24"
                          height="24"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                        >
                          <path d="m7.5 4.27 9 5.15"></path>
                          <path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z">
                          </path>
                          <path d="m3.3 7 8.7 5 8.7-5"></path>
                          <path d="M12 22V12"></path>
                        </svg>
                        Products
                      </a>
                      <a
                        href="#"
                        class="flex items-center gap-4 px-2.5 text-muted-foreground hover:text-foreground"
                        data-phx-id="m31-phx-GAPTpMFHc9kS4XZh"
                      >
                        <svg
                          class="h-5 w-5"
                          xmlns="http://www.w3.org/2000/svg"
                          width="24"
                          height="24"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                        >
                          <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path>
                          <circle cx="9" cy="7" r="4"></circle>
                          <path d="M22 21v-2a4 4 0 0 0-3-3.87"></path>
                          <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                        </svg>
                        Customers
                      </a>
                      <a
                        href="#"
                        class="flex items-center gap-4 px-2.5 text-muted-foreground hover:text-foreground"
                        data-phx-id="m32-phx-GAPTpMFHc9kS4XZh"
                      >
                        <svg
                          class="h-5 w-5"
                          xmlns="http://www.w3.org/2000/svg"
                          width="24"
                          height="24"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                        >
                          <path d="M3 3v18h18"></path>
                          <path d="m19 9-5 5-4-4-3 3"></path>
                        </svg>
                        Settings
                      </a>
                    </nav>
                  </div>
                  <button
                    type="button"
                    class="ring-offset-background absolute top-4 right-4 rounded-sm opacity-70 transition-opacity hover:opacity-100 focus:ring-ring focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:pointer-events-none"
                    phx-click="[[&quot;hide&quot;,{&quot;time&quot;:400,&quot;to&quot;:&quot;#side .sheet-overlay&quot;,&quot;transition&quot;:[[&quot;transition&quot;,&quot;ease-in-out&quot;],[&quot;opacity-100&quot;],[&quot;opacity-0&quot;]]}],[&quot;hide&quot;,{&quot;time&quot;:400,&quot;to&quot;:&quot;#side .sheet-content-wrap&quot;,&quot;transition&quot;:[[&quot;transition&quot;,&quot;ease-in-out&quot;],[&quot;translate-x-0&quot;],[&quot;-translate-x-full&quot;]]}],[&quot;remove_class&quot;,{&quot;names&quot;:[&quot;overflow-hidden&quot;],&quot;to&quot;:&quot;body&quot;}],[&quot;pop_focus&quot;,{}]]"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      class="size-6 no-collapse h-4 w-4"
                    >
                      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12">
                      </path>
                    </svg>
                    <span class="sr-only">Close</span>
                  </button>
                </div>
                <span id="sheet-side-end" tabindex="0" aria-hidden="true"></span>
              </div>
            </div>
          </div>
          <nav
            arial-label="breadcrumb"
            class="hidden text-muted-foreground break-words items-center flex-wrap gap-1.5 text-sm sm:gap-2.5 md:flex"
            }=""
            data-phx-id="m33-phx-GAPTpMFHc9kS4XZh"
          >
            <ol
              class="flex text-muted-foreground break-words items-center flex-wrap gap-1.5 text-sm sm:gap-2.5"
              }=""
              data-phx-id="m34-phx-GAPTpMFHc9kS4XZh"
            >
              <li class="inline-flex items-center gap-1.5" data-phx-id="m35-phx-GAPTpMFHc9kS4XZh">
                <a
                  href="#"
                  class="transition-colors hover:text-foreground"
                  data-phx-id="m36-phx-GAPTpMFHc9kS4XZh"
                >
                </a>
                <a href="#" data-phx-id="m37-phx-GAPTpMFHc9kS4XZh"><%= @current_org.name %></a>
              </li>
              <li
                role="presentation"
                aria-hidden="true"
                class="[&amp;>svg]:size-3.5"
                data-phx-id="m38-phx-GAPTpMFHc9kS4XZh"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="2"
                  stroke="currentColor"
                  class="size-6 w-3"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5">
                  </path>
                </svg>
              </li>
              <li class="inline-flex items-center gap-1.5" data-phx-id="m39-phx-GAPTpMFHc9kS4XZh">
                <a
                  href="#"
                  class="transition-colors hover:text-foreground"
                  data-phx-id="m40-phx-GAPTpMFHc9kS4XZh"
                >
                </a>
                <a href="#" data-phx-id="m41-phx-GAPTpMFHc9kS4XZh"> Projects </a>
              </li>
              <li
                role="presentation"
                aria-hidden="true"
                class="[&amp;>svg]:size-3.5"
                data-phx-id="m42-phx-GAPTpMFHc9kS4XZh"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="2"
                  stroke="currentColor"
                  class="size-6 w-3"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5">
                  </path>
                </svg>
              </li>
              <li class="inline-flex items-center gap-1.5" data-phx-id="m43-phx-GAPTpMFHc9kS4XZh">
                <span
                  aria-disabled="true"
                  aria-current="page"
                  role="link"
                  class="text-foreground font-normal"
                  data-phx-id="m44-phx-GAPTpMFHc9kS4XZh"
                >
                  <%= @project.title %>
                </span>
              </li>
            </ol>
          </nav>
          <div class="relative ml-auto flex-1 md:grow-0">
            <svg
              class="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground"
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <circle cx="11" cy="11" r="8"></circle>
              <path d="m21 21-4.3-4.3"></path>
            </svg>
            <input
              class="flex pl-8 px-3 py-2 rounded-lg ring-offset-background border-input bg-background text-sm w-full h-10 lg:w-[336px] md:w-[200px] placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-50 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 file:border-0 file:bg-transparent file:font-medium file:text-sm border"
              type="text"
              placeholder="Search..."
              data-phx-id="m45-phx-GAPTpMFHc9kS4XZh"
            />
          </div>
          <div class="relative inline-block group" data-phx-id="m46-phx-GAPTpMFHc9kS4XZh">
            <div
              class="dropdown-menu-trigger peer"
              data-state="closed"
              phx-click="[[&quot;toggle_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;open&quot;,&quot;closed&quot;]}]]"
              phx-click-away="[[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;closed&quot;]}]]"
              data-phx-id="m47-phx-GAPTpMFHc9kS4XZh"
            >
              <button
                class="inline-flex rounded-full border-input bg-background transition-colors whitespace-nowrap items-center justify-center overflow-hidden font-medium shadow-sm text-sm w-9 h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground border"
                data-phx-id="m48-phx-GAPTpMFHc9kS4XZh"
              >
                <%= if @current_user do %>
                  <img
                    src={@current_user.avatar_url}
                    width="36"
                    height="36"
                    alt="Avatar"
                    class="overflow-hidden rounded-full"
                  />
                <% else %>
                  <.icon name="tabler-user" class="w-6 h-6" />
                <% end %>
              </button>
            </div>
            <div
              class="z-50 animate-in peer-data-[state=closed]:fade-out-0 peer-data-[state=open]:fade-in-0 peer-data-[state=closed]:zoom-out-95 peer-data-[state=open]:zoom-in-95 peer-data-[side=bottom]:slide-in-from-top-2 peer-data-[side=left]:slide-in-from-right-2 peer-data-[side=right]:slide-in-from-left-2 peer-data-[side=top]:slide-in-from-bottom-2 absolute peer-data-[state=closed]:hidden top-full mt-2 right-0"
              data-phx-id="m49-phx-GAPTpMFHc9kS4XZh"
            >
              <div class="">
                <div
                  class="min-w-[8rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-md top-0 left-full"
                  data-phx-id="m50-phx-GAPTpMFHc9kS4XZh"
                >
                  <div
                    class="px-2 py-1.5 font-semibold text-sm false"
                    data-phx-id="m51-phx-GAPTpMFHc9kS4XZh"
                  >
                    My Account
                  </div>
                  <div
                    role="separator"
                    class="-mx-1 my-1 bg-muted h-px"
                    data-phx-id="m52-phx-GAPTpMFHc9kS4XZh"
                  >
                  </div>
                  <div
                    class="relative flex px-2 py-1.5 rounded-sm select-none cursor-default transition-colors outline-none items-center text-sm hover:bg-accent focus:bg-accent focus:text-accent-foreground data-[disabled]:opacity-50 data-[disabled]:pointer-events-none"
                    data-phx-id="m53-phx-GAPTpMFHc9kS4XZh"
                  >
                    Settings
                  </div>
                  <div
                    class="relative flex px-2 py-1.5 rounded-sm select-none cursor-default transition-colors outline-none items-center text-sm hover:bg-accent focus:bg-accent focus:text-accent-foreground data-[disabled]:opacity-50 data-[disabled]:pointer-events-none"
                    data-phx-id="m54-phx-GAPTpMFHc9kS4XZh"
                  >
                    Support
                  </div>
                  <div
                    role="separator"
                    class="-mx-1 my-1 bg-muted h-px"
                    data-phx-id="m55-phx-GAPTpMFHc9kS4XZh"
                  >
                  </div>
                  <div
                    class="relative flex px-2 py-1.5 rounded-sm select-none cursor-default transition-colors outline-none items-center text-sm hover:bg-accent focus:bg-accent focus:text-accent-foreground data-[disabled]:opacity-50 data-[disabled]:pointer-events-none"
                    data-phx-id="m56-phx-GAPTpMFHc9kS4XZh"
                  >
                    Logout
                  </div>
                </div>
              </div>
            </div>
          </div>
        </header>
        <main class="grid flex-1 items-start gap-4 p-4 sm:px-6 sm:py-0 md:gap-8 lg:grid-cols-3 xl:grid-cols-3">
          <div class="grid auto-rows-max items-start gap-4 md:gap-8 lg:col-span-2">
            <div class="grid gap-4 sm:grid-cols-2">
              <div
                class="rounded-xl bg-card text-card-foreground shadow sm:col-span-2 border"
                data-phx-id="m57-phx-GAPTpMFHc9kS4XZh"
              >
                <div class="flex p-6 pb-3 flex-col space-y-1.5">
                  <div class="flex justify-between items-start gap-8">
                    <div class="flex-1">
                      <h3 class="tracking-tight font-semibold leading-none text-2xl mb-4">
                        <%= @project.title %>
                      </h3>

                      <div class="flex flex-wrap gap-2 mb-4">
                        <%= for tech <- @project.tech_stack do %>
                          <span class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 border-transparent bg-secondary text-secondary-foreground">
                            <%= tech %>
                          </span>
                        <% end %>
                      </div>

                      <div class="flex items-center gap-4 text-muted-foreground text-sm">
                        <div class="flex items-center gap-1">
                          <.icon name="tabler-clock" class="w-4 h-4" /> Posted March 15, 2024
                        </div>
                        <div class="flex items-center gap-1">
                          <.icon name="tabler-world" class="w-4 h-4" /> <%= @project.country %>
                        </div>
                      </div>
                    </div>
                    <div class="text-right">
                      <div class="text-primary font-semibold font-display text-3xl">
                        <%= Money.format!(@project.hourly_rate, "USD") %>/hour
                      </div>
                      <div class="text-sm text-muted-foreground">
                        Hourly Rate
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div
                class="rounded-xl bg-card text-card-foreground shadow border"
                data-phx-id="m63-phx-GAPTpMFHc9kS4XZh"
              >
                <div class="flex p-6 flex-col space-y-4">
                  <div class="flex items-center gap-3 text-muted-foreground">
                    <.icon name="tabler-file-description" class="w-5 h-5" />
                    <h3 class="font-medium">Project Description</h3>
                  </div>
                  <p class="text-sm text-muted-foreground">
                    Add details about requirements, timeline, and expectations.
                  </p>
                  <button class="inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-primary text-primary-foreground hover:bg-primary/90 h-10 px-4 py-2">
                    Add Description
                  </button>
                </div>
              </div>
              <div
                class="rounded-xl bg-card text-card-foreground shadow border"
                data-phx-id="m70-phx-GAPTpMFHc9kS4XZh"
              >
                <div class="flex p-6 flex-col space-y-4">
                  <div class="flex items-center gap-3 text-muted-foreground">
                    <.icon name="tabler-file-upload" class="w-5 h-5" />
                    <h3 class="font-medium">Documents</h3>
                  </div>
                  <p class="text-sm text-muted-foreground">
                    Upload NDA, IP agreements, and other legal documents.
                  </p>
                  <button class="inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-primary text-primary-foreground hover:bg-primary/90 h-10 px-4 py-2">
                    Upload Documents
                  </button>
                </div>
              </div>
            </div>
            <div
              class=""
              id="tabs"
              phx-mounted="[[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;&quot;],&quot;to&quot;:&quot;#tabs .tabs-trigger[data-state=active]&quot;}],[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;active&quot;],&quot;to&quot;:&quot;#tabs .tabs-trigger[data-target=week]&quot;}],[&quot;hide&quot;,{&quot;to&quot;:&quot;#tabs .tabs-content:not([value=week])&quot;}],[&quot;show&quot;,{&quot;to&quot;:&quot;#tabs .tabs-content[value=week]&quot;}]]"
              data-phx-id="m77-phx-GAPTpMFHc9kS4XZh"
            >
              <div class="flex items-center">
                <div
                  class="inline-flex p-1 rounded-md bg-muted text-muted-foreground items-center justify-center h-10"
                  data-phx-id="m78-phx-GAPTpMFHc9kS4XZh"
                >
                  <button
                    class="inline-flex px-3 py-1.5 rounded-sm ring-offset-background transition-all whitespace-nowrap items-center justify-center font-medium text-sm disabled:pointer-events-none disabled:opacity-50 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 data-[state=active]:bg-background data-[state=active]:shadow-sm data-[state=active]:text-foreground tabs-trigger"
                    data-target="week"
                    phx-click="[[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;&quot;],&quot;to&quot;:&quot;#tabs .tabs-trigger[data-state=active]&quot;}],[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;active&quot;],&quot;to&quot;:&quot;#tabs .tabs-trigger[data-target=week]&quot;}],[&quot;hide&quot;,{&quot;to&quot;:&quot;#tabs .tabs-content:not([value=week])&quot;}],[&quot;show&quot;,{&quot;to&quot;:&quot;#tabs .tabs-content[value=week]&quot;}]]"
                    data-phx-id="m79-phx-GAPTpMFHc9kS4XZh"
                    data-state="active"
                  >
                    Week
                  </button>
                  <button
                    class="inline-flex px-3 py-1.5 rounded-sm ring-offset-background transition-all whitespace-nowrap items-center justify-center font-medium text-sm disabled:pointer-events-none disabled:opacity-50 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 data-[state=active]:bg-background data-[state=active]:shadow-sm data-[state=active]:text-foreground tabs-trigger"
                    data-target="month"
                    phx-click="[[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;&quot;],&quot;to&quot;:&quot;#tabs .tabs-trigger[data-state=active]&quot;}],[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;active&quot;],&quot;to&quot;:&quot;#tabs .tabs-trigger[data-target=month]&quot;}],[&quot;hide&quot;,{&quot;to&quot;:&quot;#tabs .tabs-content:not([value=month])&quot;}],[&quot;show&quot;,{&quot;to&quot;:&quot;#tabs .tabs-content[value=month]&quot;}]]"
                    data-phx-id="m80-phx-GAPTpMFHc9kS4XZh"
                  >
                    Month
                  </button>
                  <button
                    class="inline-flex px-3 py-1.5 rounded-sm ring-offset-background transition-all whitespace-nowrap items-center justify-center font-medium text-sm disabled:pointer-events-none disabled:opacity-50 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 data-[state=active]:bg-background data-[state=active]:shadow-sm data-[state=active]:text-foreground tabs-trigger"
                    data-target="year"
                    phx-click="[[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;&quot;],&quot;to&quot;:&quot;#tabs .tabs-trigger[data-state=active]&quot;}],[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;active&quot;],&quot;to&quot;:&quot;#tabs .tabs-trigger[data-target=year]&quot;}],[&quot;hide&quot;,{&quot;to&quot;:&quot;#tabs .tabs-content:not([value=year])&quot;}],[&quot;show&quot;,{&quot;to&quot;:&quot;#tabs .tabs-content[value=year]&quot;}]]"
                    data-phx-id="m81-phx-GAPTpMFHc9kS4XZh"
                  >
                    Year
                  </button>
                </div>
                <div class="ml-auto flex items-center gap-2">
                  <div class="relative inline-block group" data-phx-id="m82-phx-GAPTpMFHc9kS4XZh">
                    <div
                      class="dropdown-menu-trigger peer"
                      data-state="closed"
                      phx-click="[[&quot;toggle_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;open&quot;,&quot;closed&quot;]}]]"
                      phx-click-away="[[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;closed&quot;]}]]"
                      data-phx-id="m83-phx-GAPTpMFHc9kS4XZh"
                    >
                      <button
                        class="inline-flex px-3 rounded-md border-input bg-background transition-colors whitespace-nowrap items-center justify-center font-medium shadow-sm gap-1 text-sm h-7 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground border"
                        data-phx-id="m84-phx-GAPTpMFHc9kS4XZh"
                      >
                        <svg
                          class="h-3.5 w-3.5"
                          xmlns="http://www.w3.org/2000/svg"
                          width="24"
                          height="24"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                        >
                          <path d="M3 6h18"></path>
                          <path d="M7 12h10"></path>
                          <path d="M10 18h4"></path>
                        </svg>
                        <span class="sr-only sm:not-sr-only"> Filter </span>
                      </button>
                    </div>
                    <div
                      class="z-50 animate-in peer-data-[state=closed]:fade-out-0 peer-data-[state=open]:fade-in-0 peer-data-[state=closed]:zoom-out-95 peer-data-[state=open]:zoom-in-95 peer-data-[side=bottom]:slide-in-from-top-2 peer-data-[side=left]:slide-in-from-right-2 peer-data-[side=right]:slide-in-from-left-2 peer-data-[side=top]:slide-in-from-bottom-2 absolute peer-data-[state=closed]:hidden top-full mt-2 right-0"
                      data-phx-id="m85-phx-GAPTpMFHc9kS4XZh"
                    >
                      <div class="">
                        <div
                          class="min-w-[8rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-md top-0 left-full"
                          data-phx-id="m86-phx-GAPTpMFHc9kS4XZh"
                        >
                          <div
                            class="relative flex px-2 py-1.5 rounded-sm select-none cursor-default transition-colors outline-none items-center text-sm hover:bg-accent focus:bg-accent focus:text-accent-foreground data-[disabled]:opacity-50 data-[disabled]:pointer-events-none"
                            data-phx-id="m89-phx-GAPTpMFHc9kS4XZh"
                          >
                            Fulfilled
                          </div>
                          <div
                            class="relative flex px-2 py-1.5 rounded-sm select-none cursor-default transition-colors outline-none items-center text-sm hover:bg-accent focus:bg-accent focus:text-accent-foreground data-[disabled]:opacity-50 data-[disabled]:pointer-events-none"
                            data-phx-id="m90-phx-GAPTpMFHc9kS4XZh"
                          >
                            Declined
                          </div>
                          <div
                            class="relative flex px-2 py-1.5 rounded-sm select-none cursor-default transition-colors outline-none items-center text-sm hover:bg-accent focus:bg-accent focus:text-accent-foreground data-[disabled]:opacity-50 data-[disabled]:pointer-events-none"
                            data-phx-id="m91-phx-GAPTpMFHc9kS4XZh"
                          >
                            Refunded
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                  <button
                    class="inline-flex px-3 rounded-md border-input bg-background transition-colors whitespace-nowrap items-center justify-center font-medium shadow-sm gap-1 text-sm h-7 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground border"
                    data-phx-id="m92-phx-GAPTpMFHc9kS4XZh"
                  >
                    <svg
                      class="h-3.5 w-3.5"
                      xmlns="http://www.w3.org/2000/svg"
                      width="24"
                      height="24"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                    >
                      <path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"></path>
                      <path d="M14 2v4a2 2 0 0 0 2 2h4"></path>
                    </svg>
                    <span class="sr-only sm:not-sr-only"> Export </span>
                  </button>
                </div>
              </div>
              <div
                class="mt-2 ring-offset-background focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 tabs-content"
                value="week"
                data-phx-id="m93-phx-GAPTpMFHc9kS4XZh"
              >
                <div
                  class="rounded-xl bg-card text-card-foreground shadow border"
                  data-phx-id="m94-phx-GAPTpMFHc9kS4XZh"
                >
                  <div
                    class="flex p-6 px-7 flex-col space-y-1.5"
                    data-phx-id="m95-phx-GAPTpMFHc9kS4XZh"
                  >
                    <h3
                      class="tracking-tight font-semibold leading-none text-2xl"
                      data-phx-id="m96-phx-GAPTpMFHc9kS4XZh"
                    >
                      Bounties
                    </h3>
                    <p class="text-muted-foreground text-sm" data-phx-id="m97-phx-GAPTpMFHc9kS4XZh">
                      Bounties linked to your project
                    </p>
                  </div>
                  <div class="p-6 pt-0" data-phx-id="m98-phx-GAPTpMFHc9kS4XZh">
                    <table
                      class="text-sm w-full caption-bottom"
                      data-phx-id="m99-phx-GAPTpMFHc9kS4XZh"
                    >
                      <thead class="[&_tr]:border-b">
                        <tr class="transition-colors hover:bg-muted/50 border-b data-[state=selected]:bg-muted">
                          <th class="px-4 text-muted-foreground text-left align-middle font-medium h-12">
                            Task
                          </th>
                          <th class="hidden px-4 text-muted-foreground text-left align-middle font-medium h-12 sm:table-cell">
                            Owner
                          </th>
                          <th class="hidden px-4 text-muted-foreground text-left align-middle font-medium h-12 sm:table-cell">
                            Tech Stack
                          </th>
                          <th class="hidden px-4 text-muted-foreground text-left align-middle font-medium h-12 md:table-cell">
                            Posted
                          </th>
                          <th class="px-4 text-muted-foreground text-right align-middle font-medium h-12">
                            Bounty
                          </th>
                        </tr>
                      </thead>
                      <tbody class="[&_tr:last-child]:border-0">
                        <%= for bounty <- @bounties do %>
                          <tr class="transition-colors hover:bg-muted/50 border-b data-[state=selected]:bg-muted">
                            <td class="p-4 align-middle">
                              <div class="font-medium"><%= bounty.task.title %></div>
                              <div class="hidden text-sm text-muted-foreground md:inline">
                                <%= bounty.task.owner %>/<%= bounty.task.repo %> #<%= bounty.task.number %>
                              </div>
                            </td>
                            <td class="hidden p-4 align-middle sm:table-cell">
                              <div class="flex items-center gap-2">
                                <img src={bounty.owner.avatar_url} class="h-6 w-6 rounded-full" />
                                <%= bounty.owner.name %>
                              </div>
                            </td>
                            <td class="hidden p-4 align-middle sm:table-cell">
                              <div class="flex flex-wrap gap-1">
                                <%= for tech <- bounty.tech_stack || [] do %>
                                  <div class="inline-flex px-2.5 py-0.5 rounded-full border-transparent bg-secondary text-secondary-foreground text-xs">
                                    <%= tech %>
                                  </div>
                                <% end %>
                              </div>
                            </td>
                            <td class="hidden p-4 align-middle md:table-cell">
                              <%= Calendar.strftime(bounty.inserted_at, "%Y-%m-%d") %>
                            </td>
                            <td class="p-4 text-right align-middle">
                              <%= Money.format!(bounty.amount, bounty.currency) %>
                            </td>
                          </tr>
                        <% end %>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="lg:col-span-1">
            <div class="rounded-xl bg-card text-card-foreground shadow border">
              <div class="p-6">
                <h2 class="tracking-tight font-semibold leading-none text-lg mb-4">
                  Matching Developers
                </h2>

                <%= if @matching_devs == [] do %>
                  <p class="text-muted-foreground">No matching developers found</p>
                <% else %>
                  <div class="space-y-4">
                    <%= for dev <- @matching_devs do %>
                      <div class="flex items-center gap-4 p-4 rounded-lg bg-accent/50">
                        <img src={dev.avatar_url} alt={dev.name} class="w-12 h-12 rounded-full" />
                        <div class="flex-grow min-w-0">
                          <div class="flex justify-between items-start gap-2">
                            <div class="truncate">
                              <div class="font-medium truncate">
                                <%= dev.name %> <%= dev.flag %>
                              </div>
                              <div class="text-sm text-muted-foreground truncate">
                                @<%= dev.handle %>
                              </div>
                            </div>
                            <div class="text-right shrink-0">
                              <div class="text-sm text-muted-foreground">Earned</div>
                              <div class="font-medium">
                                <%= Money.format!(dev.amount, "USD") %>
                              </div>
                            </div>
                          </div>

                          <div class="mt-2 flex flex-wrap gap-1">
                            <%= for skill <- dev.skills do %>
                              <span class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80">
                                <%= skill %>
                              </span>
                            <% end %>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
    """
  end
end
