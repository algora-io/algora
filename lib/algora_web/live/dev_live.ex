defmodule AlgoraWeb.DevLive do
  use AlgoraWeb, :live_view


  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Orders",

     )}
  end

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen w-full flex-col bg-muted/40" data-phx-id="m1-phx-GAPTpMFHc9kS4XZh">
      <aside class="fixed inset-y-0 left-0 z-10 hidden w-14 flex-col border-r bg-background sm:flex">
        <nav class="flex flex-col items-center gap-4 px-2 sm:py-5">
          <a href="#" class="group flex h-9 w-9 shrink-0 items-center justify-center gap-2 rounded-full bg-primary text-lg font-semibold text-primary-foreground md:h-8 md:w-8 md:text-base" data-phx-id="m2-phx-GAPTpMFHc9kS4XZh">
            <svg class="h-4 w-4 transition-all group-hover:scale-110" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="m7.5 4.27 9 5.15"></path>
              <path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"></path>
              <path d="m3.3 7 8.7 5 8.7-5"></path>
              <path d="M12 22V12"></path>
            </svg>
            <span class="sr-only"> Acme Inc </span>
          </a>
          <div class="relative inline-block group/tooltip" data-phx-id="m3-phx-GAPTpMFHc9kS4XZh">
            <tooltip_trigger>
              <a href="#" class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground md:h-8 md:w-8" data-phx-id="m4-phx-GAPTpMFHc9kS4XZh">
                <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
                  <polyline points="9 22 9 12 15 12 15 22"></polyline>
                </svg>
                <span class="sr-only"> Dashboard </span>
              </a>
            </tooltip_trigger>
            <div data-side="right" class="absolute hidden px-3 py-1.5 ml-2 rounded-md bg-popover text-popover-foreground whitespace-nowrap overflow-hidden shadow-md z-50 left-full top-1/2 text-sm w-auto -translate-y-1/2 animate-in border data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 fade-in-0 group-hover/tooltip:block slide-in-from-top-1/2 tooltip-content zoom-in-95" data-phx-id="m5-phx-GAPTpMFHc9kS4XZh"> Dashboard </div>
          </div>
          <div class="relative inline-block group/tooltip" data-phx-id="m6-phx-GAPTpMFHc9kS4XZh">
            <tooltip_trigger>
              <a href="#" class="flex h-9 w-9 items-center justify-center rounded-lg bg-accent text-accent-foreground transition-colors hover:text-foreground md:h-8 md:w-8" data-phx-id="m7-phx-GAPTpMFHc9kS4XZh">
                <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <circle cx="8" cy="21" r="1"></circle>
                  <circle cx="19" cy="21" r="1"></circle>
                  <path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12"></path>
                </svg>
                <span class="sr-only"> Orders </span>
              </a>
            </tooltip_trigger>
            <div data-side="right" class="absolute hidden px-3 py-1.5 ml-2 rounded-md bg-popover text-popover-foreground whitespace-nowrap overflow-hidden shadow-md z-50 left-full top-1/2 text-sm w-auto -translate-y-1/2 animate-in border data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 fade-in-0 group-hover/tooltip:block slide-in-from-top-1/2 tooltip-content zoom-in-95" data-phx-id="m8-phx-GAPTpMFHc9kS4XZh"> Orders </div>
          </div>
          <div class="relative inline-block group/tooltip" data-phx-id="m9-phx-GAPTpMFHc9kS4XZh">
            <tooltip_trigger>
              <a href="#" class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground md:h-8 md:w-8" data-phx-id="m10-phx-GAPTpMFHc9kS4XZh">
                <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="m7.5 4.27 9 5.15"></path>
                  <path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"></path>
                  <path d="m3.3 7 8.7 5 8.7-5"></path>
                  <path d="M12 22V12"></path>
                </svg>
                <span class="sr-only"> Products </span>
              </a>
            </tooltip_trigger>
            <div data-side="right" class="absolute hidden px-3 py-1.5 ml-2 rounded-md bg-popover text-popover-foreground whitespace-nowrap overflow-hidden shadow-md z-50 left-full top-1/2 text-sm w-auto -translate-y-1/2 animate-in border data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 fade-in-0 group-hover/tooltip:block slide-in-from-top-1/2 tooltip-content zoom-in-95" data-phx-id="m11-phx-GAPTpMFHc9kS4XZh"> Products </div>
          </div>
          <div class="relative inline-block group/tooltip" data-phx-id="m12-phx-GAPTpMFHc9kS4XZh">
            <tooltip_trigger>
              <a href="#" class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground md:h-8 md:w-8" data-phx-id="m13-phx-GAPTpMFHc9kS4XZh">
                <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path>
                  <circle cx="9" cy="7" r="4"></circle>
                  <path d="M22 21v-2a4 4 0 0 0-3-3.87"></path>
                  <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                </svg>
                <span class="sr-only"> Customers </span>
              </a>
            </tooltip_trigger>
            <div data-side="right" class="absolute hidden px-3 py-1.5 ml-2 rounded-md bg-popover text-popover-foreground whitespace-nowrap overflow-hidden shadow-md z-50 left-full top-1/2 text-sm w-auto -translate-y-1/2 animate-in border data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 fade-in-0 group-hover/tooltip:block slide-in-from-top-1/2 tooltip-content zoom-in-95" data-phx-id="m14-phx-GAPTpMFHc9kS4XZh"> Customers </div>
          </div>
          <div class="relative inline-block group/tooltip" data-phx-id="m15-phx-GAPTpMFHc9kS4XZh">
            <tooltip_trigger>
              <a href="#" class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground md:h-8 md:w-8" data-phx-id="m16-phx-GAPTpMFHc9kS4XZh">
                <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M3 3v18h18"></path>
                  <path d="m19 9-5 5-4-4-3 3"></path>
                </svg>
                <span class="sr-only"> Analytics </span>
              </a>
            </tooltip_trigger>
            <div data-side="right" class="absolute hidden px-3 py-1.5 ml-2 rounded-md bg-popover text-popover-foreground whitespace-nowrap overflow-hidden shadow-md z-50 left-full top-1/2 text-sm w-auto -translate-y-1/2 animate-in border data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 fade-in-0 group-hover/tooltip:block slide-in-from-top-1/2 tooltip-content zoom-in-95" data-phx-id="m17-phx-GAPTpMFHc9kS4XZh"> Analytics </div>
          </div>
        </nav>
        <nav class="mt-auto flex flex-col items-center gap-4 px-2 sm:py-5">
          <div class="relative inline-block group/tooltip" data-phx-id="m18-phx-GAPTpMFHc9kS4XZh">
            <tooltip_trigger>
              <a href="#" class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground md:h-8 md:w-8" data-phx-id="m19-phx-GAPTpMFHc9kS4XZh">
                <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"></path>
                  <circle cx="12" cy="12" r="3"></circle>
                </svg>
                <span class="sr-only"> Settings </span>
              </a>
            </tooltip_trigger>
            <div data-side="right" class="absolute hidden px-3 py-1.5 ml-2 rounded-md bg-popover text-popover-foreground whitespace-nowrap overflow-hidden shadow-md z-50 left-full top-1/2 text-sm w-auto -translate-y-1/2 animate-in border data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 fade-in-0 group-hover/tooltip:block slide-in-from-top-1/2 tooltip-content zoom-in-95" data-phx-id="m20-phx-GAPTpMFHc9kS4XZh"> Settings </div>
          </div>
        </nav>
      </aside>
      <div class="flex flex-col sm:gap-4 sm:py-4 sm:pl-14">
        <header class="sticky top-0 z-30 flex h-14 items-center gap-4 border-b bg-background px-4 sm:static sm:h-auto sm:border-0 sm:bg-transparent sm:px-6">
          <div class="inline-block" data-phx-id="m21-phx-GAPTpMFHc9kS4XZh">
            <div class="inner-block" phx-click="[[&quot;exec&quot;,{&quot;attr&quot;:&quot;phx-show-sheet&quot;,&quot;to&quot;:&quot;#side&quot;}]]" data-phx-id="m22-phx-GAPTpMFHc9kS4XZh">
              <button class="inline-flex rounded-md border-input bg-background transition-colors whitespace-nowrap items-center justify-center font-medium shadow-sm text-sm w-9 h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 sm:hidden disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground border" data-phx-id="m23-phx-GAPTpMFHc9kS4XZh">
                <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <rect width="18" height="18" x="3" y="3" rx="2"></rect>
                  <path d="M9 3v18"></path>
                </svg>
                <span class="sr-only"> Toggle Menu </span>
              </button>
            </div>
            <div class="sheet-content relative z-50" id="side" phx-show-sheet="[[&quot;show&quot;,{&quot;time&quot;:600,&quot;to&quot;:&quot;#side .sheet-overlay&quot;,&quot;transition&quot;:[[&quot;transition&quot;,&quot;ease-in-out&quot;],[&quot;opacity-0&quot;],[&quot;opacity-100&quot;]]}],[&quot;show&quot;,{&quot;time&quot;:600,&quot;to&quot;:&quot;#side .sheet-content-wrap&quot;,&quot;transition&quot;:[[&quot;transition&quot;,&quot;ease-in-out&quot;],[&quot;-translate-x-full&quot;],[&quot;translate-x-0&quot;]]}],[&quot;add_class&quot;,{&quot;names&quot;:[&quot;overflow-hidden&quot;],&quot;to&quot;:&quot;body&quot;}],[&quot;focus_first&quot;,{&quot;to&quot;:&quot;#side .sheet-content-wrap&quot;}]]" phx-hide-sheet="[[&quot;hide&quot;,{&quot;time&quot;:400,&quot;to&quot;:&quot;#side .sheet-overlay&quot;,&quot;transition&quot;:[[&quot;transition&quot;,&quot;ease-in-out&quot;],[&quot;opacity-100&quot;],[&quot;opacity-0&quot;]]}],[&quot;hide&quot;,{&quot;time&quot;:400,&quot;to&quot;:&quot;#side .sheet-content-wrap&quot;,&quot;transition&quot;:[[&quot;transition&quot;,&quot;ease-in-out&quot;],[&quot;translate-x-0&quot;],[&quot;-translate-x-full&quot;]]}],[&quot;remove_class&quot;,{&quot;names&quot;:[&quot;overflow-hidden&quot;],&quot;to&quot;:&quot;body&quot;}],[&quot;pop_focus&quot;,{}]]" data-phx-id="m24-phx-GAPTpMFHc9kS4XZh">
              <div class="fixed hidden bg-black/80 z-50 inset-0 sheet-overlay" aria-hidden="true" data-phx-id="m25-phx-GAPTpMFHc9kS4XZh"></div>
              <div id="sheet-side" phx-hook="Phoenix.FocusWrap" class="fixed hidden bg-background transition shadow-lg z-50 left-0 inset-y-0 w-3/4 h-full sm:max-w-xs border-r sheet-content-wrap" role="sheet" phx-click-away="[[&quot;exec&quot;,{&quot;attr&quot;:&quot;phx-hide-sheet&quot;,&quot;to&quot;:&quot;#side&quot;}]]" phx-key="escape" phx-window-keydown="[[&quot;exec&quot;,{&quot;attr&quot;:&quot;phx-hide-sheet&quot;,&quot;to&quot;:&quot;#side&quot;}]]" data-phx-id="m26-phx-GAPTpMFHc9kS4XZh">
                <span id="sheet-side-start" tabindex="0" aria-hidden="true"></span>
                <div class="relative h-full">
                  <div class="p-6 overflow-y-auto h-full sm:max-w-xs">
                    <nav class="grid gap-6 text-lg font-medium">
                      <a href="#" class="group flex h-10 w-10 shrink-0 items-center justify-center gap-2 rounded-full bg-primary text-lg font-semibold text-primary-foreground md:text-base" data-phx-id="m27-phx-GAPTpMFHc9kS4XZh">
                        <svg class="h-5 w-5 transition-all group-hover:scale-110" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                          <path d="m7.5 4.27 9 5.15"></path>
                          <path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"></path>
                          <path d="m3.3 7 8.7 5 8.7-5"></path>
                          <path d="M12 22V12"></path>
                        </svg>
                        <span class="sr-only"> Acme Inc </span>
                      </a>
                      <a href="#" class="flex items-center gap-4 px-2.5 text-muted-foreground hover:text-foreground" data-phx-id="m28-phx-GAPTpMFHc9kS4XZh">
                        <home class="h-5 w-5"></home> Dashboard
                      </a>
                      <a href="#" class="flex items-center gap-4 px-2.5 text-foreground" data-phx-id="m29-phx-GAPTpMFHc9kS4XZh">
                        <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                          <circle cx="8" cy="21" r="1"></circle>
                          <circle cx="19" cy="21" r="1"></circle>
                          <path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12"></path>
                        </svg> Orders </a>
                      <a href="#" class="flex items-center gap-4 px-2.5 text-muted-foreground hover:text-foreground" data-phx-id="m30-phx-GAPTpMFHc9kS4XZh">
                        <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                          <path d="m7.5 4.27 9 5.15"></path>
                          <path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"></path>
                          <path d="m3.3 7 8.7 5 8.7-5"></path>
                          <path d="M12 22V12"></path>
                        </svg> Products </a>
                      <a href="#" class="flex items-center gap-4 px-2.5 text-muted-foreground hover:text-foreground" data-phx-id="m31-phx-GAPTpMFHc9kS4XZh">
                        <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                          <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path>
                          <circle cx="9" cy="7" r="4"></circle>
                          <path d="M22 21v-2a4 4 0 0 0-3-3.87"></path>
                          <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                        </svg> Customers </a>
                      <a href="#" class="flex items-center gap-4 px-2.5 text-muted-foreground hover:text-foreground" data-phx-id="m32-phx-GAPTpMFHc9kS4XZh">
                        <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                          <path d="M3 3v18h18"></path>
                          <path d="m19 9-5 5-4-4-3 3"></path>
                        </svg> Settings </a>
                    </nav>
                  </div>
                  <button type="button" class="ring-offset-background absolute top-4 right-4 rounded-sm opacity-70 transition-opacity hover:opacity-100 focus:ring-ring focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:pointer-events-none" phx-click="[[&quot;hide&quot;,{&quot;time&quot;:400,&quot;to&quot;:&quot;#side .sheet-overlay&quot;,&quot;transition&quot;:[[&quot;transition&quot;,&quot;ease-in-out&quot;],[&quot;opacity-100&quot;],[&quot;opacity-0&quot;]]}],[&quot;hide&quot;,{&quot;time&quot;:400,&quot;to&quot;:&quot;#side .sheet-content-wrap&quot;,&quot;transition&quot;:[[&quot;transition&quot;,&quot;ease-in-out&quot;],[&quot;translate-x-0&quot;],[&quot;-translate-x-full&quot;]]}],[&quot;remove_class&quot;,{&quot;names&quot;:[&quot;overflow-hidden&quot;],&quot;to&quot;:&quot;body&quot;}],[&quot;pop_focus&quot;,{}]]">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6 no-collapse h-4 w-4">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12"></path>
                    </svg>
                    <span class="sr-only">Close</span>
                  </button>
                </div>
                <span id="sheet-side-end" tabindex="0" aria-hidden="true"></span>
              </div>
            </div>
          </div>
          <nav arial-label="breadcrumb" class="hidden text-muted-foreground break-words items-center flex-wrap gap-1.5 text-sm sm:gap-2.5 md:flex" }="" data-phx-id="m33-phx-GAPTpMFHc9kS4XZh">
            <ol class="flex text-muted-foreground break-words items-center flex-wrap gap-1.5 text-sm sm:gap-2.5" }="" data-phx-id="m34-phx-GAPTpMFHc9kS4XZh">
              <li class="inline-flex items-center gap-1.5" data-phx-id="m35-phx-GAPTpMFHc9kS4XZh">
                <a href="#" class="transition-colors hover:text-foreground" data-phx-id="m36-phx-GAPTpMFHc9kS4XZh"></a>
                <a href="#" data-phx-id="m37-phx-GAPTpMFHc9kS4XZh"> Dashboard </a>
              </li>
              <li role="presentation" aria-hidden="true" class="[&amp;>svg]:size-3.5" data-phx-id="m38-phx-GAPTpMFHc9kS4XZh">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="size-6 w-3">
                  <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5"></path>
                </svg>
              </li>
              <li class="inline-flex items-center gap-1.5" data-phx-id="m39-phx-GAPTpMFHc9kS4XZh">
                <a href="#" class="transition-colors hover:text-foreground" data-phx-id="m40-phx-GAPTpMFHc9kS4XZh"></a>
                <a href="#" data-phx-id="m41-phx-GAPTpMFHc9kS4XZh"> Orders </a>
              </li>
              <li role="presentation" aria-hidden="true" class="[&amp;>svg]:size-3.5" data-phx-id="m42-phx-GAPTpMFHc9kS4XZh">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="size-6 w-3">
                  <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5"></path>
                </svg>
              </li>
              <li class="inline-flex items-center gap-1.5" data-phx-id="m43-phx-GAPTpMFHc9kS4XZh">
                <span aria-disabled="true" aria-current="page" role="link" class="text-foreground font-normal" data-phx-id="m44-phx-GAPTpMFHc9kS4XZh"> Recent Orders </span>
              </li>
            </ol>
          </nav>
          <div class="relative ml-auto flex-1 md:grow-0">
            <svg class="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <circle cx="11" cy="11" r="8"></circle>
              <path d="m21 21-4.3-4.3"></path>
            </svg>
            <input class="flex pl-8 px-3 py-2 rounded-lg ring-offset-background border-input bg-background text-sm w-full h-10 lg:w-[336px] md:w-[200px] placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-50 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 file:border-0 file:bg-transparent file:font-medium file:text-sm border" type="text" placeholder="Search..." data-phx-id="m45-phx-GAPTpMFHc9kS4XZh">
          </div>
          <div class="relative inline-block group" data-phx-id="m46-phx-GAPTpMFHc9kS4XZh">
            <div class="dropdown-menu-trigger peer" data-state="closed" phx-click="[[&quot;toggle_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;open&quot;,&quot;closed&quot;]}]]" phx-click-away="[[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;closed&quot;]}]]" data-phx-id="m47-phx-GAPTpMFHc9kS4XZh">
              <button class="inline-flex rounded-full border-input bg-background transition-colors whitespace-nowrap items-center justify-center overflow-hidden font-medium shadow-sm text-sm w-9 h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground border" data-phx-id="m48-phx-GAPTpMFHc9kS4XZh">
                <img src="/images/avatar02-e904d5847af14af9cad1ad5c92151406.png?vsn=d" width="36" height="36" alt="Avatar" class="overflow-hidden rounded-full">
              </button>
            </div>
            <div class="z-50 animate-in peer-data-[state=closed]:fade-out-0 peer-data-[state=open]:fade-in-0 peer-data-[state=closed]:zoom-out-95 peer-data-[state=open]:zoom-in-95 peer-data-[side=bottom]:slide-in-from-top-2 peer-data-[side=left]:slide-in-from-right-2 peer-data-[side=right]:slide-in-from-left-2 peer-data-[side=top]:slide-in-from-bottom-2 absolute peer-data-[state=closed]:hidden top-full mt-2 right-0" data-phx-id="m49-phx-GAPTpMFHc9kS4XZh">
              <div class="">
                <div class="min-w-[8rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-md top-0 left-full" data-phx-id="m50-phx-GAPTpMFHc9kS4XZh">
                  <div class="px-2 py-1.5 font-semibold text-sm false" data-phx-id="m51-phx-GAPTpMFHc9kS4XZh"> My Account </div>
                  <div role="separator" class="-mx-1 my-1 bg-muted h-px" data-phx-id="m52-phx-GAPTpMFHc9kS4XZh"></div>
                  <div class="relative flex px-2 py-1.5 rounded-sm select-none cursor-default transition-colors outline-none items-center text-sm hover:bg-accent focus:bg-accent focus:text-accent-foreground data-[disabled]:opacity-50 data-[disabled]:pointer-events-none" data-phx-id="m53-phx-GAPTpMFHc9kS4XZh"> Settings </div>
                  <div class="relative flex px-2 py-1.5 rounded-sm select-none cursor-default transition-colors outline-none items-center text-sm hover:bg-accent focus:bg-accent focus:text-accent-foreground data-[disabled]:opacity-50 data-[disabled]:pointer-events-none" data-phx-id="m54-phx-GAPTpMFHc9kS4XZh"> Support </div>
                  <div role="separator" class="-mx-1 my-1 bg-muted h-px" data-phx-id="m55-phx-GAPTpMFHc9kS4XZh"></div>
                  <div class="relative flex px-2 py-1.5 rounded-sm select-none cursor-default transition-colors outline-none items-center text-sm hover:bg-accent focus:bg-accent focus:text-accent-foreground data-[disabled]:opacity-50 data-[disabled]:pointer-events-none" data-phx-id="m56-phx-GAPTpMFHc9kS4XZh"> Logout </div>
                </div>
              </div>
            </div>
          </div>
        </header>
        <main class="grid flex-1 items-start gap-4 p-4 sm:px-6 sm:py-0 md:gap-8 lg:grid-cols-3 xl:grid-cols-3">
          <div class="grid auto-rows-max items-start gap-4 md:gap-8 lg:col-span-2">
            <div class="grid gap-4 sm:grid-cols-2 md:grid-cols-4 lg:grid-cols-2 xl:grid-cols-4">
              <div class="rounded-xl bg-card text-card-foreground shadow sm:col-span-2 border" data-phx-id="m57-phx-GAPTpMFHc9kS4XZh">
                <div class="flex p-6 pb-3 flex-col space-y-1.5" data-phx-id="m58-phx-GAPTpMFHc9kS4XZh">
                  <h3 class="tracking-tight font-semibold leading-none text-2xl" data-phx-id="m59-phx-GAPTpMFHc9kS4XZh"> Your Orders </h3>
                  <p class="text-muted-foreground leading-relaxed text-balance max-w-lg" data-phx-id="m60-phx-GAPTpMFHc9kS4XZh"> Introducing Our Dynamic Orders Dashboard for Seamless Management and Insightful Analysis. </p>
                </div>
                <div class="flex p-6 pt-0 items-center justify-between" data-phx-id="m61-phx-GAPTpMFHc9kS4XZh">
                  <button class="inline-flex px-4 py-2 rounded-md bg-primary text-primary-foreground transition-colors whitespace-nowrap items-center justify-center font-medium shadow text-sm h-9 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 hover:bg-primary/90" data-phx-id="m62-phx-GAPTpMFHc9kS4XZh"> Create New Order </button>
                </div>
              </div>
              <div class="rounded-xl bg-card text-card-foreground shadow border" data-phx-id="m63-phx-GAPTpMFHc9kS4XZh">
                <div class="flex p-6 pb-2 flex-col space-y-1.5" data-phx-id="m64-phx-GAPTpMFHc9kS4XZh">
                  <p class="text-muted-foreground text-sm" data-phx-id="m65-phx-GAPTpMFHc9kS4XZh"> This Week </p>
                  <h3 class="tracking-tight font-semibold leading-none text-4xl" data-phx-id="m66-phx-GAPTpMFHc9kS4XZh"> $1,329 </h3>
                </div>
                <div class="p-6 pt-0" data-phx-id="m67-phx-GAPTpMFHc9kS4XZh">
                  <div class="text-xs text-muted-foreground"> +25% from last week </div>
                </div>
                <div class="flex p-6 pt-0 items-center justify-between" data-phx-id="m68-phx-GAPTpMFHc9kS4XZh">
                  <div class="relative rounded-full bg-secondary overflow-hidden w-full h-4" aria-label="25% increase" data-phx-id="m69-phx-GAPTpMFHc9kS4XZh">
                    <div class="h-full w-full flex-1 bg-primary transition-all" style="transform: translateX(-75%)"></div>
                  </div>
                </div>
              </div>
              <div class="rounded-xl bg-card text-card-foreground shadow border" data-phx-id="m70-phx-GAPTpMFHc9kS4XZh">
                <div class="flex p-6 pb-2 flex-col space-y-1.5" data-phx-id="m71-phx-GAPTpMFHc9kS4XZh">
                  <p class="text-muted-foreground text-sm" data-phx-id="m72-phx-GAPTpMFHc9kS4XZh"> This Month </p>
                  <h3 class="tracking-tight font-semibold leading-none text-4xl" data-phx-id="m73-phx-GAPTpMFHc9kS4XZh"> $5,329 </h3>
                </div>
                <div class="p-6 pt-0" data-phx-id="m74-phx-GAPTpMFHc9kS4XZh">
                  <div class="text-xs text-muted-foreground"> +10% from last month </div>
                </div>
                <div class="flex p-6 pt-0 items-center justify-between" data-phx-id="m75-phx-GAPTpMFHc9kS4XZh">
                  <div class="relative rounded-full bg-secondary overflow-hidden w-full h-4" aria-label="12% increase" data-phx-id="m76-phx-GAPTpMFHc9kS4XZh">
                    <div class="h-full w-full flex-1 bg-primary transition-all" style="transform: translateX(-88%)"></div>
                  </div>
                </div>
              </div>
            </div>
            <div class="" id="tabs" phx-mounted="[[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;&quot;],&quot;to&quot;:&quot;#tabs .tabs-trigger[data-state=active]&quot;}],[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;active&quot;],&quot;to&quot;:&quot;#tabs .tabs-trigger[data-target=week]&quot;}],[&quot;hide&quot;,{&quot;to&quot;:&quot;#tabs .tabs-content:not([value=week])&quot;}],[&quot;show&quot;,{&quot;to&quot;:&quot;#tabs .tabs-content[value=week]&quot;}]]" data-phx-id="m77-phx-GAPTpMFHc9kS4XZh">
              <div class="flex items-center">
                <div class="inline-flex p-1 rounded-md bg-muted text-muted-foreground items-center justify-center h-10" data-phx-id="m78-phx-GAPTpMFHc9kS4XZh">
                  <button class="inline-flex px-3 py-1.5 rounded-sm ring-offset-background transition-all whitespace-nowrap items-center justify-center font-medium text-sm disabled:pointer-events-none disabled:opacity-50 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 data-[state=active]:bg-background data-[state=active]:shadow-sm data-[state=active]:text-foreground tabs-trigger" data-target="week" phx-click="[[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;&quot;],&quot;to&quot;:&quot;#tabs .tabs-trigger[data-state=active]&quot;}],[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;active&quot;],&quot;to&quot;:&quot;#tabs .tabs-trigger[data-target=week]&quot;}],[&quot;hide&quot;,{&quot;to&quot;:&quot;#tabs .tabs-content:not([value=week])&quot;}],[&quot;show&quot;,{&quot;to&quot;:&quot;#tabs .tabs-content[value=week]&quot;}]]" data-phx-id="m79-phx-GAPTpMFHc9kS4XZh" data-state="active"> Week </button>
                  <button class="inline-flex px-3 py-1.5 rounded-sm ring-offset-background transition-all whitespace-nowrap items-center justify-center font-medium text-sm disabled:pointer-events-none disabled:opacity-50 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 data-[state=active]:bg-background data-[state=active]:shadow-sm data-[state=active]:text-foreground tabs-trigger" data-target="month" phx-click="[[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;&quot;],&quot;to&quot;:&quot;#tabs .tabs-trigger[data-state=active]&quot;}],[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;active&quot;],&quot;to&quot;:&quot;#tabs .tabs-trigger[data-target=month]&quot;}],[&quot;hide&quot;,{&quot;to&quot;:&quot;#tabs .tabs-content:not([value=month])&quot;}],[&quot;show&quot;,{&quot;to&quot;:&quot;#tabs .tabs-content[value=month]&quot;}]]" data-phx-id="m80-phx-GAPTpMFHc9kS4XZh"> Month </button>
                  <button class="inline-flex px-3 py-1.5 rounded-sm ring-offset-background transition-all whitespace-nowrap items-center justify-center font-medium text-sm disabled:pointer-events-none disabled:opacity-50 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 data-[state=active]:bg-background data-[state=active]:shadow-sm data-[state=active]:text-foreground tabs-trigger" data-target="year" phx-click="[[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;&quot;],&quot;to&quot;:&quot;#tabs .tabs-trigger[data-state=active]&quot;}],[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;active&quot;],&quot;to&quot;:&quot;#tabs .tabs-trigger[data-target=year]&quot;}],[&quot;hide&quot;,{&quot;to&quot;:&quot;#tabs .tabs-content:not([value=year])&quot;}],[&quot;show&quot;,{&quot;to&quot;:&quot;#tabs .tabs-content[value=year]&quot;}]]" data-phx-id="m81-phx-GAPTpMFHc9kS4XZh"> Year </button>
                </div>
                <div class="ml-auto flex items-center gap-2">
                  <div class="relative inline-block group" data-phx-id="m82-phx-GAPTpMFHc9kS4XZh">
                    <div class="dropdown-menu-trigger peer" data-state="closed" phx-click="[[&quot;toggle_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;open&quot;,&quot;closed&quot;]}]]" phx-click-away="[[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;closed&quot;]}]]" data-phx-id="m83-phx-GAPTpMFHc9kS4XZh">
                      <button class="inline-flex px-3 rounded-md border-input bg-background transition-colors whitespace-nowrap items-center justify-center font-medium shadow-sm gap-1 text-sm h-7 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground border" data-phx-id="m84-phx-GAPTpMFHc9kS4XZh">
                        <svg class="h-3.5 w-3.5" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                          <path d="M3 6h18"></path>
                          <path d="M7 12h10"></path>
                          <path d="M10 18h4"></path>
                        </svg>
                        <span class="sr-only sm:not-sr-only"> Filter </span>
                      </button>
                    </div>
                    <div class="z-50 animate-in peer-data-[state=closed]:fade-out-0 peer-data-[state=open]:fade-in-0 peer-data-[state=closed]:zoom-out-95 peer-data-[state=open]:zoom-in-95 peer-data-[side=bottom]:slide-in-from-top-2 peer-data-[side=left]:slide-in-from-right-2 peer-data-[side=right]:slide-in-from-left-2 peer-data-[side=top]:slide-in-from-bottom-2 absolute peer-data-[state=closed]:hidden top-full mt-2 right-0" data-phx-id="m85-phx-GAPTpMFHc9kS4XZh">
                      <div class="">
                        <div class="min-w-[8rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-md top-0 left-full" data-phx-id="m86-phx-GAPTpMFHc9kS4XZh">
                          <div class="px-2 py-1.5 font-semibold text-sm false" data-phx-id="m87-phx-GAPTpMFHc9kS4XZh"> Filter by </div>
                          <div role="separator" class="-mx-1 my-1 bg-muted h-px" data-phx-id="m88-phx-GAPTpMFHc9kS4XZh"></div>
                          <div class="relative flex px-2 py-1.5 rounded-sm select-none cursor-default transition-colors outline-none items-center text-sm hover:bg-accent focus:bg-accent focus:text-accent-foreground data-[disabled]:opacity-50 data-[disabled]:pointer-events-none" data-phx-id="m89-phx-GAPTpMFHc9kS4XZh"> Fulfilled </div>
                          <div class="relative flex px-2 py-1.5 rounded-sm select-none cursor-default transition-colors outline-none items-center text-sm hover:bg-accent focus:bg-accent focus:text-accent-foreground data-[disabled]:opacity-50 data-[disabled]:pointer-events-none" data-phx-id="m90-phx-GAPTpMFHc9kS4XZh"> Declined </div>
                          <div class="relative flex px-2 py-1.5 rounded-sm select-none cursor-default transition-colors outline-none items-center text-sm hover:bg-accent focus:bg-accent focus:text-accent-foreground data-[disabled]:opacity-50 data-[disabled]:pointer-events-none" data-phx-id="m91-phx-GAPTpMFHc9kS4XZh"> Refunded </div>
                        </div>
                      </div>
                    </div>
                  </div>
                  <button class="inline-flex px-3 rounded-md border-input bg-background transition-colors whitespace-nowrap items-center justify-center font-medium shadow-sm gap-1 text-sm h-7 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground border" data-phx-id="m92-phx-GAPTpMFHc9kS4XZh">
                    <svg class="h-3.5 w-3.5" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                      <path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"></path>
                      <path d="M14 2v4a2 2 0 0 0 2 2h4"></path>
                    </svg>
                    <span class="sr-only sm:not-sr-only"> Export </span>
                  </button>
                </div>
              </div>
              <div class="mt-2 ring-offset-background focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 tabs-content" value="week" data-phx-id="m93-phx-GAPTpMFHc9kS4XZh">
                <div class="rounded-xl bg-card text-card-foreground shadow border" data-phx-id="m94-phx-GAPTpMFHc9kS4XZh">
                  <div class="flex p-6 px-7 flex-col space-y-1.5" data-phx-id="m95-phx-GAPTpMFHc9kS4XZh">
                    <h3 class="tracking-tight font-semibold leading-none text-2xl" data-phx-id="m96-phx-GAPTpMFHc9kS4XZh"> Orders </h3>
                    <p class="text-muted-foreground text-sm" data-phx-id="m97-phx-GAPTpMFHc9kS4XZh"> Recent orders from your store. </p>
                  </div>
                  <div class="p-6 pt-0" data-phx-id="m98-phx-GAPTpMFHc9kS4XZh">
                    <table class="text-sm w-full caption-bottom" data-phx-id="m99-phx-GAPTpMFHc9kS4XZh">
                      <thead class="[&amp;_tr]:border-b" data-phx-id="m100-phx-GAPTpMFHc9kS4XZh">
                        <tr class="transition-colors hover:bg-muted/50 border-b data-[state=selected]:bg-muted" data-phx-id="m101-phx-GAPTpMFHc9kS4XZh">
                          <th class="px-4 text-muted-foreground text-left align-middle font-medium h-12 [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m102-phx-GAPTpMFHc9kS4XZh"> Customer </th>
                          <th class="hidden px-4 text-muted-foreground text-left align-middle font-medium h-12 sm:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m103-phx-GAPTpMFHc9kS4XZh"> Type </th>
                          <th class="hidden px-4 text-muted-foreground text-left align-middle font-medium h-12 sm:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m104-phx-GAPTpMFHc9kS4XZh"> Status </th>
                          <th class="hidden px-4 text-muted-foreground text-left align-middle font-medium h-12 md:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m105-phx-GAPTpMFHc9kS4XZh"> Date </th>
                          <th class="px-4 text-muted-foreground text-right align-middle font-medium h-12 [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m106-phx-GAPTpMFHc9kS4XZh"> Amount </th>
                        </tr>
                      </thead>
                      <tbody class="[&amp;_tr:last-child]:border-0" data-phx-id="m107-phx-GAPTpMFHc9kS4XZh">
                        <tr class="bg-accent transition-colors hover:bg-muted/50 border-b data-[state=selected]:bg-muted" data-phx-id="m108-phx-GAPTpMFHc9kS4XZh">
                          <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m109-phx-GAPTpMFHc9kS4XZh">
                            <div class="font-medium"> Liam Johnson </div>
                            <div class="hidden text-sm text-muted-foreground md:inline"> liam@example.com </div>
                          </td>
                          <td class="hidden p-4 align-middle sm:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m110-phx-GAPTpMFHc9kS4XZh"> Sale </td>
                          <td class="hidden p-4 align-middle sm:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m111-phx-GAPTpMFHc9kS4XZh">
                            <div class="inline-flex px-2.5 py-0.5 rounded-full border-transparent bg-secondary text-secondary-foreground transition-colors items-center font-semibold text-xs focus:ring-ring focus:outline-none focus:ring-2 focus:ring-offset-2 hover:bg-secondary/80 border" data-phx-id="m112-phx-GAPTpMFHc9kS4XZh"> Fulfilled </div>
                          </td>
                          <td class="hidden p-4 align-middle md:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m113-phx-GAPTpMFHc9kS4XZh"> 2023-06-23 </td>
                          <td class="p-4 text-right align-middle [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m114-phx-GAPTpMFHc9kS4XZh"> $250.00 </td>
                        </tr>
                        <tr class="transition-colors hover:bg-muted/50 border-b data-[state=selected]:bg-muted" data-phx-id="m115-phx-GAPTpMFHc9kS4XZh">
                          <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m116-phx-GAPTpMFHc9kS4XZh">
                            <div class="font-medium"> Olivia Smith </div>
                            <div class="hidden text-sm text-muted-foreground md:inline"> olivia@example.com </div>
                          </td>
                          <td class="hidden p-4 align-middle sm:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m117-phx-GAPTpMFHc9kS4XZh"> Refund </td>
                          <td class="hidden p-4 align-middle sm:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m118-phx-GAPTpMFHc9kS4XZh">
                            <div class="inline-flex px-2.5 py-0.5 rounded-full text-foreground transition-colors items-center font-semibold text-xs focus:ring-ring focus:outline-none focus:ring-2 focus:ring-offset-2 border" data-phx-id="m119-phx-GAPTpMFHc9kS4XZh"> Declined </div>
                          </td>
                          <td class="hidden p-4 align-middle md:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m120-phx-GAPTpMFHc9kS4XZh"> 2023-06-24 </td>
                          <td class="p-4 text-right align-middle [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m121-phx-GAPTpMFHc9kS4XZh"> $150.00 </td>
                        </tr>
                        <tr class="transition-colors hover:bg-muted/50 border-b data-[state=selected]:bg-muted" data-phx-id="m122-phx-GAPTpMFHc9kS4XZh">
                          <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m123-phx-GAPTpMFHc9kS4XZh">
                            <div class="font-medium"> Noah Williams </div>
                            <div class="hidden text-sm text-muted-foreground md:inline"> noah@example.com </div>
                          </td>
                          <td class="hidden p-4 align-middle sm:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m124-phx-GAPTpMFHc9kS4XZh"> Subscription </td>
                          <td class="hidden p-4 align-middle sm:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m125-phx-GAPTpMFHc9kS4XZh">
                            <div class="inline-flex px-2.5 py-0.5 rounded-full border-transparent bg-secondary text-secondary-foreground transition-colors items-center font-semibold text-xs focus:ring-ring focus:outline-none focus:ring-2 focus:ring-offset-2 hover:bg-secondary/80 border" data-phx-id="m126-phx-GAPTpMFHc9kS4XZh"> Fulfilled </div>
                          </td>
                          <td class="hidden p-4 align-middle md:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m127-phx-GAPTpMFHc9kS4XZh"> 2023-06-25 </td>
                          <td class="p-4 text-right align-middle [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m128-phx-GAPTpMFHc9kS4XZh"> $350.00 </td>
                        </tr>
                        <tr class="transition-colors hover:bg-muted/50 border-b data-[state=selected]:bg-muted" data-phx-id="m129-phx-GAPTpMFHc9kS4XZh">
                          <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m130-phx-GAPTpMFHc9kS4XZh">
                            <div class="font-medium"> Emma Brown </div>
                            <div class="hidden text-sm text-muted-foreground md:inline"> emma@example.com </div>
                          </td>
                          <td class="hidden p-4 align-middle sm:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m131-phx-GAPTpMFHc9kS4XZh"> Sale </td>
                          <td class="hidden p-4 align-middle sm:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m132-phx-GAPTpMFHc9kS4XZh">
                            <div class="inline-flex px-2.5 py-0.5 rounded-full border-transparent bg-secondary text-secondary-foreground transition-colors items-center font-semibold text-xs focus:ring-ring focus:outline-none focus:ring-2 focus:ring-offset-2 hover:bg-secondary/80 border" data-phx-id="m133-phx-GAPTpMFHc9kS4XZh"> Fulfilled </div>
                          </td>
                          <td class="hidden p-4 align-middle md:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m134-phx-GAPTpMFHc9kS4XZh"> 2023-06-26 </td>
                          <td class="p-4 text-right align-middle [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m135-phx-GAPTpMFHc9kS4XZh"> $450.00 </td>
                        </tr>
                        <tr class="transition-colors hover:bg-muted/50 border-b data-[state=selected]:bg-muted" data-phx-id="m136-phx-GAPTpMFHc9kS4XZh">
                          <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m137-phx-GAPTpMFHc9kS4XZh">
                            <div class="font-medium"> Liam Johnson </div>
                            <div class="hidden text-sm text-muted-foreground md:inline"> liam@example.com </div>
                          </td>
                          <td class="hidden p-4 align-middle sm:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m138-phx-GAPTpMFHc9kS4XZh"> Sale </td>
                          <td class="hidden p-4 align-middle sm:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m139-phx-GAPTpMFHc9kS4XZh">
                            <div class="inline-flex px-2.5 py-0.5 rounded-full border-transparent bg-secondary text-secondary-foreground transition-colors items-center font-semibold text-xs focus:ring-ring focus:outline-none focus:ring-2 focus:ring-offset-2 hover:bg-secondary/80 border" data-phx-id="m140-phx-GAPTpMFHc9kS4XZh"> Fulfilled </div>
                          </td>
                          <td class="hidden p-4 align-middle md:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m141-phx-GAPTpMFHc9kS4XZh"> 2023-06-23 </td>
                          <td class="p-4 text-right align-middle [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m142-phx-GAPTpMFHc9kS4XZh"> $250.00 </td>
                        </tr>
                        <tr class="transition-colors hover:bg-muted/50 border-b data-[state=selected]:bg-muted" data-phx-id="m143-phx-GAPTpMFHc9kS4XZh">
                          <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m144-phx-GAPTpMFHc9kS4XZh">
                            <div class="font-medium"> Liam Johnson </div>
                            <div class="hidden text-sm text-muted-foreground md:inline"> liam@example.com </div>
                          </td>
                          <td class="hidden p-4 align-middle sm:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m145-phx-GAPTpMFHc9kS4XZh"> Sale </td>
                          <td class="hidden p-4 align-middle sm:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m146-phx-GAPTpMFHc9kS4XZh">
                            <div class="inline-flex px-2.5 py-0.5 rounded-full border-transparent bg-secondary text-secondary-foreground transition-colors items-center font-semibold text-xs focus:ring-ring focus:outline-none focus:ring-2 focus:ring-offset-2 hover:bg-secondary/80 border" data-phx-id="m147-phx-GAPTpMFHc9kS4XZh"> Fulfilled </div>
                          </td>
                          <td class="hidden p-4 align-middle md:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m148-phx-GAPTpMFHc9kS4XZh"> 2023-06-23 </td>
                          <td class="p-4 text-right align-middle [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m149-phx-GAPTpMFHc9kS4XZh"> $250.00 </td>
                        </tr>
                        <tr class="transition-colors hover:bg-muted/50 border-b data-[state=selected]:bg-muted" data-phx-id="m150-phx-GAPTpMFHc9kS4XZh">
                          <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m151-phx-GAPTpMFHc9kS4XZh">
                            <div class="font-medium"> Olivia Smith </div>
                            <div class="hidden text-sm text-muted-foreground md:inline"> olivia@example.com </div>
                          </td>
                          <td class="hidden p-4 align-middle sm:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m152-phx-GAPTpMFHc9kS4XZh"> Refund </td>
                          <td class="hidden p-4 align-middle sm:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m153-phx-GAPTpMFHc9kS4XZh">
                            <div class="inline-flex px-2.5 py-0.5 rounded-full text-foreground transition-colors items-center font-semibold text-xs focus:ring-ring focus:outline-none focus:ring-2 focus:ring-offset-2 border" data-phx-id="m154-phx-GAPTpMFHc9kS4XZh"> Declined </div>
                          </td>
                          <td class="hidden p-4 align-middle md:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m155-phx-GAPTpMFHc9kS4XZh"> 2023-06-24 </td>
                          <td class="p-4 text-right align-middle [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m156-phx-GAPTpMFHc9kS4XZh"> $150.00 </td>
                        </tr>
                        <tr class="transition-colors hover:bg-muted/50 border-b data-[state=selected]:bg-muted" data-phx-id="m157-phx-GAPTpMFHc9kS4XZh">
                          <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m158-phx-GAPTpMFHc9kS4XZh">
                            <div class="font-medium"> Emma Brown </div>
                            <div class="hidden text-sm text-muted-foreground md:inline"> emma@example.com </div>
                          </td>
                          <td class="hidden p-4 align-middle sm:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m159-phx-GAPTpMFHc9kS4XZh"> Sale </td>
                          <td class="hidden p-4 align-middle sm:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m160-phx-GAPTpMFHc9kS4XZh">
                            <div class="inline-flex px-2.5 py-0.5 rounded-full border-transparent bg-secondary text-secondary-foreground transition-colors items-center font-semibold text-xs focus:ring-ring focus:outline-none focus:ring-2 focus:ring-offset-2 hover:bg-secondary/80 border" data-phx-id="m161-phx-GAPTpMFHc9kS4XZh"> Fulfilled </div>
                          </td>
                          <td class="hidden p-4 align-middle md:table-cell [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m162-phx-GAPTpMFHc9kS4XZh"> 2023-06-26 </td>
                          <td class="p-4 text-right align-middle [&amp;:has([role=checkbox])]:pr-0" data-phx-id="m163-phx-GAPTpMFHc9kS4XZh"> $450.00 </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div>
            <div class="rounded-xl bg-card text-card-foreground overflow-hidden shadow border" data-phx-id="m164-phx-GAPTpMFHc9kS4XZh">
              <div class="flex p-6 bg-muted/50 items-start flex-row space-y-1.5" data-phx-id="m165-phx-GAPTpMFHc9kS4XZh">
                <div class="grid gap-0.5">
                  <h3 class="flex tracking-tight items-center font-semibold leading-none gap-2 text-lg group" data-phx-id="m166-phx-GAPTpMFHc9kS4XZh"> Order Oe31b70H <button class="inline-flex rounded-md border-input bg-background transition-opacity whitespace-nowrap items-center justify-center font-medium shadow-sm text-sm w-6 h-6 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground border group-hover:opacity-100 opacity-0" data-phx-id="m167-phx-GAPTpMFHc9kS4XZh">
                      <copy class="h-3 w-3"></copy>
                      <span class="sr-only"> Copy Order ID </span>
                    </button>
                  </h3>
                  <p class="text-muted-foreground text-sm" data-phx-id="m168-phx-GAPTpMFHc9kS4XZh"> Date: November 23, 2023 </p>
                </div>
                <div class="ml-auto flex items-center gap-1">
                  <button class="inline-flex px-3 rounded-md border-input bg-background transition-colors whitespace-nowrap items-center justify-center font-medium shadow-sm gap-1 text-xs h-8 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground border" data-phx-id="m169-phx-GAPTpMFHc9kS4XZh">
                    <svg class="h-3.5 w-3.5" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                      <path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2"></path>
                      <path d="M15 18H9"></path>
                      <path d="M19 18h2a1 1 0 0 0 1-1v-3.65a1 1 0 0 0-.22-.624l-3.48-4.35A1 1 0 0 0 17.52 8H14"></path>
                      <circle cx="17" cy="18" r="2"></circle>
                      <circle cx="7" cy="18" r="2"></circle>
                    </svg>
                    <span class="lg:sr-only xl:not-sr-only xl:whitespace-nowrap"> Track Order </span>
                  </button>
                  <div class="relative inline-block group" data-phx-id="m170-phx-GAPTpMFHc9kS4XZh">
                    <div class="dropdown-menu-trigger peer" data-state="closed" phx-click="[[&quot;toggle_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;open&quot;,&quot;closed&quot;]}]]" phx-click-away="[[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;closed&quot;]}]]" data-phx-id="m171-phx-GAPTpMFHc9kS4XZh">
                      <button class="inline-flex rounded-md border-input bg-background transition-colors whitespace-nowrap items-center justify-center font-medium shadow-sm text-sm w-8 h-8 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground border" data-phx-id="m172-phx-GAPTpMFHc9kS4XZh">
                        <svg class="h-3.5 w-3.5" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                          <circle cx="12" cy="12" r="1"></circle>
                          <circle cx="12" cy="5" r="1"></circle>
                          <circle cx="12" cy="19" r="1"></circle>
                        </svg>
                        <span class="sr-only"> More </span>
                      </button>
                    </div>
                    <div class="z-50 animate-in peer-data-[state=closed]:fade-out-0 peer-data-[state=open]:fade-in-0 peer-data-[state=closed]:zoom-out-95 peer-data-[state=open]:zoom-in-95 peer-data-[side=bottom]:slide-in-from-top-2 peer-data-[side=left]:slide-in-from-right-2 peer-data-[side=right]:slide-in-from-left-2 peer-data-[side=top]:slide-in-from-bottom-2 absolute peer-data-[state=closed]:hidden top-full mt-2 right-0" data-phx-id="m173-phx-GAPTpMFHc9kS4XZh">
                      <div class="">
                        <div class="min-w-[8rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-md top-0 left-full" data-phx-id="m174-phx-GAPTpMFHc9kS4XZh">
                          <div class="relative flex px-2 py-1.5 rounded-sm select-none cursor-default transition-colors outline-none items-center text-sm hover:bg-accent focus:bg-accent focus:text-accent-foreground data-[disabled]:opacity-50 data-[disabled]:pointer-events-none" data-phx-id="m175-phx-GAPTpMFHc9kS4XZh"> Edit </div>
                          <div class="relative flex px-2 py-1.5 rounded-sm select-none cursor-default transition-colors outline-none items-center text-sm hover:bg-accent focus:bg-accent focus:text-accent-foreground data-[disabled]:opacity-50 data-[disabled]:pointer-events-none" data-phx-id="m176-phx-GAPTpMFHc9kS4XZh"> Export </div>
                          <div role="separator" class="-mx-1 my-1 bg-muted h-px" data-phx-id="m177-phx-GAPTpMFHc9kS4XZh"></div>
                          <div class="relative flex px-2 py-1.5 rounded-sm select-none cursor-default transition-colors outline-none items-center text-sm hover:bg-accent focus:bg-accent focus:text-accent-foreground data-[disabled]:opacity-50 data-[disabled]:pointer-events-none" data-phx-id="m178-phx-GAPTpMFHc9kS4XZh"> Trash </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div class="p-6 text-sm" data-phx-id="m179-phx-GAPTpMFHc9kS4XZh">
                <div class="grid gap-3">
                  <div class="font-semibold"> Order Details </div>
                  <ul class="grid gap-3">
                    <li class="flex items-center justify-between">
                      <span class="text-muted-foreground"> Glimmer Lamps x <span> 2 </span>
                      </span>
                      <span> $250.00 </span>
                    </li>
                    <li class="flex items-center justify-between">
                      <span class="text-muted-foreground"> Aqua Filters x <span> 1 </span>
                      </span>
                      <span> $49.00 </span>
                    </li>
                  </ul>
                  <div class="my-2 bg-border shrink-0 w-full h-[1px]" data-phx-id="m180-phx-GAPTpMFHc9kS4XZh"></div>
                  <ul class="grid gap-3">
                    <li class="flex items-center justify-between">
                      <span class="text-muted-foreground"> Subtotal </span>
                      <span> $299.00 </span>
                    </li>
                    <li class="flex items-center justify-between">
                      <span class="text-muted-foreground"> Shipping </span>
                      <span> $5.00 </span>
                    </li>
                    <li class="flex items-center justify-between">
                      <span class="text-muted-foreground"> Tax </span>
                      <span> $25.00 </span>
                    </li>
                    <li class="flex items-center justify-between font-semibold">
                      <span class="text-muted-foreground"> Total </span>
                      <span> $329.00 </span>
                    </li>
                  </ul>
                </div>
                <div class="my-4 bg-border shrink-0 w-full h-[1px]" data-phx-id="m181-phx-GAPTpMFHc9kS4XZh"></div>
                <div class="grid grid-cols-2 gap-4">
                  <div class="grid gap-3">
                    <div class="font-semibold"> Shipping Information </div>
                    <address class="grid gap-0.5 not-italic text-muted-foreground">
                      <span> Liam Johnson </span>
                      <span> 1234 Main St. </span>
                      <span> Anytown, CA 12345 </span>
                    </address>
                  </div>
                  <div class="grid auto-rows-max gap-3">
                    <div class="font-semibold"> Billing Information </div>
                    <div class="text-muted-foreground"> Same as shipping address </div>
                  </div>
                </div>
                <div class="my-4 bg-border shrink-0 w-full h-[1px]" data-phx-id="m182-phx-GAPTpMFHc9kS4XZh"></div>
                <div class="grid gap-3">
                  <div class="font-semibold"> Customer Information </div>
                  <dl class="grid gap-3">
                    <div class="flex items-center justify-between">
                      <dt class="text-muted-foreground"> Customer </dt>
                      <dd> Liam Johnson </dd>
                    </div>
                    <div class="flex items-center justify-between">
                      <dt class="text-muted-foreground"> Email </dt>
                      <dd>
                        <a href="mailto:"> liam@acme.com </a>
                      </dd>
                    </div>
                    <div class="flex items-center justify-between">
                      <dt class="text-muted-foreground"> Phone </dt>
                      <dd>
                        <a href="tel:"> +1 234 567 890 </a>
                      </dd>
                    </div>
                  </dl>
                </div>
                <div class="my-4 bg-border shrink-0 w-full h-[1px]" data-phx-id="m183-phx-GAPTpMFHc9kS4XZh"></div>
                <div class="grid gap-3">
                  <div class="font-semibold"> Payment Information </div>
                  <dl class="grid gap-3">
                    <div class="flex items-center justify-between">
                      <dt class="flex items-center gap-1 text-muted-foreground">
                        <svg class="h-4 w-4" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                          <rect width="20" height="14" x="2" y="5" rx="2"></rect>
                          <line x1="2" x2="22" y1="10" y2="10"></line>
                        </svg> Visa
                      </dt>
                      <dd> **** **** **** 4532 </dd>
                    </div>
                  </dl>
                </div>
              </div>
              <div class="flex p-6 px-6 py-3 bg-muted/50 items-center justify-between flex-row border-t" data-phx-id="m184-phx-GAPTpMFHc9kS4XZh">
                <div class="text-xs text-muted-foreground"> Updated <time datetime="2023-11-23"> November 23, 2023 </time>
                </div>
                <nav arial-label="pagination" role="pagination" class="flex mr-0 justify-center w-auto ml-auto mx-auto" }="" data-phx-id="m185-phx-GAPTpMFHc9kS4XZh">
                  <ul class="flex items-center flex-row gap-1" }="" data-phx-id="m186-phx-GAPTpMFHc9kS4XZh">
                    <li class="" data-phx-id="m187-phx-GAPTpMFHc9kS4XZh">
                      <button class="inline-flex rounded-md border-input bg-background transition-colors whitespace-nowrap items-center justify-center font-medium shadow-sm text-sm w-6 h-6 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground border" data-phx-id="m188-phx-GAPTpMFHc9kS4XZh">
                        <svg class="h-3.5 w-3.5" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                          <path d="m15 18-6-6 6-6"></path>
                        </svg>
                        <span class="sr-only"> Previous Order </span>
                      </button>
                    </li>
                    <li class="" data-phx-id="m189-phx-GAPTpMFHc9kS4XZh">
                      <button class="inline-flex rounded-md border-input bg-background transition-colors whitespace-nowrap items-center justify-center font-medium shadow-sm text-sm w-6 h-6 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground border" data-phx-id="m190-phx-GAPTpMFHc9kS4XZh">
                        <svg class="h-3.5 w-3.5" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                          <path d="m9 18 6-6-6-6"></path>
                        </svg>
                        <span class="sr-only"> Next Order </span>
                      </button>
                    </li>
                  </ul>
                </nav>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
    """
  end
end
