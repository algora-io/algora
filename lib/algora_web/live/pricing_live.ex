defmodule AlgoraWeb.PricingLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias AlgoraWeb.Components.Footer
  alias AlgoraWeb.Components.Header

  defmodule Plan do
    @moduledoc false
    defstruct [
      :name,
      :description,
      :price,
      :cta_text,
      :popular,
      :previous_tier,
      :features,
      :footnote
    ]
  end

  defmodule Feature do
    @moduledoc false
    defstruct [:name, :detail]
  end

  defmodule ComputeOption do
    @moduledoc false
    defstruct [:name, :cpu, :memory, :price]
  end

  defmodule FaqItem do
    @moduledoc false
    defstruct [:id, :question, :answer]
  end

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        page_title: "Pricing",
        plans: get_plans(),
        faq_items: get_faq_items(),
        testimonials: get_testimonials(),
        page_scroll: 0,
        active_faq: nil
      )

    {:ok, socket}
  end

  def handle_event("select_plan", %{"plan" => plan_name}, socket) do
    {:noreply, push_navigate(socket, to: "/signup?plan=#{plan_name}")}
  end

  def handle_event("toggle_faq", %{"id" => faq_id}, socket) do
    active_faq = if socket.assigns.active_faq == faq_id, do: nil, else: faq_id
    {:noreply, assign(socket, active_faq: active_faq)}
  end

  def handle_event("select_compute", %{"option" => option}, socket) do
    {:noreply, assign(socket, selected_compute_option: option)}
  end

  # Component: Pricing Card
  def pricing_card(assigns) do
    ~H"""
    <div class={[
      "bg-surface-75 flex flex-col rounded-xl border first:rounded-l-xl last:rounded-r-xl last:border-r xl:rounded-none xl:border-r-0",
      @plan.popular && "border-foreground-muted !border-2 !rounded-xl xl:-my-8"
    ]}>
      <div class="px-8 pt-6 xl:px-4 2xl:px-8">
        <div class="flex items-center gap-2">
          <div class="flex items-center gap-2 pb-2">
            <h3 class="font-display flex items-center gap-4 text-2xl font-normal uppercase text-foreground">
              {@plan.name}
            </h3>
            <%= if @plan.popular do %>
              <span class="bg-foreground-light text-[13px] rounded-md px-2 py-0.5 leading-4 text-background">
                Most Popular
              </span>
            <% end %>
          </div>
        </div>
        <p class="text-foreground-light mb-4 text-sm 2xl:pr-4">
          {@plan.description}
        </p>
        <button
          phx-click="select_plan"
          phx-value-plan={@plan.name}
          class={[
            "font-regular h-[42px] relative w-full cursor-pointer space-x-2 rounded-md border px-4 py-2 text-center outline-none outline-0 transition-all duration-200 ease-out focus-visible:outline-4 focus-visible:outline-offset-1",
            @plan.popular && "mt-8 bg-primary text-primary-foreground hover:bg-primary/90",
            !@plan.popular &&
              "bg-background text-foreground hover:bg-accent hover:text-accent-foreground"
          ]}
        >
          {@plan.cta_text}
        </button>
        <div class="border-default flex items-baseline border-b py-8 text-5xl font-normal text-foreground lg:min-h-[175px] lg:pt-10 lg:pb-0 lg:text-4xl xl:text-4xl">
          <div class="flex flex-col gap-1">
            <%= if @plan.price do %>
              <div>
                <p class="text-foreground-lighter text-[13px] ml-1 font-normal leading-4">From</p>
                <div class="flex items-end">
                  <p class="font-display mt-2 pb-1 text-5xl">${@plan.price}</p>
                  <p class="text-foreground-lighter text-[13px] mb-1.5 ml-1 leading-4">/ month</p>
                </div>
              </div>
            <% else %>
              <div class="mt-4 flex items-end">
                <p class="font-display mt-2 pb-1 text-4xl">Custom</p>
              </div>
            <% end %>
          </div>
        </div>
      </div>
      <div class="border-default rounded-bl-[4px] rounded-br-[4px] flex flex-1 flex-col px-8 py-6 xl:px-4 2xl:px-8">
        <p class="text-foreground-lighter text-[13px] mt-2 mb-4">
          {if @plan.previous_tier,
            do: "Everything in the #{@plan.previous_tier} Plan, plus:",
            else: "Get started with:"}
        </p>
        <ul class="text-[13px] text-foreground-lighter flex-1">
          <%= for feature <- @plan.features do %>
            <li class="flex flex-col py-2 first:mt-0">
              <div class="flex items-center">
                <div class="flex w-6">
                  <.icon name="tabler-check" class="h-4 w-4 text-primary" />
                </div>
                <span class="mb-0 text-foreground">{feature.name}</span>
              </div>
              <%= if feature.detail do %>
                <p class="text-foreground-lighter ml-6">{feature.detail}</p>
              <% end %>
            </li>
          <% end %>
        </ul>
        <%= if @plan.footnote do %>
          <div class="mt-auto flex flex-col gap-6 prose">
            <div class="mt-12 space-y-2">
              <p class="text-[13px] text-foreground-lighter mb-0 whitespace-pre-wrap leading-5">
                {@plan.footnote}
              </p>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Component: Compute Add-ons
  def compute_addons(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl">
      <div class="mb-16 text-center">
        <h2 class="mb-4 text-3xl font-bold text-foreground">Compute Add-ons</h2>
        <p class="text-lg text-muted-foreground">
          Additional compute resources for demanding workloads
        </p>
      </div>
      <div class="grid grid-cols-1 gap-8 md:grid-cols-3">
        <%= for option <- @compute_addons do %>
          <div class={["rounded-lg border p-6", @selected_option == option.name && "border-primary"]}>
            <button phx-click="select_compute" phx-value-option={option.name} class="w-full text-left">
              <h3 class="mb-2 text-xl font-semibold text-foreground">{option.name}</h3>
              <div class="space-y-2 text-sm text-muted-foreground">
                <p>CPU: {option.cpu}</p>
                <p>Memory: {option.memory}</p>
                <p class="text-lg font-semibold text-foreground">${option.price}/month</p>
              </div>
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Component: Plan Comparison Table
  def plan_comparison_table(assigns) do
    ~H"""
    <div class="container mx-auto py-16">
      <h2 class="mb-12 text-center text-3xl font-bold text-foreground">Compare Plans</h2>
      <div class="overflow-x-auto">
        <table class="w-full border-collapse">
          <thead>
            <tr class="border-b">
              <th class="p-4 text-left text-muted-foreground">Features</th>
              <%= for plan <- @plans do %>
                <th class="p-4 text-center text-muted-foreground">
                  {plan.name}
                </th>
              <% end %>
            </tr>
          </thead>
          <tbody>
            <%= for feature <- get_comparison_features() do %>
              <tr class="border-b">
                <td class="p-4 text-foreground">{feature.name}</td>
                <%= for plan <- @plans do %>
                  <td class="p-4 text-center">
                    <%= if has_feature?(plan, feature) do %>
                      <.icon name="tabler-check" class="mx-auto h-5 w-5 text-primary" />
                    <% else %>
                      <.icon name="tabler-minus" class="mx-auto h-5 w-5 text-muted-foreground" />
                    <% end %>
                  </td>
                <% end %>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  # Component: FAQ Section
  def faq_section(assigns) do
    ~H"""
    <div class="container mx-auto py-16">
      <h2 class="mb-12 text-center text-3xl font-bold text-foreground">
        Frequently asked questions
      </h2>
      <div class="mx-auto max-w-3xl space-y-4">
        <%= for item <- @faq_items do %>
          <div class="rounded-lg border">
            <button
              phx-click="toggle_faq"
              phx-value-id={item.id}
              class="flex w-full items-center justify-between p-4 text-left"
            >
              <span class="font-medium text-foreground">{item.question}</span>
              <.icon
                name="tabler-chevron-down"
                class={
                  classes([
                    "h-5 w-5 text-muted-foreground transition-transform duration-200",
                    @active_faq == item.id && "rotate-180 transform"
                  ])
                }
              />
            </button>
            <%= if @active_faq == item.id do %>
              <div class="p-4 pt-0 text-muted-foreground">
                {item.answer}
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Data functions
  defp get_plans do
    [
      %Plan{
        name: "Hobby",
        description: "Perfect for small projects and indie developers",
        price: 0,
        cta_text: "Start for Free",
        popular: false,
        features: [
          %Feature{name: "Up to $5,000 in project budgets"},
          %Feature{name: "Algora Network", detail: "15% platform fee"},
          %Feature{name: "Bring Your Own Devs", detail: "5% platform fee"},
          %Feature{name: "Unlimited projects"},
          %Feature{name: "Community support"},
          %Feature{name: "Basic project management tools"},
          %Feature{name: "Pay per milestone"}
        ],
        footnote: "Perfect for testing the waters with smaller projects"
      },
      %Plan{
        name: "Startup",
        description: "For growing companies",
        price: 599,
        cta_text: "Upgrade now",
        popular: true,
        previous_tier: "Hobby",
        features: [
          %Feature{name: "Up to $50,000 in project budgets"},
          %Feature{name: "Algora Network", detail: "15% platform fee"},
          %Feature{name: "Bring Your Own Devs", detail: "5% platform fee"},
          %Feature{name: "Priority support"},
          %Feature{name: "Advanced project management"},
          %Feature{name: "Custom workflows"},
          %Feature{name: "Team collaboration tools"},
          %Feature{name: "Analytics dashboard"},
          %Feature{name: "Job board access"},
          %Feature{name: "Unlimited job postings"}
        ]
      },
      %Plan{
        name: "Enterprise",
        description: "For large organizations",
        price: nil,
        cta_text: "Contact Sales",
        popular: false,
        previous_tier: "Startup",
        features: [
          %Feature{name: "Unlimited project budgets"},
          %Feature{name: "Algora Network", detail: "15% platform fee"},
          %Feature{name: "Bring Your Own Devs", detail: "5% platform fee"},
          %Feature{name: "Dedicated account manager"},
          %Feature{name: "Custom contracts & MSA"},
          %Feature{name: "Advanced security features"},
          %Feature{name: "Custom integrations"},
          %Feature{name: "SLA guarantees"},
          %Feature{name: "Onboarding assistance"},
          %Feature{name: "Training for your team"},
          %Feature{name: "Custom job board"},
          %Feature{name: "ATS integration"}
        ]
      }
    ]
  end

  defp get_faq_items do
    [
      %FaqItem{
        id: "platform-fee",
        question: "How do the platform fees work?",
        answer:
          "We charge 15% for projects using the Algora Network of developers, or 5% if you bring your own developers. This fee helps us maintain the platform, provide payment protection, and ensure quality service."
      },
      %FaqItem{
        id: "budget-limits",
        question: "What happens if my project exceeds the budget limit?",
        answer:
          "You'll need to upgrade to a higher tier to handle larger project budgets. Contact our sales team if you're close to your limit."
      },
      %FaqItem{
        id: "payment-protection",
        question: "How does payment protection work?",
        answer:
          "We hold payments in escrow and release them based on project milestones. This ensures both clients and developers are protected throughout the project lifecycle."
      }
    ]
  end

  defp get_comparison_features do
    [
      %Feature{name: "Project Budget Limit"},
      %Feature{name: "Algora Network Fee"},
      %Feature{name: "Bring Your Own Devs Fee"},
      %Feature{name: "Support Level"},
      %Feature{name: "Team Management"},
      %Feature{name: "Custom Contracts"},
      %Feature{name: "Analytics"}
    ]
  end

  defp has_feature?(plan, feature) do
    Enum.any?(plan.features, &(&1.name == feature.name))
  end

  defp get_testimonials do
    [
      %{
        name: "Sarah Chen",
        role: "CTO at TechCorp",
        avatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
        quote:
          "Algora has transformed how we hire developers. The quality of talent and the seamless platform experience has made scaling our team effortless."
      },
      %{
        name: "Michael Rodriguez",
        role: "Engineering Lead at StartupX",
        avatar: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e",
        quote:
          "The developers we found through Algora have become integral parts of our team. The platform's focus on open source contributors really makes a difference."
      },
      %{
        name: "Emily Thompson",
        role: "VP Engineering at ScaleUp Inc",
        avatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80",
        quote:
          "What impressed me most was how quickly we could find and onboard qualified developers. Algora's platform streamlines the entire process."
      }
    ]
  end

  def render(assigns) do
    ~H"""
    <div class="bg-gradient-to-br from-primary/5 to-muted/20">
      <Header.header />

      <main class="pt-24 xl:pt-20 2xl:pt-28">
        <div class="relative z-10 pt-8 pb-4 xl:py-16">
          <div class="mx-auto max-w-7xl px-8 text-center sm:px-6 lg:px-8">
            <div class="mx-auto max-w-3xl space-y-2 lg:max-w-none">
              <h1 class="text-4xl font-bold text-popover-foreground">
                Predictable pricing,<br class="block lg:hidden" /> designed to scale
              </h1>
              <p class="text-lg text-muted-foreground">
                Start building for free, collaborate with your team, then scale to millions of users
              </p>
            </div>
          </div>
        </div>

        <div class="mx-auto flex flex-col lg:container lg:px-16 xl:px-12">
          <div class="relative z-10 mx-auto w-full px-4 sm:px-6 lg:px-8">
            <div class="mx-auto grid max-w-md gap-4 lg:max-w-none lg:grid-cols-2 xl:grid-cols-3 xl:gap-0">
              <%= for plan <- @plans do %>
                <.pricing_card plan={plan} />
              <% end %>
            </div>
          </div>

          <div class="py-24 sm:py-32">
            <div class="mx-auto max-w-7xl px-6 lg:px-8">
              <div class="mx-auto max-w-xl text-center">
                <h2 class="mb-4 text-3xl font-bold text-popover-foreground">
                  Trusted by companies worldwide
                </h2>
                <p class="text-lg text-muted-foreground">
                  See what our customers have to say about their experience with Algora
                </p>
              </div>
              <div class="mx-auto mt-16 max-w-2xl gap-8 text-sm leading-6 text-gray-900 sm:mt-20 sm:grid-cols-2 xl:mx-0 xl:max-w-none">
                <div class="grid gap-x-12 gap-y-8 sm:grid-cols-7">
                  <div class="col-span-3">
                    <div class="relative flex aspect-square w-full items-center justify-center overflow-hidden rounded-2xl bg-gray-800">
                      <iframe
                        src="https://www.youtube.com/embed/xObOGcUdtY0?si=mrHBcTn-Nzj4_okq"
                        title="YouTube video player"
                        frameborder="0"
                        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                        referrerpolicy="strict-origin-when-cross-origin"
                        allowfullscreen
                        width="100%"
                        height="100%"
                      >
                      </iframe>
                    </div>
                  </div>
                  <div class="col-span-4">
                    <h3 class="text-3xl font-display font-bold text-success">
                      $15,000 Bounty: Delighted by the Results
                    </h3>
                    <div class="relative text-base">
                      <svg
                        viewBox="0 0 162 128"
                        fill="none"
                        aria-hidden="true"
                        class="absolute -top-12 left-0 -z-10 h-32 stroke-white/25"
                      >
                        <path
                          id="b56e9dab-6ccb-4d32-ad02-6b4bb5d9bbeb"
                          d="M65.5697 118.507L65.8918 118.89C68.9503 116.314 71.367 113.253 73.1386 109.71C74.9162 106.155 75.8027 102.28 75.8027 98.0919C75.8027 94.237 75.16 90.6155 73.8708 87.2314C72.5851 83.8565 70.8137 80.9533 68.553 78.5292C66.4529 76.1079 63.9476 74.2482 61.0407 72.9536C58.2795 71.4949 55.276 70.767 52.0386 70.767C48.9935 70.767 46.4686 71.1668 44.4872 71.9924L44.4799 71.9955L44.4726 71.9988C42.7101 72.7999 41.1035 73.6831 39.6544 74.6492C38.2407 75.5916 36.8279 76.455 35.4159 77.2394L35.4047 77.2457L35.3938 77.2525C34.2318 77.9787 32.6713 78.3634 30.6736 78.3634C29.0405 78.3634 27.5131 77.2868 26.1274 74.8257C24.7483 72.2185 24.0519 69.2166 24.0519 65.8071C24.0519 60.0311 25.3782 54.4081 28.0373 48.9335C30.703 43.4454 34.3114 38.345 38.8667 33.6325C43.5812 28.761 49.0045 24.5159 55.1389 20.8979C60.1667 18.0071 65.4966 15.6179 71.1291 13.7305C73.8626 12.8145 75.8027 10.2968 75.8027 7.38572C75.8027 3.6497 72.6341 0.62247 68.8814 1.1527C61.1635 2.2432 53.7398 4.41426 46.6119 7.66522C37.5369 11.6459 29.5729 17.0612 22.7236 23.9105C16.0322 30.6019 10.618 38.4859 6.47981 47.558L6.47976 47.558L6.47682 47.5647C2.4901 56.6544 0.5 66.6148 0.5 77.4391C0.5 84.2996 1.61702 90.7679 3.85425 96.8404L3.8558 96.8445C6.08991 102.749 9.12394 108.02 12.959 112.654L12.959 112.654L12.9646 112.661C16.8027 117.138 21.2829 120.739 26.4034 123.459L26.4033 123.459L26.4144 123.465C31.5505 126.033 37.0873 127.316 43.0178 127.316C47.5035 127.316 51.6783 126.595 55.5376 125.148L55.5376 125.148L55.5477 125.144C59.5516 123.542 63.0052 121.456 65.9019 118.881L65.5697 118.507Z"
                        >
                        </path>
                        <use href="#b56e9dab-6ccb-4d32-ad02-6b4bb5d9bbeb" x="86"></use>
                      </svg>
                      <div class="font-medium text-white whitespace-pre-line">
                        We've used Algora extensively at Golem Cloud for our hiring needs and what I have found actually over the course of a few decades of hiring people is that many times someone who is very active in open-source development, these types of engineers often make fantastic additions to a team.

                        Through our $15,000 bounty, we got hundreds of GitHub stars, more than 100 new users on our Discord, and some really fantastic Rust engineers.

                        The bounty system helps us assess real-world skills instead of just technical challenge problems. It's a great way to find talented developers who deeply understand how your system works.
                      </div>
                    </div>
                    <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-8">
                      <div class="flex items-center gap-4">
                        <span class="relative flex h-12 w-12 shrink-0 items-center overflow-hidden rounded-full">
                          <img
                            alt="John A. De Goes"
                            loading="lazy"
                            decoding="async"
                            data-nimg="fill"
                            class="aspect-square h-full w-full"
                            sizes="100vw"
                            src="https://pbs.twimg.com/profile_images/1771489509798236160/jGsCqm25_400x400.jpg"
                            style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                          />
                        </span>
                        <div>
                          <div class="text-base font-medium text-gray-100">John A. De Goes</div>
                          <div class="text-sm text-gray-300">Founder & CEO</div>
                        </div>
                      </div>
                      <div class="flex items-center gap-4">
                        <a
                          class="relative flex h-12 w-12 shrink-0 items-center overflow-hidden rounded-xl"
                          href="https://console.algora.io/org/golemcloud"
                        >
                          <img
                            alt="Golem Cloud"
                            loading="lazy"
                            decoding="async"
                            data-nimg="fill"
                            class="aspect-square h-full w-full"
                            sizes="100vw"
                            src="https://avatars.githubusercontent.com/u/133607167?s=200&v=4"
                            style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                          />
                        </a>
                        <div>
                          <a
                            class="text-base font-medium text-gray-100"
                            href="https://console.algora.io/org/golemcloud"
                          >
                            Golem Cloud
                          </a>
                          <a
                            class="block text-sm text-gray-300 hover:text-white"
                            target="_blank"
                            rel="noopener"
                            href="https://golem.cloud"
                          >
                            golem.cloud
                          </a>
                        </div>
                      </div>
                      <div class="flex items-center gap-4">
                        <a
                          class="relative flex h-12 w-12 shrink-0 items-center overflow-hidden rounded-xl"
                          href="https://console.algora.io/org/zio"
                        >
                          <img
                            alt="Ziverge"
                            loading="lazy"
                            decoding="async"
                            data-nimg="fill"
                            class="aspect-square h-full w-full"
                            sizes="100vw"
                            src="https://avatars.githubusercontent.com/u/58878508?s=200&v=4"
                            style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                          />
                        </a>
                        <div>
                          <a
                            class="text-base font-medium text-gray-100"
                            href="https://console.algora.io/org/zio"
                          >
                            Ziverge
                          </a>
                          <a
                            class="block text-sm text-gray-300 hover:text-white"
                            target="_blank"
                            rel="noopener"
                            href="https://ziverge.com"
                          >
                            ziverge.com
                          </a>
                        </div>
                      </div>
                    </div>
                    <dl class="flex flex-wrap items-center gap-x-12 gap-y-4 pt-8 xl:flex-nowrap">
                      <div class="flex flex-col-reverse">
                        <dt class="text-base text-gray-300">Total awarded</dt>
                        <dd class="font-display text-2xl font-semibold tracking-tight text-white">
                          $103,950
                        </dd>
                      </div>
                      <div class="flex flex-col-reverse">
                        <dt class="text-base text-gray-300">Bounties completed</dt>
                        <dd class="font-display text-2xl font-semibold tracking-tight text-white">
                          359
                        </dd>
                      </div>
                      <div class="flex flex-col-reverse">
                        <dt class="text-base text-gray-300">Contributors rewarded</dt>
                        <dd class="font-display text-2xl font-semibold tracking-tight text-white">
                          82
                        </dd>
                      </div>
                    </dl>
                  </div>
                </div>
              </div>
              <div class="mx-auto mt-24 max-w-2xl gap-8 text-sm leading-6 text-gray-900 sm:mt-30 sm:grid-cols-2 xl:mx-0 xl:max-w-none">
                <div class="grid gap-x-12 gap-y-8 sm:grid-cols-7">
                  <div class="col-span-3">
                    <h3 class="text-3xl font-display font-bold text-success">
                      From Bounty Contributor<br />To Full-Time Engineer
                    </h3>
                    <div class="relative text-base">
                      <svg
                        viewBox="0 0 162 128"
                        fill="none"
                        aria-hidden="true"
                        class="absolute -top-12 left-0 -z-10 h-32 stroke-white/25"
                      >
                        <path
                          id="b56e9dab-6ccb-4d32-ad02-6b4bb5d9bbeb"
                          d="M65.5697 118.507L65.8918 118.89C68.9503 116.314 71.367 113.253 73.1386 109.71C74.9162 106.155 75.8027 102.28 75.8027 98.0919C75.8027 94.237 75.16 90.6155 73.8708 87.2314C72.5851 83.8565 70.8137 80.9533 68.553 78.5292C66.4529 76.1079 63.9476 74.2482 61.0407 72.9536C58.2795 71.4949 55.276 70.767 52.0386 70.767C48.9935 70.767 46.4686 71.1668 44.4872 71.9924L44.4799 71.9955L44.4726 71.9988C42.7101 72.7999 41.1035 73.6831 39.6544 74.6492C38.2407 75.5916 36.8279 76.455 35.4159 77.2394L35.4047 77.2457L35.3938 77.2525C34.2318 77.9787 32.6713 78.3634 30.6736 78.3634C29.0405 78.3634 27.5131 77.2868 26.1274 74.8257C24.7483 72.2185 24.0519 69.2166 24.0519 65.8071C24.0519 60.0311 25.3782 54.4081 28.0373 48.9335C30.703 43.4454 34.3114 38.345 38.8667 33.6325C43.5812 28.761 49.0045 24.5159 55.1389 20.8979C60.1667 18.0071 65.4966 15.6179 71.1291 13.7305C73.8626 12.8145 75.8027 10.2968 75.8027 7.38572C75.8027 3.6497 72.6341 0.62247 68.8814 1.1527C61.1635 2.2432 53.7398 4.41426 46.6119 7.66522C37.5369 11.6459 29.5729 17.0612 22.7236 23.9105C16.0322 30.6019 10.618 38.4859 6.47981 47.558L6.47976 47.558L6.47682 47.5647C2.4901 56.6544 0.5 66.6148 0.5 77.4391C0.5 84.2996 1.61702 90.7679 3.85425 96.8404L3.8558 96.8445C6.08991 102.749 9.12394 108.02 12.959 112.654L12.959 112.654L12.9646 112.661C16.8027 117.138 21.2829 120.739 26.4034 123.459L26.4033 123.459L26.4144 123.465C31.5505 126.033 37.0873 127.316 43.0178 127.316C47.5035 127.316 51.6783 126.595 55.5376 125.148L55.5376 125.148L55.5477 125.144C59.5516 123.542 63.0052 121.456 65.9019 118.881L65.5697 118.507Z"
                        >
                        </path>
                        <use href="#b56e9dab-6ccb-4d32-ad02-6b4bb5d9bbeb" x="86"></use>
                      </svg>
                      <div class="font-medium text-white whitespace-pre-line">
                        We were doing bounties on Algora, and this one developer Nick kept solving them. His personality really came through in the GitHub issues and code. We ended up hiring him from that, and it was the easiest hire because we already knew he was great from his contributions.

                        That's one massive advantage open source companies have versus closed source. When I talk to young people asking for advice, I specifically tell them to go on Algora and find issues there. You get to show people your work, plus you can point to your contributions as proof of your abilities, and you make money in the meantime.
                      </div>
                    </div>
                    <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-8">
                      <div class="flex items-center gap-4">
                        <span class="relative flex h-12 w-12 shrink-0 items-center overflow-hidden rounded-full">
                          <img
                            alt="Eric Allam"
                            loading="lazy"
                            decoding="async"
                            data-nimg="fill"
                            class="aspect-square h-full w-full"
                            sizes="100vw"
                            src="https://pbs.twimg.com/profile_images/1584912680007204865/a_GK3tMi_400x400.jpg"
                            style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                          />
                        </span>
                        <div>
                          <div class="text-base font-medium text-gray-100">Eric Allam</div>
                          <div class="text-sm text-gray-300">Founder & CTO</div>
                        </div>
                      </div>
                      <div class="flex items-center gap-4">
                        <a
                          class="relative flex h-12 w-12 shrink-0 items-center overflow-hidden rounded-xl"
                          href="https://console.algora.io/org/triggerdotdev"
                        >
                          <img
                            alt="Trigger.dev"
                            loading="lazy"
                            decoding="async"
                            data-nimg="fill"
                            class="aspect-square h-full w-full"
                            sizes="100vw"
                            src="https://avatars.githubusercontent.com/u/95297378?s=200&v=4"
                            style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                          />
                        </a>
                        <div>
                          <a
                            class="text-base font-medium text-gray-100"
                            href="https://console.algora.io/org/triggerdotdev"
                          >
                            Trigger.dev (YC W23)
                          </a>
                          <a
                            class="block text-sm text-gray-300 hover:text-white"
                            target="_blank"
                            rel="noopener"
                            href="https://trigger.dev"
                          >
                            trigger.dev
                          </a>
                        </div>
                      </div>
                    </div>
                    <dl class="flex flex-wrap items-center gap-x-6 gap-y-4 pt-8 xl:flex-nowrap">
                      <div class="flex flex-col-reverse">
                        <dt class="text-base text-gray-300">Total awarded</dt>
                        <dd class="font-display text-2xl font-semibold tracking-tight text-white">
                          $9,920
                        </dd>
                      </div>
                      <div class="flex flex-col-reverse">
                        <dt class="text-base text-gray-300">Bounties completed</dt>
                        <dd class="font-display text-2xl font-semibold tracking-tight text-white">
                          106
                        </dd>
                      </div>
                      <div class="flex flex-col-reverse">
                        <dt class="text-base text-gray-300">Contributors rewarded</dt>
                        <dd class="font-display text-2xl font-semibold tracking-tight text-white">
                          35
                        </dd>
                      </div>
                    </dl>
                  </div>
                  <div class="col-span-4">
                    <div class="relative flex aspect-video w-full items-center justify-center overflow-hidden rounded-2xl bg-gray-800">
                      <iframe
                        src="https://www.youtube.com/embed/FXQVD02rfg8?si=rt3r_8-aFt2ZKla8"
                        title="YouTube video player"
                        frameborder="0"
                        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                        referrerpolicy="strict-origin-when-cross-origin"
                        allowfullscreen
                        width="100%"
                        height="100%"
                      >
                      </iframe>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="container mx-auto py-16">
            <h2 class="mb-12 text-center text-3xl font-bold text-popover-foreground">
              Frequently asked questions
            </h2>
            <div class="mx-auto max-w-3xl space-y-4">
              <%= for item <- @faq_items do %>
                <div class="rounded-lg border">
                  <button
                    phx-click="toggle_faq"
                    phx-value-id={item.id}
                    class="flex w-full items-center justify-between p-4 text-left"
                  >
                    <span class="font-medium text-foreground">{item.question}</span>
                    <.icon
                      name="tabler-chevron-down"
                      class={
                        classes([
                          "h-5 w-5 text-muted-foreground transition-transform duration-200",
                          @active_faq == item.id && "rotate-180 transform"
                        ])
                      }
                    />
                  </button>
                  <%= if @active_faq == item.id do %>
                    <div class="p-4 pt-0 text-muted-foreground">
                      {item.answer}
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <div class="border-t bg-card py-32 text-center">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="mb-8 text-3xl font-bold text-card-foreground">
              <span class="text-muted-foreground">The open source</span>
              <span class="block sm:inline">UpWork alternative.</span>
            </h2>
            <div class="flex justify-center gap-4">
              <.link
                navigate="/signup"
                class="inline-flex h-10 items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50"
              >
                Start your project
              </.link>
              <.link
                navigate="/contact/sales"
                class="inline-flex h-10 items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50"
              >
                Request a demo
              </.link>
            </div>
          </div>
        </div>
      </main>

      <Footer.footer />
    </div>
    """
  end
end
