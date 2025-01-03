defmodule AlgoraWeb.DevLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts.User

  def mount(_params, _session, socket) do
    project = %{
      title: "Looking for an Elixir developer to build a real-time chat application",
      description: "Build a real-time chat application using Phoenix and LiveView.",
      tech_stack: ["Elixir", "Phoenix", "PostgreSQL", "TailwindCSS"],
      country: socket.assigns.current_country
    }

    nav_items = [
      %{
        icon: "tabler-home",
        label: "Dashboard",
        href: "#",
        active: true
      },
      %{
        icon: "tabler-diamond",
        label: "Bountes",
        href: "#",
        active: false
      },
      %{
        icon: "tabler-file",
        label: "Documents",
        href: "#",
        active: false
      },
      %{
        icon: "tabler-users",
        label: "Team",
        href: "#",
        active: false
      }
    ]

    footer_nav_items = [
      %{
        icon: "tabler-settings",
        label: "Settings",
        href: "#"
      }
    ]

    user_menu_items = [
      %{label: "My Account", href: "#", divider: true},
      %{label: "Settings", href: "#"},
      %{label: "Support", href: "#", divider: true},
      %{label: "Logout", href: "#"}
    ]

    filter_menu_items = [
      %{label: "Fulfilled", href: "#"},
      %{label: "Declined", href: "#"},
      %{label: "Refunded", href: "#"}
    ]

    time_periods = [
      %{label: "Week", value: "week"},
      %{label: "Month", value: "month"},
      %{label: "Year", value: "year"}
    ]

    # matching_devs =
    #   Accounts.list_developers(
    #     limit: 5,
    #     sort_by_country: project.country,
    #     sort_by_tech_stack: project.tech_stack
    #   )

    # bounties = Bounties.list_bounties(limit: 8)

    {:ok,
     assign(socket,
       page_title: "Project",
       project: project,
       nav_items: nav_items,
       footer_nav_items: footer_nav_items,
       user_menu_items: user_menu_items,
       filter_menu_items: filter_menu_items,
       time_periods: time_periods,
       active_period: "week",
       matching_devs: [],
       bounties: []
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen w-full flex-col bg-muted/10" data-phx-id="m1-phx-GAPTpMFHc9kS4XZh">
      <aside class="fixed inset-y-0 left-0 z-10 hidden w-14 flex-col border-r bg-gray-950 sm:flex">
        <nav class="flex flex-col items-center gap-4 px-2 sm:py-5">
          <a
            href="#"
            class="group flex h-9 w-9 shrink-0 items-center justify-center gap-2 rounded-full bg-primary text-lg font-semibold text-primary-foreground md:h-8 md:w-8 md:text-base"
            data-phx-id="m2-phx-GAPTpMFHc9kS4XZh"
          >
            <img src={@current_org.avatar_url} alt={@current_org.name} class="h-8 w-8 rounded-full" />
          </a>
          <%= for item <- @nav_items do %>
            <div class="group/tooltip relative inline-block">
              <tooltip_trigger>
                <a
                  href={item.href}
                  class={"#{if item.active, do: "bg-accent text-accent-foreground", else: "text-muted-foreground"} flex h-9 w-9 items-center justify-center rounded-lg transition-colors hover:text-foreground md:h-8 md:w-8"}
                >
                  <.icon name={item.icon} class="h-5 w-5" />
                  <span class="sr-only">{item.label}</span>
                </a>
              </tooltip_trigger>
              <div class="tooltip-content absolute top-1/2 left-full z-50 ml-2 hidden w-auto -translate-y-1/2 overflow-hidden whitespace-nowrap rounded-md border bg-popover px-3 py-1.5 text-sm text-popover-foreground shadow-md animate-in fade-in-0 zoom-in-95 slide-in-from-top-1/2 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 group-hover/tooltip:block">
                {item.label}
              </div>
            </div>
          <% end %>
        </nav>
        <nav class="mt-auto flex flex-col items-center gap-4 px-2 sm:py-5">
          <%= for item <- @footer_nav_items do %>
            <div class="group/tooltip relative inline-block">
              <tooltip_trigger>
                <a
                  href={item.href}
                  class="flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:text-foreground md:h-8 md:w-8"
                >
                  <.icon name={item.icon} class="h-5 w-5" />
                  <span class="sr-only">{item.label}</span>
                </a>
              </tooltip_trigger>
              <div class="tooltip-content absolute top-1/2 left-full z-50 ml-2 hidden w-auto -translate-y-1/2 overflow-hidden whitespace-nowrap rounded-md border bg-popover px-3 py-1.5 text-sm text-popover-foreground shadow-md animate-in fade-in-0 zoom-in-95 slide-in-from-top-1/2 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 group-hover/tooltip:block">
                {item.label}
              </div>
            </div>
          <% end %>
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
                class="inline-flex h-9 w-9 items-center justify-center whitespace-nowrap rounded-md border border-input bg-background text-sm font-medium shadow-sm transition-colors hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 sm:hidden"
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
                class="sheet-overlay fixed inset-0 z-50 hidden bg-black/80"
                aria-hidden="true"
                data-phx-id="m25-phx-GAPTpMFHc9kS4XZh"
              >
              </div>
              <div
                id="sheet-side"
                phx-hook="Phoenix.FocusWrap"
                class="sheet-content-wrap fixed inset-y-0 left-0 z-50 hidden h-full w-3/4 border-r bg-background shadow-lg transition sm:max-w-xs"
                role="sheet"
                phx-click-away="[[&quot;exec&quot;,{&quot;attr&quot;:&quot;phx-hide-sheet&quot;,&quot;to&quot;:&quot;#side&quot;}]]"
                phx-key="escape"
                phx-window-keydown="[[&quot;exec&quot;,{&quot;attr&quot;:&quot;phx-hide-sheet&quot;,&quot;to&quot;:&quot;#side&quot;}]]"
                data-phx-id="m26-phx-GAPTpMFHc9kS4XZh"
              >
                <span id="sheet-side-start" tabindex="0" aria-hidden="true"></span>
                <div class="relative h-full">
                  <div class="h-full overflow-y-auto p-6 sm:max-w-xs">
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
                    class="absolute top-4 right-4 rounded-sm opacity-70 ring-offset-background transition-opacity hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:pointer-events-none"
                    phx-click="[[&quot;hide&quot;,{&quot;time&quot;:400,&quot;to&quot;:&quot;#side .sheet-overlay&quot;,&quot;transition&quot;:[[&quot;transition&quot;,&quot;ease-in-out&quot;],[&quot;opacity-100&quot;],[&quot;opacity-0&quot;]]}],[&quot;hide&quot;,{&quot;time&quot;:400,&quot;to&quot;:&quot;#side .sheet-content-wrap&quot;,&quot;transition&quot;:[[&quot;transition&quot;,&quot;ease-in-out&quot;],[&quot;translate-x-0&quot;],[&quot;-translate-x-full&quot;]]}],[&quot;remove_class&quot;,{&quot;names&quot;:[&quot;overflow-hidden&quot;],&quot;to&quot;:&quot;body&quot;}],[&quot;pop_focus&quot;,{}]]"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="1.5"
                      stroke="currentColor"
                      class="no-collapse size-6 h-4 w-4"
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
            class="hidden flex-wrap items-center gap-1.5 break-words text-sm text-muted-foreground sm:gap-2.5 md:flex"
            }=""
            data-phx-id="m33-phx-GAPTpMFHc9kS4XZh"
          >
            <ol
              class="flex flex-wrap items-center gap-1.5 break-words text-sm text-muted-foreground sm:gap-2.5"
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
                <a href="#" data-phx-id="m37-phx-GAPTpMFHc9kS4XZh">{@current_org.name}</a>
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
                  class="font-normal text-foreground"
                  data-phx-id="m44-phx-GAPTpMFHc9kS4XZh"
                >
                  {@project.title}
                </span>
              </li>
            </ol>
          </nav>
          <div
            class="group relative ml-auto inline-block md:grow-0"
            data-phx-id="m46-phx-GAPTpMFHc9kS4XZh"
          >
            <div
              class="dropdown-menu-trigger peer"
              data-state="closed"
              phx-click="[[&quot;toggle_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;open&quot;,&quot;closed&quot;]}]]"
              phx-click-away="[[&quot;set_attr&quot;,{&quot;attr&quot;:[&quot;data-state&quot;,&quot;closed&quot;]}]]"
              data-phx-id="m47-phx-GAPTpMFHc9kS4XZh"
            >
              <button
                class="inline-flex h-9 w-9 items-center justify-center overflow-hidden whitespace-nowrap rounded-full border border-input bg-background text-sm font-medium shadow-sm transition-colors hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50"
                data-phx-id="m48-phx-GAPTpMFHc9kS4XZh"
              >
                <%= if @current_user && @current_user.avatar_url do %>
                  <img
                    src={@current_user.avatar_url}
                    width="36"
                    height="36"
                    alt={@current_user.name}
                    class="overflow-hidden rounded-full"
                  />
                <% else %>
                  <.icon name="tabler-user" class="h-6 w-6" />
                <% end %>
              </button>
            </div>
            <div
              class="absolute top-full right-0 z-50 mt-2 animate-in peer-data-[side=bottom]:slide-in-from-top-2 peer-data-[side=left]:slide-in-from-right-2 peer-data-[side=right]:slide-in-from-left-2 peer-data-[side=top]:slide-in-from-bottom-2 peer-data-[state=closed]:hidden peer-data-[state=closed]:fade-out-0 peer-data-[state=closed]:zoom-out-95 peer-data-[state=open]:fade-in-0 peer-data-[state=open]:zoom-in-95"
              data-phx-id="m49-phx-GAPTpMFHc9kS4XZh"
            >
              <div class="">
                <div
                  class="min-w-[8rem] top-0 left-full overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-md"
                  data-phx-id="m50-phx-GAPTpMFHc9kS4XZh"
                >
                  <div
                    class="false px-2 py-1.5 text-sm font-semibold"
                    data-phx-id="m51-phx-GAPTpMFHc9kS4XZh"
                  >
                    My Account
                  </div>
                  <div
                    role="separator"
                    class="-mx-1 my-1 h-px bg-muted"
                    data-phx-id="m52-phx-GAPTpMFHc9kS4XZh"
                  >
                  </div>
                  <%= for item <- @user_menu_items do %>
                    <%= if item[:divider] do %>
                      <div role="separator" class="-mx-1 my-1 h-px bg-muted"></div>
                    <% end %>
                    <div class="relative flex cursor-default select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none transition-colors data-[disabled]:pointer-events-none data-[disabled]:opacity-50 hover:bg-accent focus:bg-accent focus:text-accent-foreground">
                      {item.label}
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        </header>
        <main class="grid flex-1 items-start gap-4 p-4 sm:px-6 sm:py-0 lg:grid-cols-3 xl:grid-cols-3">
          <div class="grid auto-rows-max items-start gap-4 lg:col-span-2">
            <div class="grid gap-4 sm:grid-cols-2">
              <div
                class="rounded-xl border bg-card text-card-foreground shadow sm:col-span-2"
                data-phx-id="m57-phx-GAPTpMFHc9kS4XZh"
              >
                <div class="flex flex-col space-y-1.5 p-6 pb-3">
                  <div class="flex items-start justify-between gap-4">
                    <div class="flex-1">
                      <h3 class="mb-4 text-2xl font-semibold leading-none tracking-tight">
                        {@project.title}
                      </h3>

                      <div class="mb-4 flex flex-wrap gap-2">
                        <%= for tech <- @project.tech_stack do %>
                          <span class="inline-flex items-center rounded-full border border-transparent bg-secondary px-2.5 py-0.5 text-xs font-semibold text-secondary-foreground transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2">
                            {tech}
                          </span>
                        <% end %>
                      </div>

                      <div class="flex items-center gap-4 text-sm text-muted-foreground">
                        <div class="flex items-center gap-1">
                          <.icon name="tabler-clock" class="h-4 w-4" /> Posted March 15, 2024
                        </div>
                        <div class="flex items-center gap-1">
                          <.icon name="tabler-world" class="h-4 w-4" /> {@project.country}
                        </div>
                      </div>
                    </div>
                    <%= if @project[:hourly_rate] do %>
                      <div class="text-right">
                        <div class="font-display text-3xl font-semibold text-primary">
                          {Money.to_string!(@project.hourly_rate)}/hour
                        </div>
                        <div class="text-sm text-muted-foreground">
                          Hourly Rate
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
              <div
                class="rounded-xl border bg-card text-card-foreground shadow"
                data-phx-id="m63-phx-GAPTpMFHc9kS4XZh"
              >
                <div class="flex flex-col space-y-4 p-6">
                  <div class="flex items-center gap-3 text-muted-foreground">
                    <.icon name="tabler-file-description" class="h-5 w-5" />
                    <h3 class="font-medium">Project Description</h3>
                  </div>
                  <p class="text-sm text-muted-foreground">
                    Add details on requirements, timeline, and expectations.
                  </p>
                  <button class="inline-flex h-10 items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground ring-offset-background transition-colors hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50">
                    Add Description
                  </button>
                </div>
              </div>
              <div
                class="rounded-xl border bg-card text-card-foreground shadow"
                data-phx-id="m70-phx-GAPTpMFHc9kS4XZh"
              >
                <div class="flex flex-col space-y-4 p-6">
                  <div class="flex items-center gap-3 text-muted-foreground">
                    <.icon name="tabler-file-upload" class="h-5 w-5" />
                    <h3 class="font-medium">Documents</h3>
                  </div>
                  <p class="text-sm text-muted-foreground">
                    Upload NDA, IP agreements, and other legal documents.
                  </p>
                  <button class="inline-flex h-10 items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground ring-offset-background transition-colors hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50">
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
              <%!-- <div class="mb-2 flex items-center">
                <div
                  class="inline-flex p-1 rounded-md bg-muted text-muted-foreground items-center justify-center h-10"
                  data-phx-id="m78-phx-GAPTpMFHc9kS4XZh"
                >
                  <%= for period <- @time_periods do %>
                    <button
                      class="inline-flex px-3 py-1.5 rounded-sm ring-offset-background transition-all whitespace-nowrap items-center justify-center font-medium text-sm disabled:pointer-events-none disabled:opacity-50 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 data-[state=active]:bg-background data-[state=active]:shadow-sm data-[state=active]:text-foreground tabs-trigger"
                      data-target={period.value}
                      data-state={if @active_period == period.value, do: "active", else: ""}
                      phx-click="select_period"
                      phx-value-period={period.value}
                    >
                      <%= period.label %>
                    </button>
                  <% end %>
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
                        <.icon name="tabler-filter" class="h-3.5 w-3.5" />
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
                          <%= for item <- @filter_menu_items do %>
                            <div class="relative flex px-2 py-1.5 rounded-sm select-none cursor-default transition-colors outline-none items-center text-sm hover:bg-accent focus:bg-accent focus:text-accent-foreground data-[disabled]:opacity-50 data-[disabled]:pointer-events-none">
                              <%= item.label %>
                            </div>
                          <% end %>
                        </div>
                      </div>
                    </div>
                  </div>
                  <button
                    class="inline-flex px-3 rounded-md border-input bg-background transition-colors whitespace-nowrap items-center justify-center font-medium shadow-sm gap-1 text-sm h-7 focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground border"
                    data-phx-id="m92-phx-GAPTpMFHc9kS4XZh"
                  >
                    <.icon name="tabler-file-export" class="h-3.5 w-3.5" />
                    <span class="sr-only sm:not-sr-only"> Export </span>
                  </button>
                </div>
              </div> --%>
              <div
                class="tabs-content ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                value="week"
                data-phx-id="m93-phx-GAPTpMFHc9kS4XZh"
              >
                <div
                  class="rounded-xl border bg-card text-card-foreground shadow"
                  data-phx-id="m94-phx-GAPTpMFHc9kS4XZh"
                >
                  <div
                    class="flex flex-col space-y-1.5 p-6 px-7"
                    data-phx-id="m95-phx-GAPTpMFHc9kS4XZh"
                  >
                    <h3
                      class="text-2xl font-semibold leading-none tracking-tight"
                      data-phx-id="m96-phx-GAPTpMFHc9kS4XZh"
                    >
                      Bounties
                    </h3>
                    <p class="text-sm text-muted-foreground" data-phx-id="m97-phx-GAPTpMFHc9kS4XZh">
                      Bounties linked to your project
                    </p>
                  </div>
                  <div class="p-6 pt-0" data-phx-id="m98-phx-GAPTpMFHc9kS4XZh">
                    <table
                      class="w-full caption-bottom text-sm"
                      data-phx-id="m99-phx-GAPTpMFHc9kS4XZh"
                    >
                      <thead class="[&_tr]:border-b">
                        <tr class="border-b transition-colors data-[state=selected]:bg-muted hover:bg-muted/50">
                          <th class="h-12 px-4 text-left align-middle font-medium text-muted-foreground">
                            Ticket
                          </th>
                          <th class="hidden h-12 px-4 text-left align-middle font-medium text-muted-foreground sm:table-cell">
                            Owner
                          </th>
                          <th class="hidden h-12 px-4 text-left align-middle font-medium text-muted-foreground sm:table-cell">
                            Tech Stack
                          </th>
                          <th class="hidden h-12 px-4 text-left align-middle font-medium text-muted-foreground md:table-cell">
                            Posted
                          </th>
                          <th class="h-12 px-4 text-right align-middle font-medium text-muted-foreground">
                            Bounty
                          </th>
                        </tr>
                      </thead>
                      <tbody class="[&_tr:last-child]:border-0">
                        <%= if @bounties == [] do %>
                          <tr>
                            <td colspan="5" class="p-8">
                              <div class="flex flex-col items-center space-y-3 text-center">
                                <div class="rounded-full bg-primary/10 p-3">
                                  <.icon name="tabler-plus" class="h-6 w-6 text-primary" />
                                </div>
                                <h3 class="text-lg font-semibold">No Bounties Yet</h3>
                                <p class="max-w-sm text-sm text-muted-foreground">
                                  Create your first bounty to start attracting developers to your project.
                                </p>
                                <button class="inline-flex h-9 items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground ring-offset-background transition-colors hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50">
                                  <.icon name="tabler-plus" class="mr-2 h-4 w-4" /> Add Bounty
                                </button>
                              </div>
                            </td>
                          </tr>
                        <% else %>
                          <%= for bounty <- @bounties do %>
                            <tr class="border-b transition-colors data-[state=selected]:bg-muted hover:bg-muted/50">
                              <td class="p-4 align-middle">
                                <div class="font-medium">{bounty.ticket.title}</div>
                                <div class="hidden text-sm text-muted-foreground md:inline">
                                  {bounty.ticket.owner}/{bounty.ticket.repo} #{bounty.ticket.number}
                                </div>
                              </td>
                              <td class="hidden p-4 align-middle sm:table-cell">
                                <div class="flex items-center gap-2">
                                  <img src={bounty.owner.avatar_url} class="h-6 w-6 rounded-full" />
                                  {bounty.owner.name}
                                </div>
                              </td>
                              <td class="hidden p-4 align-middle sm:table-cell">
                                <div class="flex flex-wrap gap-1">
                                  <%= for tech <- bounty.tech_stack || [] do %>
                                    <div class="inline-flex rounded-full border-transparent bg-secondary px-2.5 py-0.5 text-xs text-secondary-foreground">
                                      {tech}
                                    </div>
                                  <% end %>
                                </div>
                              </td>
                              <td class="hidden p-4 align-middle md:table-cell">
                                {Calendar.strftime(bounty.inserted_at, "%Y-%m-%d")}
                              </td>
                              <td class="p-4 text-right align-middle">
                                {Money.to_string!(bounty.amount)}
                              </td>
                            </tr>
                          <% end %>
                        <% end %>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="lg:col-span-1">
            <div class="mb-4 rounded-xl border bg-card text-card-foreground shadow">
              <div class="p-6">
                <div class="flex flex-col items-center space-y-3 text-center">
                  <div class="rounded-full bg-primary/10 p-3">
                    <.icon name="tabler-users-plus" class="h-6 w-6 text-primary" />
                  </div>
                  <h3 class="text-lg font-semibold">Invite Developers</h3>
                  <p class="text-sm text-muted-foreground">
                    Share this project with developers in your network or invite them directly.
                  </p>
                  <div class="flex gap-2">
                    <button class="inline-flex h-9 items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground ring-offset-background transition-colors hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50">
                      Invite Developers
                    </button>
                    <button class="inline-flex h-9 items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium ring-offset-background transition-colors hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50">
                      Share Link
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <%= if @matching_devs != [] do %>
              <div class="rounded-xl border bg-card text-card-foreground shadow">
                <div class="p-6">
                  <h2 class="mb-4 text-lg font-semibold leading-none tracking-tight">
                    Matching Developers
                  </h2>

                  <div class="space-y-4">
                    <%= for dev <- @matching_devs do %>
                      <div class="flex items-center gap-4 rounded-lg bg-accent/50 p-4">
                        <img src={dev.avatar_url} alt={dev.name} class="h-12 w-12 rounded-full" />
                        <div class="min-w-0 flex-grow">
                          <div class="flex items-start justify-between gap-2">
                            <div class="truncate">
                              <div class="truncate font-medium">
                                {dev.name} {dev.flag}
                              </div>
                              <div class="truncate text-sm text-muted-foreground">
                                @{User.handle(dev)}
                              </div>
                            </div>
                            <div class="shrink-0 text-right">
                              <div class="text-sm text-muted-foreground">Earned</div>
                              <div class="font-medium">
                                {Money.to_string!(dev.total_earned)}
                              </div>
                            </div>
                          </div>

                          <div class="mt-2 flex flex-wrap gap-1">
                            <%= for tech <- dev.tech_stack do %>
                              <span class="inline-flex items-center rounded-full border border-transparent bg-secondary px-2.5 py-0.5 text-xs font-semibold text-secondary-foreground transition-colors hover:bg-secondary/80 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2">
                                {tech}
                              </span>
                            <% end %>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </main>
      </div>
    </div>
    """
  end

  def handle_event("select_period", %{"period" => period}, socket) do
    {:noreply, assign(socket, active_period: period)}
  end
end
