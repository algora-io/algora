defmodule AlgoraWeb.PricingLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.PSP.ConnectCountries
  alias AlgoraWeb.Components.Footer
  alias AlgoraWeb.Components.Header

  defmodule Plan do
    @moduledoc false
    defstruct [
      :id,
      :name,
      :description,
      :price,
      :cta_text,
      :cta_url,
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

  defmodule FaqItem do
    @moduledoc false
    defstruct [:id, :question, :answer]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pt-24 xl:pt-20 2xl:pt-28">
      <%= if @screenshot? do %>
        <div class="-mt-20" />
      <% else %>
        <Header.header />
      <% end %>

      <div class="mx-auto flex flex-col lg:container lg:px-16 xl:px-12"></div>

      <section class="bg-background pb-16 sm:pb-24">
        <div class="mx-auto px-6 lg:px-8">
          <div class="relative z-10 pb-4 xl:py-16">
            <div class="mx-auto max-w-7xl sm:text-center">
              <div class="mx-auto max-w-3xl space-y-2 lg:max-w-none">
                <h1 class="text-2xl sm:text-4xl font-bold text-popover-foreground">
                  Simple, transparent pricing
                </h1>
                <p class="text-sm sm:text-lg text-muted-foreground">
                  For individuals, OSS communities, and open/closed source companies
                </p>
              </div>
            </div>
          </div>

          <div class="mx-auto lg:max-w-[95rem] mb-8 mt-8">
            <div class="flex items-start gap-4">
              <div class="flex-1">
                <h2 class="text-2xl font-semibold text-foreground mb-2">
                  <div class="flex items-center gap-2">
                    <.icon name="tabler-wallet" class="h-6 w-6 text-emerald-400" /> Payments
                  </div>
                </h2>
                <p class="text-base text-foreground-light">
                  Fund GitHub issues with USD rewards and pay when work is merged. Set up contracts for ongoing development work. Simple, outcome-based payments.
                </p>
              </div>
            </div>
          </div>

          <div class="mx-auto grid grid-cols-1 gap-4 lg:gap-8 lg:max-w-[95rem] lg:grid-cols-2">
            <%= for plan <- @plans1 do %>
              <.pricing_card1 plan={plan} plans={@plans1} />
            <% end %>
          </div>

          <div class="mx-auto lg:max-w-[95rem] mt-16 mb-8">
            <div class="flex items-start gap-4">
              <div class="flex-1">
                <h2 class="text-2xl font-semibold text-foreground mb-2">
                  <div class="flex items-center gap-2">
                    <.icon name="tabler-building-store" class="h-6 w-6 text-purple-400" /> Platform
                  </div>
                </h2>
                <p class="text-base text-foreground-light">
                  Connect with top open source talent, increase project visibility, and hire proven contributors
                </p>
              </div>
            </div>
          </div>
          <div class="mx-auto grid grid-cols-1 gap-4 lg:max-w-[95rem] xl:gap-0">
            <%= for plan <- @plans2 do %>
              <.pricing_card2 plan={plan} plans={@plans2} />
            <% end %>
          </div>
        </div>
      </section>

      <section class="bg-black border-t py-16 sm:py-24">
        <div class="mx-auto max-w-7xl px-6 lg:px-8">
          <h2 class="mb-12 text-center text-3xl font-bold text-popover-foreground">
            Frequently asked questions
          </h2>
          <div class="mx-auto max-w-3xl space-y-4">
            <%= for item <- @faq_items do %>
              <div class="rounded-lg border">
                <button
                  phx-click={
                    %JS{}
                    |> JS.toggle(to: "#faq-#{item.id}")
                    |> JS.toggle_class("rotate-180", to: "#icon-#{item.id}")
                  }
                  class="flex w-full justify-between p-4 text-left"
                >
                  <span class="font-medium text-foreground">{item.question}</span>
                  <.icon
                    id={"icon-#{item.id}"}
                    name="tabler-chevron-down"
                    class="h-5 w-5 shrink-0 text-muted-foreground transition-transform duration-200"
                  />
                </button>
                <div id={"faq-#{item.id}"} class="hidden p-4 pt-0 text-muted-foreground">
                  {Phoenix.HTML.raw(item.answer)}
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </section>

      <section class="bg-background border-t py-16 sm:py-24">
        <div class="mx-auto max-w-7xl px-6 lg:px-8">
          <h2 class="mb-8 text-3xl font-bold text-card-foreground text-center">
            <span class="text-muted-foreground">The open source</span>
            <span class="block sm:inline">Upwork alternative.</span>
          </h2>
          <div class="flex justify-center gap-4">
            <.button navigate="/onboarding/org">
              Start your project
            </.button>
            <.button href={AlgoraWeb.Constants.get(:calendar_url)} variant="secondary">
              Request a demo
            </.button>
          </div>
          <.features_bento />
        </div>
      </section>

      <div class="bg-black">
        <Footer.footer />
      </div>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    socket =
      assign(socket,
        screenshot?: not is_nil(params["screenshot"]),
        page_title: "Pricing",
        plans1: get_plans1(),
        plans2: get_plans2(),
        faq_items: get_faq_items(),
        active_faq: nil
      )

    {:ok, socket}
  end

  defp pricing_card1(assigns) do
    ~H"""
    <.link
      href={@plan.cta_url}
      class="group border ring-1 ring-transparent hover:ring-emerald-400 rounded-xl overflow-hidden"
    >
      <div class={[
        "bg-card/75 flex flex-col h-full p-4 sm:flex-row sm:justify-between rounded-xl border-t-4 sm:border-t-0 sm:border-l-4 border-emerald-400 group-hover:border-emerald-300 group-hover:sm:border-l-8 transition-all cursor-pointer",
        @plan.popular && "border-foreground-muted !border-2 !rounded-xl xl:-my-8",
        "divide-y sm:divide-y-0 sm:divide-x sm:divide-default"
      ]}>
        <div class="flex-1 p-4 sm:px-6">
          <div class="flex items-center gap-2">
            <div class="flex items-center gap-2 pb-2">
              <h3 class="flex items-center gap-4 text-2xl font-semibold text-foreground">
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
          <div class="flex items-center justify-between">
            <div class="border-default flex items-baseline text-5xl font-normal text-foreground lg:text-4xl xl:text-4xl">
              <div class="flex flex-col gap-1 w-full">
                <%= case @plan.id do %>
                  <% "receive-payments" -> %>
                    <div class="flex justify-between">
                      <div class="flex items-end">
                        <p class="font-display text-4xl text-emerald-400">
                          0%
                        </p>
                        <p class="text-foreground-lighter text-sm mb-1.5 ml-2 leading-4">
                          service fee
                        </p>
                      </div>
                    </div>
                  <% "pay-developers" -> %>
                    <div class="flex justify-between">
                      <div class="flex items-end">
                        <p class="font-display text-4xl text-emerald-400">
                          9%
                        </p>
                        <p class="text-foreground-lighter text-sm mb-1.5 ml-2 leading-4">
                          service fee
                        </p>
                      </div>
                    </div>
                  <% "grow-your-team" -> %>
                    <div class="flex justify-between">
                      <div class="flex items-end">
                        <p class="font-display text-4xl">
                          Custom
                        </p>
                      </div>
                    </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
        <div class="flex-1 p-4 sm:px-6">
          <ul class="border-default text-sm text-foreground-lighter flex-1">
            <%= for feature <- @plan.features do %>
              <li class="flex flex-col py-2 first:mt-0">
                <div class="flex items-start">
                  <div class="flex w-7">
                    <.icon name="tabler-check" class="size-5 text-emerald-400" />
                  </div>
                  <span class="text-sm xl:text-base mb-0 text-foreground truncate">
                    {Phoenix.HTML.raw(feature.name)}
                  </span>
                </div>
                <%= if feature.detail do %>
                  <p class="text-foreground-lighter ml-6">{feature.detail}</p>
                <% end %>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </.link>
    """
  end

  defp pricing_card2(assigns) do
    ~H"""
    <div class="border ring-1 ring-transparent rounded-xl overflow-hidden">
      <div class={[
        "bg-card/75 flex flex-col h-full p-4 sm:flex-row sm:justify-between rounded-xl border-t-4 sm:border-t-0 sm:border-l-4 border-purple-400",
        @plan.popular && "border-foreground-muted !border-2 !rounded-xl xl:-my-8",
        "divide-y sm:divide-y-0 sm:divide-x sm:divide-default"
      ]}>
        <div class="sm:w-1/2 xl:w-1/3 p-4 pb-8 sm:pb-4 sm:px-6 flex flex-col justify-center">
          <div class="flex items-center gap-2">
            <div class="flex items-center gap-2 pb-2">
              <h3 class="flex items-center gap-4 text-2xl font-semibold text-foreground">
                {@plan.name}
              </h3>
              <%= if @plan.popular do %>
                <span class="bg-foreground-light text-[13px] rounded-md px-2 py-0.5 leading-4 text-background">
                  Most Popular
                </span>
              <% end %>
            </div>
          </div>
          <p class="text-foreground-light text-sm pt-2 2xl:pr-4">
            {@plan.description}
          </p>
          <div class="flex gap-2 pt-4">
            <.button
              navigate={@plan.cta_url}
              variant="purple"
              size="xl"
              class="drop-shadow-[0_1px_5px_#c084fc80]"
            >
              {@plan.cta_text}
            </.button>
          </div>
        </div>
        <div class="sm:w-1/2 xl:w-2/3 p-4 pt-8 sm:pt-4 sm:px-6">
          <ul class="border-default text-base text-foreground-lighter flex-1 grid grid-cols-1 xl:grid-cols-3 gap-4 xl:divide-x xl:divide-default">
            <li class="py-2 flex flex-col xl:items-center xl:justify-center">
              <div class="flex items-center xl:flex-col gap-4">
                <div class="shrink-0 flex items-center justify-center size-16 bg-purple-400/10 drop-shadow-[0_1px_5px_#c084fc80] rounded-full">
                  <.icon name="tabler-world" class="size-8 text-purple-400" />
                </div>
                <div class="flex flex-col xl:items-center xl:justify-center xl:gap-2">
                  <div class="text-2xl xl:text-3xl font-semibold font-display">Publish</div>
                  <div class="text-base xl:text-lg font-medium text-muted-foreground">
                    Bounties and contracts <span class="hidden 2xl:inline">on Algora</span>
                  </div>
                </div>
              </div>
            </li>
            <li class="py-2 flex flex-col xl:items-center xl:justify-center">
              <div class="flex items-center xl:flex-col gap-4">
                <div class="shrink-0 flex items-center justify-center size-16 bg-purple-400/10 drop-shadow-[0_1px_5px_#c084fc80] rounded-full">
                  <.icon name="tabler-bolt" class="size-8 text-purple-400" />
                </div>
                <div class="flex flex-col xl:items-center xl:justify-center xl:gap-2">
                  <div class="text-2xl xl:text-3xl font-semibold font-display">Match</div>
                  <div class="text-base xl:text-lg font-medium text-muted-foreground">
                    Proven Algora experts
                  </div>
                </div>
              </div>
            </li>
            <li class="py-2 flex flex-col xl:items-center xl:justify-center">
              <div class="flex items-center xl:flex-col gap-4">
                <div class="shrink-0 flex items-center justify-center size-16 bg-purple-400/10 drop-shadow-[0_1px_5px_#c084fc80] rounded-full">
                  <.icon name="tabler-briefcase" class="size-8 text-purple-400" />
                </div>
                <div class="flex flex-col xl:items-center xl:justify-center xl:gap-2">
                  <div class="text-2xl xl:text-3xl font-semibold font-display">Hire</div>
                  <div class="text-base xl:text-lg font-medium text-muted-foreground">
                    Top 1% OSS engineers
                  </div>
                </div>
              </div>
            </li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  defp get_plans1 do
    [
      %Plan{
        id: "receive-payments",
        name: "Receive payments",
        description: "Get paid for your open source work",
        price: "100%",
        cta_text: "Start earning",
        cta_url: "/onboarding/dev",
        popular: false,
        features: [
          %Feature{name: "Keep 100% of your earnings"},
          %Feature{name: "Available in #{ConnectCountries.count()} countries"},
          %Feature{name: "Fast payouts in 2-7 days"}
        ]
      },
      %Plan{
        id: "pay-developers",
        name: "Pay developers",
        description: "Reward contributors with Algora",
        price: nil,
        cta_text: "Create bounties",
        cta_url: "/onboarding/org",
        popular: false,
        features: [
          %Feature{name: "GitHub bounties and tips"},
          %Feature{name: "Contract work (fixed/hourly)"},
          %Feature{name: "Invoices, payouts, compliance, 1099s"}
        ]
      }
    ]
  end

  defp get_plans2 do
    [
      %Plan{
        id: "grow-your-team",
        name: "Growing your team?",
        description: "You're in the right place.",
        price: "Custom",
        cta_text: "Contact us",
        cta_url: AlgoraWeb.Constants.get(:calendar_url),
        popular: false,
        features: []
      }
    ]
  end

  defp get_faq_items do
    [
      %FaqItem{
        id: "platform-fee",
        question: "How do the platform fees work?",
        answer:
          "For organizations, we charge a 9% fee on bounties when they are rewarded. For individual contributors, you receive 100% of the bounty amount with no fees deducted."
      },
      %FaqItem{
        id: "payment-methods",
        question: "What payment methods do you support?",
        answer:
          ~s(We support payments via Stripe for funding bounties. Contributors can receive payments directly to their bank accounts in <a href="https://docs.algora.io/bounties/payments#supported-countries-regions" class="text-success hover:underline">#{ConnectCountries.count()} countries/regions</a> worldwide.)
      },
      %FaqItem{
        id: "payment-process",
        question: "How does the payment process work?",
        answer:
          "There's no upfront payment required for bounties. Organizations can either pay manually after merging pull requests, or save their card with Stripe to enable auto-pay on merge. Manual payments are processed through a secure Stripe hosted checkout page."
      },
      %FaqItem{
        id: "invoices-receipts",
        question: "Do you provide invoices and receipts?",
        answer:
          "Yes, users receive an invoice and receipt after each bounty payment. These documents are automatically generated and delivered to your email."
      },
      %FaqItem{
        id: "tax-forms",
        question: "How are tax forms handled?",
        answer:
          "We partner with Stripe to file and deliver 1099 forms for your US-based freelancers, simplifying tax compliance for organizations working with US contributors."
      },
      %FaqItem{
        id: "payout-time",
        question: "How long do payouts take?",
        answer:
          "Payout timing varies by country, typically ranging from 2-7 business days after a bounty is awarded. Initial payouts for new accounts may take 7-14 days. The exact timing depends on your location, banking system, and account history with Stripe, our payment processor."
      },
      %FaqItem{
        id: "minimum-bounty",
        question: "Is there a minimum bounty amount?",
        answer:
          "There's no strict minimum bounty amount. However, bounties with higher values tend to attract more attention and faster solutions from contributors."
      },
      %FaqItem{
        id: "enterprise-options",
        question: "Do you offer custom enterprise plans?",
        answer:
          ~s(Yes, for larger organizations with specific needs, we offer custom enterprise plans with additional features, dedicated support, and volume-based pricing. Please <a href="https://cal.com/ioannisflo" class="text-success hover:underline">schedule a call with a founder</a> to discuss your requirements.)
      },
      %FaqItem{
        id: "supported-countries",
        question: "Which countries are supported for contributors?",
        answer:
          ~s(We support contributors from #{ConnectCountries.count()} countries/regions worldwide. You can receive payments regardless of your location as long as you have a bank account in one of our supported countries. See the <a href="https://docs.algora.io/bounties/payments#supported-countries-regions" class="text-success hover:underline">full list of supported countries</a>.)
      }
    ]
  end

  defp features_bento(assigns) do
    ~H"""
    <div class="mt-10 grid grid-cols-1 gap-4 sm:mt-16 lg:grid-cols-[repeat(14,_minmax(0,_1fr))]">
      <div class="flex p-px lg:col-span-8">
        <div class="w-full overflow-hidden rounded sm:rounded-lg bg-card ring-1 ring-white/15 lg:rounded-tl-[2rem]">
          <img
            class="object-cover object-left"
            loading="lazy"
            src={~p"/images/screenshots/bounty.png"}
            alt=""
          />
          <div class="p-4 sm:p-6">
            <h3 class="text-sm/4 font-semibold text-gray-400">Bounties</h3>
            <p class="mt-2 text-lg font-medium tracking-tight text-white">
              Fund Issues
            </p>
            <p class="mt-2 text-sm/6 text-gray-400">
              Create bounties on your issues to incentivize solutions and attract talented contributors
            </p>
          </div>
        </div>
      </div>
      <div class="flex p-px lg:col-span-6">
        <div class="w-full overflow-hidden rounded sm:rounded-lg bg-card ring-1 ring-white/15 lg:rounded-tr-[2rem]">
          <img class="object-cover" loading="lazy" src={~p"/images/screenshots/tip.png"} alt="" />
          <div class="p-4 sm:p-6">
            <h3 class="text-sm/4 font-semibold text-gray-400">Tips</h3>
            <p class="mt-2 text-lg font-medium tracking-tight text-white">
              Show Appreciation
            </p>
            <p class="mt-2 text-sm/6 text-gray-400">
              Say thanks with tips to recognize valuable contributions
            </p>
          </div>
        </div>
      </div>
      <div class="flex p-px lg:col-span-6">
        <div class="w-full overflow-hidden rounded sm:rounded-lg bg-card ring-1 ring-white/15">
          <div class="flex object-cover">
            <div class="flex h-full w-full items-center justify-center gap-x-4 p-4 pb-0 sm:gap-x-6">
              <div class="flex w-full flex-col space-y-3 sm:w-auto sm:py-9">
                <div
                  class="w-full items-center rounded-md bg-gradient-to-b from-gray-400 to-gray-800 p-px"
                  style="opacity: 1; transform: translateX(0.2px) translateZ(0px);"
                >
                  <div class="flex items-center space-x-2 rounded-md bg-gradient-to-b from-gray-800 to-gray-900 p-2">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                      class="h-4 w-4 text-success-500"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
                        clip-rule="evenodd"
                      >
                      </path>
                    </svg>
                    <p class="pb-8 font-sans text-sm text-gray-200 last:pb-0">
                      Merged pull request
                    </p>
                  </div>
                </div>
                <div
                  class="w-full items-center rounded-md bg-gradient-to-b from-gray-400 to-gray-800 p-px"
                  style="opacity: 1; transform: translateX(0.2px) translateZ(0px);"
                >
                  <div class="flex items-center space-x-2 rounded-md bg-gradient-to-b from-gray-800 to-gray-900 p-2">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                      class="h-4 w-4 text-success-500"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
                        clip-rule="evenodd"
                      >
                      </path>
                    </svg>
                    <p class="pb-8 font-sans text-sm text-gray-200 last:pb-0">
                      Completed payment
                    </p>
                  </div>
                </div>
                <div
                  class="w-full items-center rounded-md bg-gradient-to-b from-gray-400 to-gray-800 p-px"
                  style="opacity: 0.7; transform: translateX(0.357815px) translateZ(0px);"
                >
                  <div class="flex items-center space-x-2 rounded-md bg-gradient-to-b from-gray-800 to-gray-900 p-2">
                    <svg
                      width="20"
                      height="20"
                      viewBox="0 0 20 20"
                      fill="none"
                      xmlns="http://www.w3.org/2000/svg"
                      class="h-4 w-4 animate-spin motion-reduce:hidden"
                    >
                      <rect
                        x="2"
                        y="2"
                        width="16"
                        height="16"
                        rx="8"
                        stroke="rgba(59, 130, 246, 0.4)"
                        stroke-width="3"
                      >
                      </rect>
                      <path
                        d="M10 18C5.58172 18 2 14.4183 2 10C2 5.58172 5.58172 2 10 2"
                        stroke="rgba(59, 130, 246)"
                        stroke-width="3"
                        stroke-linecap="round"
                      >
                      </path>
                    </svg>
                    <p class="pb-8 font-sans text-sm text-gray-400 last:pb-0">
                      Transferring funds to contributor
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="p-4 sm:p-6">
            <h3 class="text-sm/4 font-semibold text-gray-400">Payments</h3>
            <p class="mt-2 text-lg font-medium tracking-tight text-white">
              Pay When Merged
            </p>
            <p class="mt-2 text-sm/6 text-gray-400">
              Set up auto-pay to instantly reward contributors as their PRs are merged
            </p>
          </div>
        </div>
      </div>
      <div class="flex p-px lg:col-span-8">
        <div class="w-full overflow-hidden rounded sm:rounded-lg bg-card ring-1 ring-white/15">
          <img
            class="object-cover object-left"
            loading="lazy"
            src={~p"/images/screenshots/bounties.png"}
            alt=""
          />
          <div class="p-4 sm:p-6">
            <h3 class="text-sm/4 font-semibold text-gray-400">Pooling</h3>
            <p class="mt-2 text-lg font-medium tracking-tight text-white">
              Fund Together
            </p>
            <p class="mt-2 text-sm/6 text-gray-400">
              Companies and individuals can pool their money together to fund important issues
            </p>
          </div>
        </div>
      </div>
      <div class="flex p-px lg:col-span-5">
        <div class="w-full overflow-hidden rounded sm:rounded-lg bg-card ring-1 ring-white/15 lg:rounded-bl-[2rem]">
          <img
            class="object-cover object-left"
            loading="lazy"
            src={~p"/images/screenshots/payout-account.png"}
            alt=""
          />
          <div class="p-4 sm:p-6">
            <h3 class="text-sm/4 font-semibold text-gray-400">Payouts</h3>
            <p class="mt-2 text-lg font-medium tracking-tight text-white">
              Fast, Global Payouts
            </p>
            <p class="mt-2 text-sm/6 text-gray-400">
              Receive payments directly to your bank account from all around the world
              <.link
                href="https://docs.algora.io/bounties/payments#supported-countries-regions"
                class="font-medium text-foreground"
              >
                ({ConnectCountries.count()} countries/regions supported)
              </.link>
            </p>
          </div>
        </div>
      </div>
      <div class="flex p-px lg:col-span-9">
        <div class="w-full overflow-hidden rounded sm:rounded-lg bg-card ring-1 ring-white/15 lg:rounded-br-[2rem]">
          <img class="object-cover" loading="lazy" src={~p"/images/screenshots/contract.png"} alt="" />
          <div class="p-4 sm:p-6">
            <h3 class="text-sm/4 font-semibold text-gray-400">Contracts</h3>
            <p class="mt-2 text-lg font-medium tracking-tight text-white">
              Flexible Engagement
            </p>
            <p class="mt-2 text-sm/6 text-gray-400">
              Set hourly rates, weekly hours, and payment schedules for ongoing development work. Track progress and manage payments all in one place.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
