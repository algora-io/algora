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
                  Pricing for every team
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

          <div class="mx-auto lg:max-w-[95rem] mb-8 mt-8 lg:mt-16">
            <div class="flex items-start gap-4">
              <div class="flex-1">
                <h2 class="text-2xl font-semibold text-foreground mb-2">
                  <div class="flex items-center gap-2">
                    <.icon name="tabler-users" class="h-6 w-6 text-purple-400" /> Matching & Hiring
                  </div>
                </h2>
                <p class="text-base text-foreground-light">
                  Find and hire top 1% OSS engineers with confidence
                </p>
              </div>
            </div>
          </div>
          <div class="mx-auto grid grid-cols-1 gap-4 lg:gap-8 lg:max-w-[95rem] lg:grid-cols-2">
            <.link
              href={AlgoraWeb.Constants.get(:calendar_url)}
              class="group border ring-1 ring-transparent hover:ring-purple-400 rounded-xl overflow-hidden"
            >
              <div class="bg-card/75 flex flex-col h-full p-4 rounded-xl border-t-4 sm:border-t-0 sm:border-l-4 border-purple-400 group-hover:border-purple-300 group-hover:sm:border-l-8 transition-all cursor-pointer divide-y sm:divide-y-0">
                <div class="p-4 sm:px-6 group-hover:sm:-ml-[4px] transition-all">
                  <div class="mb-4 flex flex-col sm:flex-row sm:justify-between gap-4">
                    <h3 class="flex items-center gap-4 text-2xl font-semibold text-foreground">
                      Talent Matching
                    </h3>
                    <.button variant="purple" size="lg" class="font-display text-lg mr-auto sm:mr-0">
                      Contact us
                    </.button>
                  </div>
                  <p class="text-foreground-light text-sm sm:text-base 2xl:pr-4">
                    Connect with top engineers for your project
                  </p>
                </div>
                <div class="p-4 sm:pt-2 sm:px-6 group-hover:sm:-ml-[4px] transition-all">
                  <ul class="border-default text-sm text-foreground-lighter flex-1 space-y-3">
                    <li class="flex flex-col">
                      <div class="flex items-start">
                        <div class="flex w-7 shrink-0">
                          <.icon name="tabler-check" class="size-5 text-purple-400" />
                        </div>
                        <span class="text-sm xl:text-base mb-0 text-foreground">
                          Smart matching based on:
                        </span>
                      </div>
                      <ul class="ml-7 mt-2 space-y-2">
                        <li class="flex items-center">
                          <div class="flex w-7 shrink-0 items-center justify-center">
                            <.icon name="tabler-circle-filled" class="size-1.5 text-purple-300" />
                          </div>
                          <span class="text-sm text-foreground-light">
                            Tech stack and skills
                          </span>
                        </li>
                        <li class="flex items-center">
                          <div class="flex w-7 shrink-0 items-center justify-center">
                            <.icon name="tabler-circle-filled" class="size-1.5 text-purple-300" />
                          </div>
                          <span class="text-sm text-foreground-light">
                            Location and budget
                          </span>
                        </li>
                        <li class="flex items-center">
                          <div class="flex w-7 shrink-0 items-center justify-center">
                            <.icon name="tabler-circle-filled" class="size-1.5 text-purple-300" />
                          </div>
                          <span class="text-sm text-foreground-light">
                            Granular GitHub <span class="hidden md:inline">OSS</span>
                            contribution data
                          </span>
                        </li>
                      </ul>
                    </li>
                    <li class="flex flex-col">
                      <div class="flex items-start">
                        <div class="flex w-7 shrink-0">
                          <.icon name="tabler-check" class="size-5 text-purple-400" />
                        </div>
                        <span class="text-sm xl:text-base mb-0 text-foreground">
                          Open source: GitHub issue hypermatch
                        </span>
                      </div>
                    </li>
                    <li class="flex flex-col">
                      <div class="flex items-start">
                        <div class="flex w-7 shrink-0">
                          <.icon name="tabler-check" class="size-5 text-purple-400" />
                        </div>
                        <span class="text-sm xl:text-base mb-0 text-foreground">
                          Closed source: Project spec hypermatch
                        </span>
                      </div>
                    </li>
                  </ul>

                  <div class="mt-6 pt-6 border-t">
                    <figure class="relative">
                      <blockquote class="text-lg font-medium text-foreground/90">
                        <p>
                          "I've used Algora in the past for bounties, and recently used them to hire a contract engineer. Every time the process has yield fantastic results, with high quality code and fast turn arounds. I'm a big fan."
                        </p>
                      </blockquote>
                      <figcaption class="mt-4 flex items-center gap-x-4">
                        <img
                          src="/images/people/drew-baker.jpeg"
                          alt="Drew Baker"
                          class="h-16 w-16 rounded-full object-cover bg-gray-800"
                          loading="lazy"
                        />
                        <div class="text-sm">
                          <div class="text-base font-semibold text-foreground">Drew Baker</div>
                          <div class="text-foreground/90 font-medium">Technical Partner</div>
                          <div class="text-muted-foreground font-medium">Funkhaus</div>
                        </div>
                      </figcaption>
                    </figure>
                  </div>
                </div>
              </div>
            </.link>

            <.link
              href={AlgoraWeb.Constants.get(:calendar_url)}
              class="group border ring-1 ring-transparent hover:ring-purple-400 rounded-xl overflow-hidden"
            >
              <div class="bg-card/75 flex flex-col h-full p-4 rounded-xl border-t-4 sm:border-t-0 sm:border-l-4 border-purple-400 group-hover:border-purple-300 group-hover:sm:border-l-8 transition-all cursor-pointer divide-y sm:divide-y-0">
                <div class="p-4 sm:px-6 group-hover:sm:-ml-[4px] transition-all">
                  <div class="mb-4 flex flex-col sm:flex-row sm:justify-between gap-4">
                    <h3 class="flex items-center gap-4 text-2xl font-semibold text-foreground">
                      Hiring Platform
                    </h3>
                    <.button variant="purple" size="lg" class="font-display text-lg mr-auto sm:mr-0">
                      Contact us
                    </.button>
                  </div>
                  <p class="text-foreground-light text-sm sm:text-base 2xl:pr-4">
                    End-to-end hiring
                  </p>
                </div>
                <div class="p-4 sm:pt-2 sm:px-6 group-hover:sm:-ml-[4px] transition-all">
                  <ul class="border-default text-sm text-foreground-lighter flex-1 space-y-3">
                    <li class="flex flex-col">
                      <div class="flex items-start">
                        <div class="flex w-7 shrink-0">
                          <.icon name="tabler-check" class="size-5 text-purple-400" />
                        </div>
                        <span class="text-sm xl:text-base mb-0 text-foreground">
                          Job board that highlights applicant's OSS contributions
                        </span>
                      </div>
                    </li>
                    <li class="flex flex-col">
                      <div class="flex items-start">
                        <div class="flex w-7 shrink-0">
                          <.icon name="tabler-check" class="size-5 text-purple-400" />
                        </div>
                        <span class="text-sm xl:text-base mb-0 text-foreground">
                          Embed 1-click apply on careers page
                        </span>
                      </div>
                    </li>
                    <li class="flex flex-col">
                      <div class="flex items-start">
                        <div class="flex w-7 shrink-0">
                          <.icon name="tabler-check" class="size-5 text-purple-400" />
                        </div>
                        <span class="text-sm xl:text-base mb-0 text-foreground">
                          Automatically screen & rank candidates
                        </span>
                      </div>
                    </li>
                    <li class="flex flex-col">
                      <div class="flex items-start">
                        <div class="flex w-7 shrink-0">
                          <.icon name="tabler-check" class="size-5 text-purple-400" />
                        </div>
                        <span class="text-sm xl:text-base mb-0 text-foreground">
                          Schedule interviews and chat in-app
                        </span>
                      </div>
                    </li>
                    <li class="flex flex-col">
                      <div class="flex items-start">
                        <div class="flex w-7 shrink-0">
                          <.icon name="tabler-check" class="size-5 text-purple-400" />
                        </div>
                        <span class="text-sm xl:text-base mb-0 text-foreground">
                          Trial with bounties and contract-to-hire
                        </span>
                      </div>
                    </li>
                    <li class="flex flex-col pt-1">
                      <div class="flex items-start">
                        <div class="flex w-7 shrink-0">
                          <.icon name="tabler-check" class="size-5 text-purple-400" />
                        </div>
                        <span class="text-sm xl:text-base mb-0 text-foreground font-medium bg-purple-500/30 px-2 py-0.5 rounded-md -mt-1">
                          Access your matches and stand out
                        </span>
                      </div>
                    </li>
                    <li class="flex flex-col pt-1">
                      <div class="flex items-start">
                        <div class="flex w-7 shrink-0">
                          <.icon name="tabler-check" class="size-5 text-purple-400" />
                        </div>
                        <span class="text-sm xl:text-base mb-0 text-foreground font-medium bg-purple-500/30 px-2 py-0.5 rounded-md -mt-1">
                          Publish jobs on Algora platform
                        </span>
                      </div>
                    </li>
                    <li class="flex flex-col pt-1">
                      <div class="flex items-start">
                        <div class="flex w-7 shrink-0">
                          <.icon name="tabler-check" class="size-5 text-purple-400" />
                        </div>
                        <span class="text-sm xl:text-base mb-0 text-foreground font-medium bg-purple-500/30 px-2 py-0.5 rounded-md -mt-1">
                          Recruiting partner option available
                        </span>
                      </div>
                    </li>
                  </ul>
                </div>
              </div>
            </.link>
          </div>

          <div class="mx-auto lg:max-w-[95rem] mt-8 text-center">
            <div class="bg-card/75 rounded-xl p-6 border">
              <h3 class="text-xl font-semibold text-foreground mb-4">
                Why Choose Algora for Hiring?
              </h3>
              <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div>
                  <div class="mb-2 mx-auto flex items-center justify-center h-12 w-12 bg-purple-400/10 rounded-full">
                    <.icon name="tabler-filter" class="h-8 w-8 text-purple-400" />
                  </div>
                  <h4 class="font-semibold text-foreground mb-1">High Signal</h4>
                  <p class="text-sm text-foreground-light">
                    Access pre-vetted developers with proven OSS track records
                  </p>
                </div>
                <div>
                  <div class="mb-2 mx-auto flex items-center justify-center h-12 w-12 bg-purple-400/10 rounded-full">
                    <.icon name="tabler-clock" class="h-8 w-8 text-purple-400" />
                  </div>
                  <h4 class="font-semibold text-foreground mb-1">Save Time & Money</h4>
                  <p class="text-sm text-foreground-light">
                    Match with top developers efficiently
                  </p>
                </div>
                <div>
                  <div class="mb-2 mx-auto flex items-center justify-center h-12 w-12 bg-purple-400/10 rounded-full">
                    <.icon name="tabler-shield-check" class="h-8 w-8 text-purple-400" />
                  </div>
                  <h4 class="font-semibold text-foreground mb-1">Reduce Risk</h4>
                  <p class="text-sm text-foreground-light">
                    Trial with bounties before committing to full-time hires
                  </p>
                </div>
              </div>
            </div>
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

      <section class="relative isolate pb-16 sm:pb-40">
        <div class="mx-auto max-w-7xl px-6 lg:px-8">
          <h2 class="mb-8 text-3xl font-bold text-card-foreground text-center">
            Join the open source economy
          </h2>
          <div class="mt-6 sm:mt-10 flex gap-4 justify-center">
            <.button
              navigate={~p"/onboarding/org"}
              class="h-10 sm:h-14 rounded-md px-8 sm:px-12 text-sm sm:text-xl"
            >
              Companies
            </.button>
            <.button
              navigate={~p"/onboarding/dev"}
              variant="secondary"
              class="h-10 sm:h-14 rounded-md px-8 sm:px-12 text-sm sm:text-xl"
            >
              Developers
            </.button>
          </div>
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
        faq_items: get_faq_items(),
        active_faq: nil
      )

    {:ok, socket}
  end

  def pricing_card1(assigns) do
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
        <div class="flex-1 p-4 sm:px-6 group-hover:sm:-ml-[4px] transition-all">
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
                          100%
                        </p>
                        <p class="text-foreground-lighter text-sm mb-1.5 ml-2 leading-4">
                          received
                        </p>
                      </div>
                    </div>
                  <% "pay-developers" -> %>
                    <div class="flex justify-between">
                      <div class="flex items-end">
                        <.button
                          variant="default"
                          size="lg"
                          class="font-display text-lg mr-auto sm:mr-0"
                        >
                          Contact us
                        </.button>
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
                  <div class="flex w-7 shrink-0">
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

  def get_plans1 do
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
        cta_url: AlgoraWeb.Constants.get(:calendar_url),
        popular: false,
        features: [
          %Feature{name: "GitHub bounties and tips"},
          %Feature{name: "Contract work (fixed/hourly)"},
          %Feature{name: "Invoices, payouts, compliance, 1099s"}
        ]
      }
    ]
  end

  defp get_faq_items do
    [
      %FaqItem{
        id: "payment-methods",
        question: "What payment methods do you support?",
        answer:
          ~s(We support payments via Stripe for funding bounties. Contributors can receive payments directly to their bank accounts in <a href="https://algora.io/docs/payments#supported-countries-regions" class="text-success hover:underline">#{ConnectCountries.count()} countries/regions</a> worldwide.)
      },
      %FaqItem{
        id: "payment-process",
        question: "How does the payment process work?",
        answer:
          "Organizations can either pay manually after merging pull requests, or save their card with Stripe to enable auto-pay on merge. Manual payments are processed through a secure Stripe hosted checkout page."
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
          ~s(We support contributors from #{ConnectCountries.count()} countries/regions worldwide. You can receive payments regardless of your location as long as you have a bank account in one of our supported countries. See the <a href="https://algora.io/docs/payments#supported-countries-regions" class="text-success hover:underline">full list of supported countries</a>.)
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
                href="https://algora.io/docs/payments#supported-countries-regions"
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
