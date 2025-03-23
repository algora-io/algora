defmodule AlgoraWeb.Pricing4Live do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.PSP.ConnectCountries
  alias AlgoraWeb.Components.Footer
  alias AlgoraWeb.Components.Header
  alias AlgoraWeb.Components.Logos
  alias AlgoraWeb.Components.Wordmarks

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
        <div class="mx-auto max-w-7xl px-6 lg:px-8">
          <div class="relative z-10 pb-4 xl:py-16">
            <div class="mx-auto max-w-7xl text-center px-6 lg:px-8">
              <div class="mx-auto max-w-3xl space-y-2 lg:max-w-none">
                <h1 class="text-3xl sm:text-4xl font-bold text-popover-foreground">
                  Simple, transparent pricing
                </h1>
                <p class="text-sm sm:text-lg text-muted-foreground">
                  For individuals, OSS communities, and open/closed source companies
                </p>
              </div>
            </div>
          </div>

          <div class="mx-auto lg:max-w-[90rem] mb-8">
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

          <div class="mx-auto grid gap-4 lg:max-w-[90rem] lg:grid-cols-2 xl:gap-0 border-l-4 border-emerald-400">
            <%= for plan <- @plans1 do %>
              <.pricing_card1 plan={plan} plans={@plans1} />
            <% end %>
          </div>

          <div class="mx-auto lg:max-w-[90rem] mt-16 mb-8">
            <div class="flex items-start gap-4">
              <div class="flex-1">
                <h2 class="text-2xl font-semibold text-foreground mb-2">
                  <div class="flex items-center gap-2">
                    <.icon name="tabler-building-store" class="h-6 w-6 text-blue-400" /> Platform
                  </div>
                </h2>
                <p class="text-base text-foreground-light">
                  Connect with top open source talent, increase project visibility, and hire proven contributors
                </p>
              </div>
            </div>
          </div>
          <div class="mx-auto grid gap-4 lg:max-w-[90rem] lg:min-h-[23rem] xl:gap-0 border-l-4 border-blue-400">
            <%= for plan <- @plans2 do %>
              <.pricing_card2 plan={plan} plans={@plans2} />
            <% end %>
          </div>
        </div>
      </section>

      <section class="bg-muted/20 border-t py-16 sm:py-24">
        <div class="mx-auto max-w-7xl px-6 lg:px-8">
          <div class="mx-auto max-w-2xl text-center">
            <h2 class="mb-4 text-3xl font-bold text-popover-foreground">
              You're in good company
            </h2>
            <p class="text-base text-muted-foreground">
              Join hundreds of open source companies that use Algora to accelerate their development
            </p>
          </div>
          <div class="mx-auto mt-8 max-w-2xl gap-8 text-sm leading-6 sm:mt-10">
            <.logo_cloud />
          </div>
        </div>
      </section>

      <section class="bg-background border-t py-16 sm:py-24">
        <div class="mx-auto max-w-7xl px-6 lg:px-8">
          <div class="mx-auto max-w-2xl text-center">
            <h2 class="mb-4 text-3xl font-bold text-popover-foreground">
              See what our customers say
            </h2>
            <p class="text-base text-muted-foreground">
              Discover how Algora helps founders accelerate development and find top talent
            </p>
          </div>

          <div class="mx-auto mt-16 max-w-2xl gap-8 text-sm leading-6 text-gray-900 sm:mt-20 sm:grid-cols-2 lg:mx-0 lg:max-w-none">
            <div class="grid gap-x-12 gap-y-8 lg:grid-cols-7">
              <div class="lg:col-span-3">
                <div class="relative flex aspect-square w-full items-center justify-center overflow-hidden rounded-xl lg:rounded-2xl bg-gray-800">
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
              <div class="lg:col-span-4">
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
          <div class="mx-auto mt-16 max-w-2xl gap-8 text-sm leading-6 text-gray-900 sm:mt-20 sm:grid-cols-2 lg:mx-0 lg:max-w-none">
            <div class="grid gap-x-12 gap-y-8 lg:grid-cols-7">
              <div class="lg:col-span-3 order-last lg:order-first">
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
              <div class="lg:col-span-4 order-first lg:order-last">
                <div class="relative flex aspect-video w-full items-center justify-center overflow-hidden rounded-xl lg:rounded-2xl bg-gray-800">
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
      </section>

      <section class="bg-muted/20 border-t py-16 sm:py-24">
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
            <span class="block sm:inline">UpWork alternative.</span>
          </h2>
          <div class="flex justify-center gap-4">
            <.button navigate="/onboarding/org">
              Start your project
            </.button>
            <.button href="https://cal.com/ioannisflo" variant="secondary">
              Request a demo
            </.button>
          </div>
          <.features_bento />
        </div>
      </section>

      <div class="bg-muted/20">
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
    <div class={[
      "bg-card/75 flex justify-between rounded-xl border",
      "last:rounded-r-xl last:border-r xl:rounded-none xl:border-r-0",
      @plan.popular && "border-foreground-muted !border-2 !rounded-xl xl:-my-8",
      "divide-x divide-default"
    ]}>
      <div class="flex-1 px-8 pt-6 xl:px-4 2xl:px-8 pr-0">
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
        <.button navigate={@plan.cta_url}>
          {@plan.cta_text}
        </.button>
        <div class="border-default flex items-baseline py-8 text-5xl font-normal text-foreground lg:py-10 lg:text-4xl xl:text-4xl">
          <div class="flex flex-col gap-1 w-full">
            <%= case @plan.id do %>
              <% :a0 -> %>
                <div class="flex justify-between">
                  <div class="flex items-end">
                    <p class="font-display text-4xl">
                      0%
                    </p>
                    <p class="text-foreground-lighter text-sm mb-1.5 ml-2 leading-4">
                      service fee
                    </p>
                  </div>
                </div>
              <% :a1 -> %>
                <div class="flex justify-between">
                  <div class="flex items-end">
                    <p class="font-display text-4xl">
                      9%
                    </p>
                    <p class="text-foreground-lighter text-sm mb-1.5 ml-2 leading-4">
                      service fee
                    </p>
                  </div>
                </div>
              <% :b0 -> %>
                <div class="flex justify-between">
                  <div class="flex items-end">
                    <p class="font-display text-4xl">
                      $599
                    </p>
                    <p class="text-foreground-lighter text-sm mb-1.5 ml-2 leading-4">
                      /mo
                    </p>
                  </div>
                </div>
              <% :b1 -> %>
                <div class="flex justify-between">
                  <div class="flex items-end">
                    <p class="font-display text-4xl">
                      $1,599
                    </p>
                    <p class="text-foreground-lighter text-sm mb-1.5 ml-2 leading-4">
                      /mo
                    </p>
                  </div>
                </div>
              <% :b2 -> %>
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
      <div class="flex-1 border-l my-auto border-default px-4 2xl:px-8 pl-0">
        <%!-- <div class="text-sm text-foreground">
          <%= case @plan.id do %>
            <% 0 -> %>
            <% 1 -> %>
              <span>Everything in {Enum.at(@plans, 0).name}, plus:</span>
            <% 2 -> %>
              <span>Everything in {Enum.at(@plans, 1).name}, plus:</span>
          <% end %>
        </div> --%>
        <ul class="border-default text-sm text-foreground-lighter flex-1">
          <%= for feature <- @plan.features do %>
            <li class="flex flex-col py-2 first:mt-0">
              <div class="flex items-center">
                <div class="flex w-7">
                  <.icon name="tabler-check" class="size-5 text-emerald-400" />
                </div>
                <span class="text-sm xl:text-base mb-0 text-foreground">
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
    """
  end

  defp pricing_card2(assigns) do
    ~H"""
    <div class={[
      "bg-card/75 flex justify-between rounded-xl border",
      "last:rounded-r-xl last:border-r xl:rounded-none xl:border-r-0",
      @plan.popular && "border-foreground-muted !border-2 !rounded-xl xl:-my-8",
      "divide-x divide-default"
    ]}>
      <div class="w-1/3 px-8 pt-6 xl:px-4 2xl:px-8">
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
        <div class="flex gap-2">
          <.button navigate={@plan.cta_url} variant="blue">
            {@plan.cta_text}
          </.button>
          <.button
            href="https://github.com/algora-io/console"
            rel="noopener"
            target="_blank"
            variant="secondary"
          >
            <.icon name="github" class="size-5 mr-2 -ml-1" /> View source code
          </.button>
        </div>
        <div class="border-default flex items-baseline py-8 text-5xl font-normal text-foreground lg:py-10 lg:text-4xl xl:text-4xl">
          <div class="flex flex-col gap-1 w-full">
            <%= case @plan.id do %>
              <% :b2 -> %>
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
      <div class="w-2/3 border-l my-auto border-default px-8 xl:px-4 2xl:px-8">
        <ul class="border-default text-sm text-foreground-lighter flex-1 grid grid-cols-2 gap-4">
          <%= for feature <- @plan.features do %>
            <li class="flex flex-col first:mt-0">
              <div class="flex items-center">
                <div class="flex w-7">
                  <.icon name="tabler-check" class="size-5 text-blue-400" />
                </div>
                <span class="mb-0 text-foreground">{Phoenix.HTML.raw(feature.name)}</span>
              </div>
              <%= if feature.detail do %>
                <p class="text-foreground-lighter ml-6">{feature.detail}</p>
              <% end %>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  defp get_plans1 do
    [
      %Plan{
        id: :a0,
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
        id: :a1,
        name: "Pay developers",
        description: "Reward contributions with bounties",
        price: nil,
        cta_text: "Create bounties",
        cta_url: "/onboarding/dev",
        popular: false,
        features: [
          %Feature{name: "Get work done in your repos"},
          %Feature{name: "Improve your dependencies"},
          %Feature{name: "Engage your OSS community"},
          %Feature{name: "Collaborate with freelancers"},
          %Feature{name: "Evaluate candidates with real tasks"}
        ]
      }
    ]
  end

  defp get_plans2 do
    [
      %Plan{
        id: :b2,
        name: "Looking for more?",
        description: "Tailor Algora to your needs",
        price: "Custom",
        cta_text: "Contact us",
        cta_url: "https://cal.com/ioannisflo",
        popular: false,
        features: [
          %Feature{name: "Featured on Algora's marketplace (15k+ monthly visitors)"},
          %Feature{name: "Access to verified OSS experts (12k+ users)"},
          %Feature{name: "Flexible on-demand engineering"},
          %Feature{name: "Instant top matches for your roles"},
          %Feature{name: "Jobs published to platform & newsletter"},
          %Feature{name: "Interview candidates using bounties"},
          %Feature{name: ~s(<span class="font-medium">No placement fees</span> (up to 5 jobs\))},
          %Feature{name: "Whitelabel portal (cloud / self-hosted)"},
          %Feature{name: "Priority placement (5+ full-time roles)"},
          %Feature{name: "24x7x365 premium support"},
          %Feature{name: "SOC2 compliance"},
          %Feature{name: "HIPAA available as add-on"},
          %Feature{name: "Custom Security Questionnaires"}
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
          "For organizations, we charge a 19% fee on bounties, which can drop to 7.5% with volume. For individual contributors, you receive 100% of the bounty amount with no fees deducted."
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

  defp logo_cloud(assigns) do
    ~H"""
    <div>
      <div class="grid grid-cols-3 lg:grid-cols-4 items-center justify-center gap-x-5 gap-y-4 sm:gap-x-10 sm:gap-y-8">
        <a class="relative flex items-center justify-center" href="https://console.algora.io/org/cal">
          <Wordmarks.calcom class="w-[6rem] sm:w-[7rem] col-auto mt-1" alt="Cal.com" />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/qdrant"
        >
          <Wordmarks.qdrant class="w-[6rem] sm:w-[7rem] col-auto" alt="Qdrant" />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/remotion"
        >
          <img
            src="https://algora.io/banners/remotion.png"
            alt="Remotion"
            class="col-auto w-full saturate-0"
          />
        </a>
        <a class="relative flex items-center justify-center" href="https://console.algora.io/org/zio">
          <img
            src="https://algora.io/banners/zio.png"
            alt="ZIO"
            class="w-[10rem] col-auto brightness-0 invert"
          />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/triggerdotdev"
        >
          <img
            src="https://algora.io/banners/triggerdotdev.png"
            alt="Trigger.dev"
            class="col-auto w-full saturate-0"
          />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/tembo"
        >
          <img
            src="https://algora.io/banners/tembo.png"
            alt="Tembo"
            class="w-[13rem] col-auto saturate-0"
          />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/maybe-finance"
        >
          <img
            src="https://algora.io/banners/maybe.png"
            alt="Maybe"
            class="col-auto w-full saturate-0"
          />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/golemcloud"
        >
          <Wordmarks.golemcloud class="col-auto w-full" alt="Golem Cloud" />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/aidenybai"
        >
          <img
            src="https://algora.io/banners/million.png"
            alt="Million"
            class="col-auto w-44 saturate-0"
          />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/tailcallhq"
        >
          <Wordmarks.tailcall class="w-[10rem] col-auto" fill="white" alt="Tailcall" />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/highlight"
        >
          <img
            src="https://algora.io/banners/highlight.png"
            alt="Highlight"
            class="col-auto w-44 saturate-0"
          />
        </a>
        <a
          class="relative flex items-center justify-center"
          href="https://console.algora.io/org/dittofeed"
        >
          <img
            src="https://algora.io/banners/dittofeed.png"
            alt="Dittofeed"
            class="col-auto w-40 brightness-0 invert"
          />
        </a>
      </div>
    </div>
    """
  end

  defp features_bento(assigns) do
    ~H"""
    <div class="mt-10 grid grid-cols-1 gap-4 sm:mt-16 lg:grid-cols-[repeat(14,_minmax(0,_1fr))]">
      <div class="flex p-px lg:col-span-8">
        <div class="w-full overflow-hidden rounded sm:rounded-lg bg-card ring-1 ring-white/15 lg:rounded-tl-[2rem]">
          <img class="object-cover object-left" src={~p"/images/screenshots/bounty.png"} alt="" />
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
          <img class="object-cover" src={~p"/images/screenshots/tip.png"} alt="" />
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
          <img class="object-cover object-left" src={~p"/images/screenshots/bounties.png"} alt="" />
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
          <img class="object-cover" src={~p"/images/screenshots/contract.png"} alt="" />
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
