defmodule AlgoraWeb.CompaniesLive do
  use AlgoraWeb, :live_view
  alias Algora.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:featured_devs, Accounts.list_featured_devs())
     |> assign(:stats, fetch_stats())
     |> assign(:mobile_menu_open, false)
     |> assign(:expanded_faq, nil)
     |> assign(:features, features())
     |> assign(:faqs, faqs())
     |> assign(:testimonials, testimonials())}
  end

  @impl true
  def handle_event("toggle-mobile-menu", _, socket) do
    {:noreply, assign(socket, :mobile_menu_open, !socket.assigns.mobile_menu_open)}
  end

  @impl true
  def handle_event("toggle-faq", %{"id" => id}, socket) do
    {:noreply,
     assign(socket, expanded_faq: if(socket.assigns.expanded_faq == id, do: nil, else: id))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gradient-to-tl from-indigo-950 to-black">
      <!-- Header with Mobile Menu -->
      <header class="absolute inset-x-0 top-0 z-50">
        <nav
          class="mx-auto flex max-w-7xl items-center justify-between p-6 lg:px-8"
          aria-label="Global"
        >
          <div class="flex lg:flex-1">
            <.wordmark class="text-white h-8 w-auto" />
          </div>
          <div class="flex lg:hidden">
            <button
              type="button"
              class="-m-2.5 inline-flex items-center justify-center rounded-md p-2.5 text-gray-300"
              phx-click="toggle-mobile-menu"
            >
              <span class="sr-only">Open main menu</span>
              <.icon name="tabler-menu-2" class="h-6 w-6" />
            </button>
          </div>
          <div class="hidden lg:flex lg:gap-x-12">
            <a href="#features" class="text-sm/6 font-semibold text-gray-300 hover:text-white">
              Features
            </a>
            <a href="#how-it-works" class="text-sm/6 font-semibold text-gray-300 hover:text-white">
              How it Works
            </a>
            <a href="#pricing" class="text-sm/6 font-semibold text-gray-300 hover:text-white">
              Pricing
            </a>
            <a href="#testimonials" class="text-sm/6 font-semibold text-gray-300 hover:text-white">
              Testimonials
            </a>
          </div>
          <div class="hidden lg:flex lg:flex-1 lg:justify-end">
            <.link
              navigate={~p"/auth/login"}
              class="text-sm/6 font-semibold text-gray-300 hover:text-white"
            >
              Log in <span aria-hidden="true">&rarr;</span>
            </.link>
          </div>
        </nav>
        <!-- Mobile menu -->
        <div :if={@mobile_menu_open} class="lg:hidden" role="dialog" aria-modal="true">
          <div class="fixed inset-0 z-50"></div>
          <div class="fixed inset-y-0 right-0 z-50 w-full overflow-y-auto bg-gray-900 px-6 py-6 sm:max-w-sm sm:ring-1 sm:ring-white/10">
            <div class="flex items-center justify-between">
              <.wordmark class="text-white h-8 w-auto" />
              <button
                type="button"
                class="-m-2.5 rounded-md p-2.5 text-gray-300"
                phx-click="toggle-mobile-menu"
              >
                <span class="sr-only">Close menu</span>
                <.icon name="tabler-x" class="h-6 w-6" />
              </button>
            </div>
            <div class="mt-6 flow-root">
              <div class="-my-6 divide-y divide-gray-500/10">
                <div class="space-y-2 py-6">
                  <a
                    href="#features"
                    class="-mx-3 block rounded-lg px-3 py-2 text-base font-semibold text-gray-300 hover:bg-gray-800"
                  >
                    Features
                  </a>
                  <a
                    href="#how-it-works"
                    class="-mx-3 block rounded-lg px-3 py-2 text-base font-semibold text-gray-300 hover:bg-gray-800"
                  >
                    How it Works
                  </a>
                  <a
                    href="#pricing"
                    class="-mx-3 block rounded-lg px-3 py-2 text-base font-semibold text-gray-300 hover:bg-gray-800"
                  >
                    Pricing
                  </a>
                  <a
                    href="#testimonials"
                    class="-mx-3 block rounded-lg px-3 py-2 text-base font-semibold text-gray-300 hover:bg-gray-800"
                  >
                    Testimonials
                  </a>
                </div>
                <div class="py-6">
                  <.link
                    navigate={~p"/auth/login"}
                    class="-mx-3 block rounded-lg px-3 py-2.5 text-base font-semibold text-gray-300 hover:bg-gray-800"
                  >
                    Log in
                  </.link>
                </div>
              </div>
            </div>
          </div>
        </div>
      </header>

      <main>
        <!-- Hero Section -->
        <div class="relative isolate">
          <div class="mx-auto max-w-7xl px-6 pb-24 pt-36 sm:pt-60 lg:px-8 lg:pt-32">
            <div class="mx-auto max-w-2xl text-center">
              <h1 class="text-4xl font-bold tracking-tight text-white sm:text-6xl font-display">
                Hire Elite Open Source Developers
              </h1>
              <p class="mt-6 text-lg leading-8 text-gray-300">
                Access a curated network of top open source contributors. From quick bug fixes to full-time hires,
                find the perfect developer for your needs.
              </p>
              <div class="mt-10 flex items-center justify-center gap-x-6">
                <.link
                  navigate={~p"/onboarding/org"}
                  class="rounded-md bg-indigo-500 px-8 py-3 text-lg font-semibold text-white shadow-sm hover:bg-indigo-400"
                >
                  Post Your First Job
                </.link>
                <a href="#how-it-works" class="text-sm font-semibold leading-6 text-white">
                  Learn more <span aria-hidden="true">→</span>
                </a>
              </div>
            </div>
            <!-- Stats Section -->
            <dl class="mx-auto mt-16 grid max-w-4xl grid-cols-2 gap-8 text-center lg:grid-cols-4">
              <%= for stat <- @stats do %>
                <div class="mx-auto flex max-w-xs flex-col gap-y-2">
                  <dt class="text-base leading-7 text-gray-400"><%= stat.label %></dt>
                  <dd class="order-first text-3xl font-semibold tracking-tight text-white font-display">
                    <%= stat.value %>
                  </dd>
                </div>
              <% end %>
            </dl>
          </div>
        </div>
        <!-- Integration Logos -->
        <div class="mx-auto max-w-7xl px-6 sm:px-8 pb-24">
          <h2 class="text-center text-lg font-semibold leading-8 text-white mb-8">
            Seamlessly Integrates With Your Tools
          </h2>
          <div class="mx-auto grid max-w-lg grid-cols-4 items-center gap-x-8 gap-y-12 sm:max-w-xl sm:grid-cols-6 sm:gap-x-10 lg:mx-0 lg:max-w-none lg:grid-cols-5">
            <img
              class="col-span-2 max-h-12 w-full object-contain lg:col-span-1 brightness-200"
              src="https://upload.wikimedia.org/wikipedia/commons/9/91/Octicons-mark-github.svg"
              alt="GitHub"
            />
            <img
              class="col-span-2 max-h-12 w-full object-contain lg:col-span-1 brightness-200"
              src="https://upload.wikimedia.org/wikipedia/commons/8/8e/Slack_icon_2019.svg"
              alt="Slack"
            />
            <img
              class="col-span-2 max-h-12 w-full object-contain lg:col-span-1 brightness-200"
              src="https://upload.wikimedia.org/wikipedia/commons/b/ba/Stripe_Logo%2C_revised_2016.svg"
              alt="Stripe"
            />
            <img
              class="col-span-2 max-h-12 w-full object-contain lg:col-span-1 brightness-200"
              src="https://upload.wikimedia.org/wikipedia/commons/4/4e/Linear_logo_%282021%29.svg"
              alt="Linear"
            />
            <img
              class="col-span-2 max-h-12 w-full object-contain lg:col-span-1 brightness-200"
              src="https://upload.wikimedia.org/wikipedia/commons/8/82/Telegram_logo.svg"
              alt="Telegram"
            />
          </div>
        </div>
        <!-- Features Section -->
        <div id="features" class="py-24 sm:py-32">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <div class="mx-auto max-w-2xl lg:text-center">
              <h2 class="text-base font-semibold leading-7 text-indigo-400">Deploy faster</h2>
              <p class="mt-2 text-3xl font-bold tracking-tight text-white sm:text-4xl">
                Everything you need to manage developers
              </p>
              <p class="mt-6 text-lg leading-8 text-gray-300">
                From finding the right talent to managing payments, we've got you covered with a complete suite of tools.
              </p>
            </div>
            <div class="mx-auto mt-16 max-w-2xl sm:mt-20 lg:mt-24 lg:max-w-none">
              <dl class="grid max-w-xl grid-cols-1 gap-x-8 gap-y-16 lg:max-w-none lg:grid-cols-3">
                <%= for feature <- features() do %>
                  <div class="flex flex-col">
                    <dt class="flex items-center gap-x-3 text-base font-semibold leading-7 text-white">
                      <.icon name={feature.icon} class="h-5 w-5 flex-none text-indigo-400" />
                      <%= feature.name %>
                    </dt>
                    <dd class="mt-4 flex flex-auto flex-col text-base leading-7 text-gray-300">
                      <p class="flex-auto"><%= feature.description %></p>
                    </dd>
                  </div>
                <% end %>
              </dl>
            </div>
          </div>
        </div>
        <!-- How it Works Section -->
        <div id="how-it-works" class="py-24 sm:py-32">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <div class="mx-auto max-w-2xl lg:text-center">
              <h2 class="text-base font-semibold leading-7 text-indigo-400">Getting Started</h2>
              <p class="mt-2 text-3xl font-bold tracking-tight text-white sm:text-4xl">
                How Algora Works
              </p>
              <p class="mt-6 text-lg leading-8 text-gray-300">
                Get started in minutes and find the perfect developer for your project.
              </p>
            </div>
            <div class="mx-auto mt-16 max-w-2xl sm:mt-20 lg:mt-24 lg:max-w-none">
              <dl class="grid max-w-xl grid-cols-1 gap-x-8 gap-y-16 lg:max-w-none lg:grid-cols-3">
                <%= for {step, i} <- Enum.with_index(how_it_works()) do %>
                  <div class="flex flex-col">
                    <dt class="flex items-center gap-x-3 text-base font-semibold leading-7 text-white">
                      <div class="rounded-full bg-indigo-400 w-8 h-8 flex items-center justify-center text-black font-bold">
                        <%= i + 1 %>
                      </div>
                      <%= step.name %>
                    </dt>
                    <dd class="mt-4 flex flex-auto flex-col text-base leading-7 text-gray-300">
                      <p class="flex-auto"><%= step.description %></p>
                    </dd>
                  </div>
                <% end %>
              </dl>
            </div>
          </div>
        </div>
        <!-- Pricing Section -->
        <div id="pricing" class="py-24 sm:py-32">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <div class="mx-auto max-w-2xl text-center">
              <h2 class="text-base font-semibold leading-7 text-indigo-400">Pricing</h2>
              <p class="mt-2 text-3xl font-bold tracking-tight text-white sm:text-4xl">
                Simple, transparent pricing
              </p>
              <p class="mt-6 text-lg leading-8 text-gray-300">
                Choose the plan that best fits your needs. All plans include access to our full platform.
              </p>
            </div>
            <div class="mx-auto mt-16 grid max-w-lg grid-cols-1 gap-8 lg:max-w-none lg:grid-cols-3">
              <%= for plan <- pricing_plans() do %>
                <div class="flex flex-col justify-between rounded-3xl bg-white/5 p-8 ring-1 ring-white/10 xl:p-10">
                  <div>
                    <div class="flex items-center justify-between gap-x-4">
                      <h3 class="text-lg font-semibold leading-8 text-white"><%= plan.name %></h3>
                      <%= if plan.popular do %>
                        <p class="rounded-full bg-indigo-500 px-2.5 py-1 text-xs font-semibold leading-5 text-white">
                          Most popular
                        </p>
                      <% end %>
                    </div>
                    <p class="mt-6 text-base leading-7 text-gray-300"><%= plan.description %></p>
                    <p class="mt-8 flex items-baseline gap-x-1">
                      <span class="text-4xl font-bold tracking-tight text-white">
                        <%= plan.price %>
                      </span>
                      <%= if plan.period do %>
                        <span class="text-sm font-semibold leading-6 text-gray-300">
                          /<%= plan.period %>
                        </span>
                      <% end %>
                    </p>
                    <ul role="list" class="mt-8 space-y-3 text-sm leading-6 text-gray-300">
                      <%= for feature <- plan.features do %>
                        <li class="flex gap-x-3">
                          <.icon name="tabler-check" class="h-5 w-5 flex-none text-indigo-400" />
                          <%= feature %>
                        </li>
                      <% end %>
                    </ul>
                  </div>
                  <.link
                    navigate={~p"/onboarding/org"}
                    class="mt-8 block rounded-md bg-indigo-500 px-3 py-2 text-center text-sm font-semibold leading-6 text-white shadow-sm hover:bg-indigo-400 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
                  >
                    Get started today
                  </.link>
                </div>
              <% end %>
            </div>
          </div>
        </div>
        <!-- Testimonials Section -->
        <div id="testimonials" class="py-24 sm:py-32">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <div class="mx-auto max-w-xl text-center">
              <h2 class="text-lg font-semibold leading-8 text-indigo-400">Testimonials</h2>
              <p class="mt-2 text-3xl font-bold tracking-tight text-white sm:text-4xl">
                Trusted by companies worldwide
              </p>
            </div>
            <div class="mx-auto mt-16 space-y-24">
              <%= for {testimonial, index} <- Enum.with_index(@testimonials) do %>
                <div class="relative isolate overflow-hidden bg-white/5 px-6 py-12 sm:px-10 sm:py-16 rounded-2xl ring-1 ring-white/10">
                  <div class="mx-auto grid max-w-2xl grid-cols-1 gap-x-12 gap-y-16 lg:mx-0 lg:max-w-none lg:grid-cols-2 lg:items-start lg:gap-y-10">
                    <%= if index == 4 do %>
                      <div class="lg:col-span-1">
                        <div class="relative w-full overflow-hidden rounded-2xl">
                          <div class="relative pt-[56.25%]">
                            <iframe
                              class="absolute inset-0 w-full h-full"
                              src="https://www.youtube.com/embed/your_video_id"
                              title="Customer Success Story"
                              frameborder="0"
                              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                              allowfullscreen
                            >
                            </iframe>
                          </div>
                        </div>
                        <div class="text-center lg:text-left mt-8">
                          <h3 class="text-2xl font-semibold leading-7 tracking-tight text-white">
                            <%= testimonial.name %>
                          </h3>
                          <p class="text-lg leading-6 text-gray-400 mt-2"><%= testimonial.role %></p>
                          <p class="text-md leading-6 text-indigo-400"><%= testimonial.company %></p>
                        </div>
                        <figure class="mt-8">
                          <blockquote class="text-xl leading-8 text-gray-300 italic">
                            <p>"<%= testimonial.quote %>"</p>
                          </blockquote>
                        </figure>
                      </div>
                      <div class="lg:col-span-1">
                        <div class="rounded-2xl bg-white/5 p-8 ring-1 ring-white/10">
                          <h4 class="text-lg font-semibold leading-6 text-indigo-400 mb-6">
                            Their Journey with Algora
                          </h4>
                          <div class="text-gray-300 text-lg leading-relaxed mb-8">
                            <%= for paragraph <- testimonial.description do %>
                              <p class="mb-4"><%= paragraph %></p>
                            <% end %>
                          </div>
                          <h4 class="text-sm font-semibold leading-6 text-indigo-400 mb-6">
                            Impact Summary
                          </h4>
                          <dl class="grid grid-cols-2 gap-6">
                            <%= for {label, value} <- testimonial.results do %>
                              <div>
                                <dt class="text-sm font-medium leading-6 text-gray-300">
                                  <%= label %>
                                </dt>
                                <dd class="mt-1 text-2xl font-semibold tracking-tight text-white">
                                  <%= value %>
                                </dd>
                              </div>
                            <% end %>
                          </dl>
                        </div>
                      </div>
                    <% else %>
                      <div class="lg:col-span-1">
                        <div class="flex flex-col items-center lg:items-start gap-y-8">
                          <img class="h-32 w-32 rounded-full" src={testimonial.avatar} alt="" />
                          <div class="text-center lg:text-left">
                            <h3 class="text-2xl font-semibold leading-7 tracking-tight text-white">
                              <%= testimonial.name %>
                            </h3>
                            <p class="text-lg leading-6 text-gray-400 mt-2">
                              <%= testimonial.role %>
                            </p>
                            <p class="text-md leading-6 text-indigo-400">
                              <%= testimonial.company %>
                            </p>
                          </div>
                        </div>
                        <figure class="mt-12">
                          <blockquote class="text-xl leading-8 text-gray-300 italic">
                            <p>"<%= testimonial.quote %>"</p>
                          </blockquote>
                        </figure>
                      </div>
                      <div class="lg:col-span-1">
                        <div class="rounded-2xl bg-white/5 p-8 ring-1 ring-white/10">
                          <h4 class="text-lg font-semibold leading-6 text-indigo-400 mb-6">
                            Their Journey with Algora
                          </h4>
                          <div class="text-gray-300 text-lg leading-relaxed mb-8">
                            <%= for paragraph <- testimonial.description do %>
                              <p class="mb-4"><%= paragraph %></p>
                            <% end %>
                          </div>
                          <h4 class="text-sm font-semibold leading-6 text-indigo-400 mb-6">
                            Impact Summary
                          </h4>
                          <dl class="grid grid-cols-2 gap-6">
                            <%= for {label, value} <- testimonial.results do %>
                              <div>
                                <dt class="text-sm font-medium leading-6 text-gray-300">
                                  <%= label %>
                                </dt>
                                <dd class="mt-1 text-2xl font-semibold tracking-tight text-white">
                                  <%= value %>
                                </dd>
                              </div>
                            <% end %>
                          </dl>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
        <!-- FAQ Section -->
        <div class="mx-auto max-w-7xl px-6 py-24 sm:py-32 lg:px-8 lg:py-40">
          <div class="mx-auto max-w-4xl divide-y divide-white/10">
            <h2 class="text-2xl font-bold leading-10 tracking-tight text-white">
              Frequently asked questions
            </h2>
            <dl class="mt-10 space-y-6 divide-y divide-white/10">
              <%= for faq <- faqs() do %>
                <div class="pt-6">
                  <dt>
                    <h3 class="text-base font-semibold leading-7 text-white">
                      <%= faq.question %>
                    </h3>
                  </dt>
                  <dd class="mt-2 text-base leading-7 text-gray-300">
                    <%= faq.answer %>
                  </dd>
                </div>
              <% end %>
            </dl>
          </div>
        </div>
        <!-- Case Studies -->
        <div class="py-24 sm:py-32">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <div class="mx-auto max-w-2xl text-center">
              <h2 class="text-base font-semibold leading-7 text-indigo-400">Case Studies</h2>
              <p class="mt-2 text-3xl font-bold tracking-tight text-white sm:text-4xl">
                Success Stories
              </p>
              <p class="mt-6 text-lg leading-8 text-gray-300">
                See how other companies have succeeded with Algora
              </p>
            </div>
            <div class="mx-auto mt-16 grid max-w-2xl auto-rows-fr grid-cols-1 gap-8 sm:mt-20 lg:mx-0 lg:max-w-none lg:grid-cols-3">
              <%= for case_study <- case_studies() do %>
                <article class="relative isolate flex flex-col justify-end overflow-hidden rounded-2xl bg-gray-900 px-8 pb-8 pt-80 sm:pt-48 lg:pt-80">
                  <img
                    src={case_study.image}
                    alt=""
                    class="absolute inset-0 -z-10 h-full w-full object-cover"
                  />
                  <div class="absolute inset-0 -z-10 bg-gradient-to-t from-gray-900 via-gray-900/40">
                  </div>
                  <div class="absolute inset-0 -z-10 rounded-2xl ring-1 ring-inset ring-gray-900/10">
                  </div>

                  <div class="flex flex-wrap items-center gap-y-1 overflow-hidden text-sm leading-6 text-gray-300">
                    <time datetime={case_study.date} class="mr-8"><%= case_study.date %></time>
                    <div class="-ml-4 flex items-center gap-x-4">
                      <svg viewBox="0 0 2 2" class="-ml-0.5 h-0.5 w-0.5 flex-none fill-white/50">
                        <circle cx="1" cy="1" r="1" />
                      </svg>
                      <div class="flex gap-x-2.5">
                        <img
                          src={case_study.author_image}
                          alt=""
                          class="h-6 w-6 flex-none rounded-full bg-white/10"
                        />
                        <%= case_study.author %>
                      </div>
                    </div>
                  </div>
                  <h3 class="mt-3 text-lg font-semibold leading-6 text-white">
                    <a href={case_study.href}>
                      <span class="absolute inset-0"></span>
                      <%= case_study.title %>
                    </a>
                  </h3>
                </article>
              <% end %>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  defp features do
    [
      %{
        name: "Global Talent Pool",
        icon: "tabler-world",
        description:
          "Access top developers from around the world, pre-vetted and ready to contribute to your projects."
      },
      %{
        name: "Seamless Integration",
        icon: "tabler-puzzle",
        description:
          "Our platform integrates with your existing tools and workflows, making team expansion effortless."
      },
      %{
        name: "Quality Assurance",
        icon: "tabler-shield-check",
        description:
          "Every developer is thoroughly vetted through technical assessments and real-world projects."
      },
      %{
        name: "Flexible Engagement",
        icon: "tabler-clock",
        description:
          "Work with developers on your terms - full-time, part-time, or project-based."
      },
      %{
        name: "Cost Effective",
        icon: "tabler-coin",
        description: "Save on recruitment costs and overhead while accessing top-tier talent."
      },
      %{
        name: "24/7 Support",
        icon: "tabler-headset",
        description: "Our team is always available to help you with any questions or concerns."
      }
    ]
  end

  defp how_it_works do
    [
      %{
        name: "Create Your Project",
        description: "Describe your needs, set your budget, and specify your requirements."
      },
      %{
        name: "Get Matched",
        description:
          "Our AI matches you with the best developers for your project based on skills and experience."
      },
      %{
        name: "Start Working",
        description:
          "Begin collaboration immediately with our integrated project management tools."
      }
    ]
  end

  defp pricing_plans do
    [
      %{
        name: "Basic",
        price: "Free",
        description: "Perfect for small projects and individual developers.",
        period: nil,
        popular: false,
        features: [
          "Up to 3 active projects",
          "Basic developer matching",
          "Standard support",
          "Community access"
        ]
      },
      %{
        name: "Pro",
        price: "$99",
        description: "Everything you need for growing teams.",
        period: "month",
        popular: true,
        features: [
          "Unlimited projects",
          "Priority matching",
          "24/7 priority support",
          "Advanced analytics",
          "Custom integrations"
        ]
      },
      %{
        name: "Enterprise",
        price: "Custom",
        description: "Dedicated support and custom solutions for large organizations.",
        period: nil,
        popular: false,
        features: [
          "Custom solutions",
          "Dedicated account manager",
          "SLA guarantees",
          "Advanced security features",
          "Custom reporting"
        ]
      }
    ]
  end

  defp testimonials do
    [
      %{
        name: "Sarah Chen",
        role: "CEO & Co-founder",
        company: "TechCorp",
        avatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
        quote:
          "Algora has transformed how we build our engineering team. The quality of developers and the speed at which we were able to scale our team exceeded our expectations.",
        description: [
          "TechCorp came to Algora looking to scale their engineering team rapidly without compromising on quality.",
          "Within weeks, they were able to onboard senior developers who had significant open source contributions in their tech stack.",
          "The seamless integration with their existing workflows meant new hires could start contributing immediately."
        ],
        results: [
          {"Developers Hired", "12"},
          {"Time to Hire", "< 2 weeks"},
          {"Cost Savings", "45%"},
          {"Projects Completed", "28"}
        ]
      },
      %{
        name: "Michael Rodriguez",
        role: "CTO",
        company: "StartupX",
        avatar: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e",
        quote:
          "The developers we've hired through Algora have been exceptional. They don't just write code - they contribute meaningful solutions and have become integral parts of our team.",
        description: [
          "StartupX needed to build a team of specialized developers for their AI-powered platform.",
          "Through Algora, they found developers who not only had the technical skills but also brought valuable experience from similar projects.",
          "The quality of contributions led them to expand their initial hiring plans and build out entire new features."
        ],
        results: [
          {"Team Growth", "3x"},
          {"Sprint Velocity", "+65%"},
          {"Code Quality", "98%"},
          {"Retention Rate", "95%"}
        ]
      },
      %{
        name: "Emily Thompson",
        role: "VP Engineering",
        company: "ScaleUp Inc",
        avatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80",
        quote:
          "What impressed me most was how quickly the developers were able to adapt to our codebase and start making meaningful contributions. The quality of talent on Algora is outstanding.",
        description: [
          "ScaleUp Inc was struggling to find developers who could handle their complex microservices architecture.",
          "Algora matched them with developers who had extensive experience with distributed systems and cloud infrastructure.",
          "The impact was immediate, with new team members improving system reliability and deployment processes within their first month."
        ],
        results: [
          {"Open Source Contributions", "150+"},
          {"Team Expansion", "4x"},
          {"Project Delivery", "2x faster"},
          {"Cost Efficiency", "40%"}
        ]
      },
      %{
        name: "David Park",
        role: "Head of Engineering",
        company: "InnovateAI",
        avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d",
        quote:
          "Finding ML engineers with open source experience was a challenge until we discovered Algora. The platform's matching algorithm helped us build a world-class AI team in record time.",
        description: [
          "InnovateAI needed specialized machine learning engineers with experience in production systems.",
          "Through Algora's network, they connected with developers who had contributed to major ML frameworks.",
          "The new team members helped revolutionize their ML pipeline and significantly improve model performance."
        ],
        results: [
          {"Specialized Hires", "8"},
          {"Product Launch", "3 months faster"},
          {"Model Accuracy", "+28%"},
          {"Infrastructure Savings", "52%"}
        ]
      },
      %{
        name: "Alex Rivera",
        role: "Engineering Director",
        company: "CloudScale Systems",
        quote:
          "Algora didn't just help us hire developers - they helped us build a culture of open source contribution that has transformed our entire engineering organization.",
        description: [
          "CloudScale Systems needed to rapidly scale their infrastructure team while maintaining their high standards for code quality.",
          "Through Algora, they found developers with significant contributions to major cloud infrastructure projects.",
          "The team's expertise in cloud-native technologies helped them reduce deployment times and improve system reliability."
        ],
        results: [
          {"Infrastructure Costs", "-60%"},
          {"Deployment Time", "90% faster"},
          {"System Reliability", "99.999%"},
          {"Team Productivity", "3x increase"}
        ]
      }
    ]
  end

  defp faqs do
    [
      %{
        question: "How does your developer vetting process work?",
        answer:
          "Our vetting process is comprehensive and includes multiple stages: technical skills assessment, code quality review, communication evaluation, and background verification. We accept only the top 1% of applicants to ensure the highest quality talent for your team."
      },
      %{
        question: "What if I'm not satisfied with a developer's performance?",
        answer:
          "We offer a 100% satisfaction guarantee. If you're not completely satisfied with a developer's performance, we'll work with you to find a replacement at no additional cost. Our priority is ensuring a perfect fit for your team."
      },
      %{
        question: "How quickly can I add developers to my team?",
        answer:
          "Most companies are able to start working with their new developers within 1-2 weeks. For specialized roles or specific technology requirements, it might take up to 3 weeks to ensure the perfect match."
      },
      %{
        question: "What types of developers are available on your platform?",
        answer:
          "We have developers across all major technologies and specializations including: Frontend (React, Vue, Angular), Backend (Node.js, Python, Ruby, Elixir), Mobile (iOS, Android, React Native), DevOps, Data Science, and more."
      },
      %{
        question: "How do you handle intellectual property and NDAs?",
        answer:
          "We take intellectual property very seriously. All developers sign comprehensive NDAs and IP assignment agreements. We can also work with your legal team to implement any additional agreements specific to your company's needs."
      },
      %{
        question: "What are your pricing models?",
        answer:
          "We offer flexible pricing models to suit different needs: hourly rates for project-based work, monthly retainers for ongoing engagements, and custom enterprise packages for larger teams. Contact us for detailed pricing based on your specific requirements."
      }
    ]
  end

  defp case_studies do
    [
      %{
        title: "How StartupX Scaled Their Engineering Team",
        href: "#",
        description:
          "StartupX needed to double their engineering team in 3 months. See how they did it with Algora.",
        date: "Mar 16, 2024",
        author: "Tom Cook",
        author_image: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e",
        image:
          "https://images.unsplash.com/photo-1496128858413-b36217c2ce36?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=3603&q=80"
      },
      %{
        title: "TechCorp's Journey to Remote-First Development",
        href: "#",
        description: "How TechCorp built a distributed engineering team across 12 countries.",
        date: "Mar 10, 2024",
        author: "Sarah Chen",
        author_image: "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
        image:
          "https://images.unsplash.com/photo-1547586696-ea22b4d4235d?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=3270&q=80"
      },
      %{
        title: "DevCo's Open Source Success Story",
        href: "#",
        description:
          "How DevCo leveraged open source talent to accelerate their product development.",
        date: "Mar 5, 2024",
        author: "Emily Thompson",
        author_image: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80",
        image:
          "https://images.unsplash.com/photo-1492724441997-5dc865305da7?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=3270&q=80"
      }
    ]
  end

  defp fetch_stats do
    [
      %{label: "Average Response Time", value: "4h"},
      %{label: "Vetted Developers", value: "500+"},
      %{label: "Success Rate", value: "94%"},
      %{label: "Cost Savings", value: "40%"}
    ]
  end
end
