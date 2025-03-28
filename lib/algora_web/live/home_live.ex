defmodule AlgoraWeb.HomeLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Bounties
  alias Algora.Github
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias Algora.Workspace
  alias AlgoraWeb.Components.Footer
  alias AlgoraWeb.Components.Header
  alias AlgoraWeb.Components.Logos
  alias AlgoraWeb.Data.PlatformStats
  alias AlgoraWeb.Forms.BountyForm
  alias AlgoraWeb.Forms.TipForm

  require Logger

  defmodule RepoForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :url, :string
    end

    def changeset(form, attrs) do
      form
      |> cast(attrs, [:url])
      |> validate_required([:url])
    end
  end

  @impl true
  def mount(%{"country_code" => country_code} = params, _session, socket) do
    Gettext.put_locale(AlgoraWeb.Gettext, Algora.Util.locale_from_country_code(country_code))

    stats = [
      %{label: "Paid Out", value: format_money(get_total_paid_out())},
      %{label: "Completed Bounties", value: format_number(get_completed_bounties_count())},
      %{label: "Contributors", value: format_number(get_contributors_count())},
      %{label: "Countries", value: format_number(get_countries_count())}
    ]

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Algora.PubSub, "auth:#{socket.id}")
    end

    {:ok,
     socket
     |> assign(:screenshot?, not is_nil(params["screenshot"]))
     |> assign(:oauth_url, Github.authorize_url(%{socket_id: socket.id}))
     |> assign(:featured_devs, Accounts.list_featured_developers(country_code))
     |> assign(:stats, stats)
     |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
     |> assign(:tip_form, to_form(TipForm.changeset(%TipForm{}, %{})))
     |> assign(:repo_form, to_form(RepoForm.changeset(%RepoForm{}, %{})))
     |> assign(:pending_action, nil)}
  end

  attr :src, :string, required: true
  attr :poster, :string, required: true
  attr :title, :string, default: nil
  attr :alt, :string, default: nil
  attr :class, :string, default: nil
  attr :autoplay, :boolean, default: true
  attr :start, :integer, default: 0

  defp modal_video(assigns) do
    ~H"""
    <div
      class={
        classes([
          "group relative aspect-video w-full overflow-hidden rounded-xl lg:rounded-2xl bg-gray-800 cursor-pointer",
          @class
        ])
      }
      phx-click={
        %JS{}
        |> JS.set_attribute({"src", @src <> "?autoplay=#{@autoplay}&start=#{@start}"},
          to: "#video-modal-iframe"
        )
        |> JS.set_attribute({"title", @title}, to: "#video-modal-iframe")
        |> show_modal("video-modal")
      }
    >
      <img src={@poster} alt={@alt} class="object-cover w-full h-full" loading="lazy" />
      <div class="absolute inset-0 flex items-center justify-center">
        <div class="size-10 sm:size-16 rounded-full bg-black/50 flex items-center justify-center group-hover:bg-black/70 transition-colors">
          <.icon name="tabler-player-play-filled" class="size-5 sm:size-8 text-white" />
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @screenshot? do %>
        <div class="-mt-24" />
      <% else %>
        <Header.header />
      <% end %>

      <main>
        <section class="relative isolate overflow-hidden min-h-[100svh] bg-gradient-to-b from-background to-black">
          <.pattern />
          <div class="mx-auto max-w-7xl pt-24 pb-12 xl:pt-20">
            <div class="mx-auto lg:mx-0 lg:flex lg:max-w-none lg:items-center">
              <div class="px-6 lg:px-8 lg:pr-0 xl:pb-20 relative w-full lg:max-w-xl lg:shrink-0 xl:max-w-3xl 2xl:max-w-3xl">
                <h1 class="font-display text-3xl sm:text-4xl md:text-5xl xl:text-7xl font-semibold tracking-tight text-foreground">
                  The open source Upwork for engineers
                </h1>
                <p class="mt-4 sm:mt-8 text-base sm:text-lg xl:text-2xl/8 font-medium text-muted-foreground sm:max-w-md lg:max-w-none">
                  Discover GitHub bounties, contract work and jobs.<br class="hidden sm:block" />
                  Hire the top 1% open source developers.
                </p>
                <div class="mt-6 sm:mt-10 flex gap-4">
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
              <!-- Featured devs -->
              <div class={
                classes([
                  "mt-8 sm:mt-14 flex justify-start md:justify-center gap-4 sm:gap-8 lg:justify-start lg:mt-0 lg:pl-0",
                  "overflow-x-auto scrollbar-thin lg:overflow-x-visible px-6 lg:px-8"
                ])
              }>
                <%= if length(@featured_devs) > 0 do %>
                  <div class="ml-auto w-28 min-[500px]:w-40 sm:w-56 lg:w-44 flex-none space-y-6 sm:space-y-8 pt-16 sm:pt-32 sm:ml-0 lg:order-last lg:pt-36 xl:order-none xl:pt-80">
                    <.dev_card dev={List.first(@featured_devs)} />
                  </div>
                  <div class="flex flex-col mr-auto w-28 min-[500px]:w-40 sm:w-56 lg:w-44 flex-none space-y-6 sm:space-y-8 sm:mr-0 lg:pt-36">
                    <%= if length(@featured_devs) >= 3 do %>
                      <%= for dev <- Enum.slice(@featured_devs, 1..2) do %>
                        <.dev_card dev={dev} />
                      <% end %>
                    <% end %>
                  </div>
                  <div class="flex flex-col w-28 min-[500px]:w-40 sm:w-56 lg:w-44 flex-none space-y-6 sm:space-y-8 pt-16 sm:pt-32 lg:pt-0">
                    <%= for dev <- Enum.slice(@featured_devs, 3..4) do %>
                      <.dev_card dev={dev} />
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>

          <div class="relative isolate overflow-hidden py-[35vw] sm:py-[25vw]">
            <div class="z-20 absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 transform">
              <div class="scale-[300%] sm:scale-[150%] opacity-50">
                <div class="[transform:perspective(4101px)_rotateX(51deg)_rotateY(-13deg)_rotateZ(40deg)]">
                  <img
                    alt="Algora dashboard"
                    width="1200"
                    height="630"
                    loading="lazy"
                    class="border border-border bg-muted mix-blend-overlay [box-shadow:0px_80px_60px_0px_rgba(0,0,0,0.35),0px_35px_28px_0px_rgba(0,0,0,0.25),0px_18px_15px_0px_rgba(0,0,0,0.20),0px_10px_8px_0px_rgba(0,0,0,0.17),0px_5px_4px_0px_rgba(0,0,0,0.14),0px_2px_2px_0px_rgba(0,0,0,0.10)]"
                    style="color:transparent"
                    src={~p"/images/screenshots/org-home.png"}
                  />
                </div>
              </div>
            </div>
            <div class="z-30 relative mx-auto max-w-7xl px-6 lg:px-8">
              <.form
                for={@repo_form}
                phx-submit="submit_repo"
                class="mt-6 sm:mt-10 w-full max-w-lg xl:max-w-2xl mx-auto"
              >
                <div class="relative">
                  <.input
                    field={@repo_form[:url]}
                    placeholder="github.com/your/repo"
                    class={
                      classes([
                        "w-full h-10 sm:h-16 text-sm sm:text-lg xl:text-2xl pl-8 sm:pl-[3.75rem] pr-24 sm:pr-48 ring-2 ring-emerald-500 font-display rounded-lg sm:rounded-xl",
                        @repo_form[:url].errors != [] && "ring-destructive"
                      ])
                    }
                  />
                  <Logos.github class="size-5 sm:size-10 absolute left-2 sm:left-3 top-2 sm:top-3 text-muted-foreground/50" />
                  <.button
                    type="submit"
                    class="absolute right-2 top-1.5 sm:top-2 bottom-1.5 sm:bottom-2 px-2 sm:px-8 h-7 sm:h-[3rem] text-sm sm:text-xl sm:font-semibold drop-shadow-[0_1px_5px_#34d39980] rounded-lg sm:rounded-xl"
                  >
                    Get Started
                  </.button>
                </div>
              </.form>
            </div>
          </div>

          <div class="p-4 sm:p-6 md:p-8">
            <div class="mx-auto max-w-6xl gap-8 text-sm leading-6 py-8 sm:py-16 md:py-24 lg:py-40">
              <div class="pt-20 sm:pt-40 flex gap-4 sm:gap-8 lg:gap-x-16">
                <div class="w-[40%]">
                  <.modal_video
                    class="aspect-[9/16] rounded-xl lg:rounded-2xl lg:rounded-r-none"
                    src="https://www.youtube.com/embed/xObOGcUdtY0"
                    start={122}
                    title="$15,000 Open source bounty to hire a Rust engineer"
                    poster={~p"/images/people/john-de-goes.jpg"}
                    alt="John A De Goes"
                  />
                </div>
                <div class="w-[60%]">
                  <.link
                    href="https://github.com/golemcloud/golem/issues/1004"
                    rel="noopener"
                    target="_blank"
                    class="relative flex aspect-[1121/1343] w-full items-center justify-center overflow-hidden rounded-xl lg:rounded-2xl lg:rounded-l-none bg-gray-800"
                  >
                    <img
                      src={~p"/images/screenshots/bounty-to-hire-golem2.png"}
                      alt="Golem bounty to hire"
                      class="object-cover"
                      loading="lazy"
                    />
                  </.link>
                </div>
              </div>
              <div class="mt-20 sm:mt-40 relative grid items-center grid-cols-1 lg:grid-cols-5 w-full gap-8 lg:gap-x-12 rounded-xl bg-black/25 p-4 sm:p-8 lg:p-12 ring-2 ring-success/20 transition-colors">
                <div class="lg:col-span-2 text-base leading-6 flex-1">
                  <div class="text-2xl sm:text-3xl font-semibold text-foreground">
                    Fund any issue
                    <span class="text-success drop-shadow-[0_1px_5px_#34d39980]">
                      in seconds
                    </span>
                  </div>
                  <div class="pt-2 text-sm sm:text-lg xl:text-lg font-medium text-muted-foreground">
                    Help improve the OSS you love and rely on
                  </div>
                  <div class="pt-4 col-span-3 text-sm text-muted-foreground space-y-1">
                    <div>
                      <.icon name="tabler-check" class="h-4 w-4 mr-1 text-success-400" />
                      Pay when PRs are merged
                    </div>
                    <div>
                      <.icon name="tabler-check" class="h-4 w-4 mr-1 text-success-400" />
                      Pool bounties with other sponsors
                    </div>
                    <div>
                      <.icon name="tabler-check" class="h-4 w-4 mr-1 text-success-400" />
                      Algora handles invoices, payouts, compliance<span class="hidden sm:inline"> & 1099s</span>
                    </div>
                  </div>
                </div>
                <.form
                  for={@bounty_form}
                  phx-submit="create_bounty"
                  class="lg:col-span-3 grid grid-cols-1 gap-4 sm:gap-6 w-full"
                >
                  <.input
                    label="URL"
                    field={@bounty_form[:url]}
                    placeholder="https://github.com/owner/repo/issues/1337"
                  />
                  <.input
                    label="Amount"
                    icon="tabler-currency-dollar"
                    field={@bounty_form[:amount]}
                    class="placeholder:text-success"
                  />
                  <div class="flex flex-col items-center gap-2">
                    <.button size="lg" class="w-full drop-shadow-[0_1px_5px_#34d39980]">
                      Fund issue
                    </.button>
                    <div class="text-sm text-muted-foreground">No credit card required</div>
                  </div>
                </.form>
              </div>
              <div class="pt-20 sm:pt-40 grid grid-cols-1 gap-16">
                <.link
                  href="https://github.com/zed-industries/zed/issues/4440"
                  rel="noopener"
                  target="_blank"
                  class="relative flex flex-col sm:flex-row items-start sm:items-center gap-4 sm:gap-x-4 rounded-xl bg-black p-4 sm:p-6 ring-1 ring-border transition-colors"
                >
                  <div class="flex -space-x-4 shrink-0">
                    <img
                      class="size-20 rounded-full z-0"
                      src="https://github.com/zed-industries.png"
                      alt="Zed"
                      loading="lazy"
                    />
                    <img
                      class="size-20 rounded-full z-10"
                      src="https://github.com/schacon.png"
                      alt="Scott Chacon"
                      loading="lazy"
                    />
                  </div>
                  <div class="text-base leading-6 flex-1">
                    <div class="text-xl sm:text-2xl font-semibold text-foreground">
                      GitHub cofounder funds new feature in Zed Editor
                    </div>
                    <div class="text-base sm:text-lg font-medium text-muted-foreground">
                      Zed Editor, Scott Chacon
                    </div>
                  </div>
                  <.button size="lg" variant="secondary" class="hidden sm:flex mt-2 sm:mt-0">
                    <Logos.github class="size-5 mr-3" /> View issue
                  </.button>
                </.link>

                <.link
                  href="https://github.com/PX4/PX4-Autopilot/issues/22464"
                  rel="noopener"
                  target="_blank"
                  class="relative flex flex-col sm:flex-row items-start sm:items-center gap-4 sm:gap-x-4 rounded-xl bg-black p-4 sm:p-6 ring-1 ring-border transition-colors"
                >
                  <div class="flex items-center -space-x-6 shrink-0">
                    <img
                      class="size-20 rounded-full z-0"
                      src="https://pbs.twimg.com/profile_images/1277333515412045824/Xys6F_6E_400x400.jpg"
                      alt="Alex Klimaj"
                      loading="lazy"
                    />
                    <img
                      class="size-16 z-20"
                      src="https://github.com/PX4.png"
                      alt="PX4"
                      loading="lazy"
                    />
                    <img
                      class="size-20 rounded-full z-10"
                      src="https://pbs.twimg.com/profile_images/1768744461243387905/AHYQnqY9_400x400.jpg"
                      alt="Andrew Wilkins"
                      loading="lazy"
                    />
                  </div>
                  <div class="text-base leading-6 flex-1">
                    <div class="text-xl sm:text-2xl font-semibold text-foreground">
                      DefenceTech CEOs fund obstacle avoidance in PX4 Autopilot
                    </div>
                    <div class="text-base sm:text-lg font-medium text-muted-foreground">
                      Alex Klimaj, Founder of ARK Electronics & Andrew Wilkins, CEO of Ascend Engineering
                    </div>
                  </div>
                  <.button size="lg" variant="secondary" class="hidden sm:flex mt-2 sm:mt-0">
                    <Logos.github class="size-5 mr-3" /> View issue
                  </.button>
                </.link>

                <.link
                  href={~p"/org/coollabsio"}
                  rel="noopener"
                  class="relative flex flex-col sm:flex-row items-start sm:items-center gap-4 sm:gap-x-4 rounded-xl bg-black p-4 sm:p-6 ring-1 ring-border transition-colors"
                >
                  <div class="flex -space-x-4 shrink-0">
                    <img
                      class="size-20 rounded-full z-0"
                      src="https://pbs.twimg.com/profile_images/1885366118367256580/ZmNo5ur__400x400.jpg"
                      alt="Coolify"
                      loading="lazy"
                    />
                    <img
                      class="size-20 rounded-full z-10"
                      src="https://github.com/andrasbacsai.png"
                      alt="Andras Bacsai"
                      loading="lazy"
                    />
                  </div>
                  <div class="text-base leading-6 flex-1">
                    <div class="text-xl sm:text-2xl font-semibold text-foreground">
                      Coolify community crowdfunds new feature development
                    </div>
                    <div class="text-base sm:text-lg font-medium text-muted-foreground">
                      Andras Bacsai, Founder of Coolify
                    </div>
                  </div>
                  <.button
                    size="lg"
                    variant="secondary"
                    class="hidden sm:flex mt-2 sm:mt-0 ring-2 ring-emerald-500"
                  >
                    View bounty board
                  </.button>
                </.link>
              </div>
            </div>
          </div>
        </section>

        <section class="relative isolate overflow-hidden bg-black py-16 sm:py-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <img
              src="https://www.firecrawl.dev/images/yc.svg"
              class="h-16 sm:h-24 mx-auto"
              alt="Y Combinator Logo"
              loading="lazy"
            />
            <h2 class="mt-4 sm:mt-8 font-display text-lg sm:text-3xl xl:text-6xl font-semibold tracking-tight text-foreground text-center mb-4 !leading-[1.25]">
              YCombinator companies use Algora<br />to build product and hire engineers
            </h2>
            <div class="mx-auto mt-8 max-w-5xl gap-12 text-sm leading-6 sm:mt-16">
              <.yc_logo_cloud />
            </div>

            <div class="mx-auto mt-16 max-w-6xl gap-8 text-sm leading-6 sm:mt-32">
              <div class="grid grid-cols-1 items-center gap-x-12 gap-y-8 lg:grid-cols-10">
                <div class="lg:col-span-4">
                  <div class="relative flex aspect-square size-[18rem] sm:size-[24rem] items-center justify-center overflow-hidden rounded-2xl bg-gray-800">
                    <img
                      src={~p"/images/people/tal-borenstein.jpeg"}
                      alt="Tal Borenstein"
                      class="object-cover"
                      loading="lazy"
                    />
                  </div>
                </div>
                <div class="lg:col-span-6">
                  <h3 class="text-xl sm:text-2xl xl:text-3xl font-display font-bold leading-[1.2] sm:leading-[2rem] xl:leading-[3rem]">
                    Keep has 90+ integrations to alert our customers about critical events. Of these,
                    <.link
                      href="https://github.com/keephq/keep/issues?q=state%3Aclosed%20label%3A%22%F0%9F%92%8E%20Bounty%22%20%20label%3A%22%F0%9F%92%B0%20Rewarded%22%20label%3AProvider%20"
                      rel="noopener"
                      target="_blank"
                      class="text-success inline-flex items-center hover:text-success-300"
                    >
                      42 integrations <.icon name="tabler-external-link" class="size-5 ml-1 mb-4" />
                    </.link>
                    were built by <span class="text-success">22 developers</span>
                    using <span class="text-success">bounties on Algora</span>.
                  </h3>
                  <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-12">
                    <div class="flex items-center gap-4">
                      <div>
                        <div class="text-xl sm:text-2xl xl:text-3xl font-semibold text-foreground">
                          Tal Borenstein
                        </div>
                        <div class="pt-2 text-base sm:text-lg xl:text-2xl font-medium text-muted-foreground">
                          Co-founder & CEO at Keep (YC W23)
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section class="relative isolate overflow-hidden bg-black py-16 sm:py-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-4">
              Build product faster
            </h2>
            <p class="text-center font-medium text-base text-muted-foreground mb-12 max-w-2xl mx-auto">
              Use bounties for outcome-based contract work with full GitHub integration.
            </p>
            <div class="mx-auto mt-16 max-w-6xl gap-8 text-sm leading-6 sm:mt-32">
              <div class="grid grid-cols-1 items-center gap-x-8 sm:gap-x-16 gap-y-8 lg:grid-cols-11">
                <div class="lg:col-span-5 order-first lg:order-last">
                  <div class="relative flex aspect-[791/576] items-center justify-center overflow-hidden rounded-xl sm:rounded-2xl bg-gray-800">
                    <img
                      src={~p"/images/people/louis-beaumont.png"}
                      alt="Louis Beaumont"
                      class="object-cover"
                      loading="lazy"
                    />
                  </div>
                </div>
                <div class="lg:col-span-6 order-last lg:order-first">
                  <h3 class="text-xl sm:text-2xl xl:text-3xl font-display font-bold leading-[1.2] sm:leading-[2rem] xl:leading-[3rem]">
                    I posted our bounty on <span class="text-success">Upwork</span>
                    to try it, overall it's <span class="text-success">1000x more friction</span>
                    than OSS bounties with Algora.
                  </h3>
                  <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-6 sm:pt-12">
                    <div class="flex items-center gap-4">
                      <div>
                        <div class="text-xl sm:text-2xl xl:text-3xl font-semibold text-foreground">
                          Louis Beaumont
                        </div>
                        <div class="pt-2 text-base sm:text-lg xl:text-2xl font-medium text-muted-foreground">
                          Co-founder & CEO at Screenpipe
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="mx-auto mt-16 max-w-6xl gap-8 text-sm leading-6 sm:mt-32">
              <div class="grid grid-cols-1 items-center gap-x-8 sm:gap-x-16 gap-y-8 lg:grid-cols-11">
                <div class="lg:col-span-6">
                  <div class="relative flex -space-x-4">
                    <img
                      src="https://github.com/calcom.png"
                      alt="Cal.com"
                      class="size-24 sm:size-40 rounded-2xl"
                      loading="lazy"
                    />
                    <img
                      src={~p"/images/people/peer-rich.jpeg"}
                      alt="PeerRich"
                      class="size-24 sm:size-40 rounded-full"
                      loading="lazy"
                    />
                    <img
                      src={~p"/images/people/bailey-pumfleet.jpeg"}
                      alt="Bailey Pumfleet"
                      class="size-24 sm:size-40 rounded-full"
                      loading="lazy"
                    />
                  </div>
                  <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-6 sm:pt-8">
                    <div class="flex flex-col sm:gap-4 text-xl sm:text-2xl xl:text-5xl font-semibold font-display">
                      <div>
                        Used bounties
                      </div>
                      <div class="text-success">
                        every month
                      </div>
                      <div class="text-success">
                        for 2+ years
                      </div>
                    </div>
                  </div>
                </div>
                <div class="lg:col-span-5">
                  <div class="text-xl sm:text-2xl xl:text-3xl font-display font-semibold leading-[1.5] sm:leading-[3rem]">
                    Shipped by <span class="text-success">86 contributors</span>
                  </div>
                  <ul class="text-xl sm:text-2xl xl:text-3xl font-display font-semibold leading-[1.5] sm:leading-[3rem]">
                    <li class="flex items-center gap-x-4">
                      <.icon name="tabler-check" class="size-6 sm:size-8 text-success" />
                      <span class="text-success tabular-nums font-bold">14</span>
                      High Priority tickets
                    </li>
                    <li class="flex items-center gap-x-4">
                      <.icon name="tabler-check" class="size-6 sm:size-8 text-success" />
                      <span class="text-success tabular-nums font-bold">24</span> Improvements
                    </li>
                    <li class="flex items-center gap-x-4">
                      <.icon name="tabler-check" class="size-6 sm:size-8 text-success" />
                      <span class="text-success tabular-nums font-bold">21</span> Bugs
                    </li>
                    <li class="flex items-center gap-x-4">
                      <.icon name="tabler-check" class="size-6 sm:size-8 text-success" />
                      <span class="text-success tabular-nums font-bold">36</span>
                      Medium priority tickets
                    </li>
                    <li class="flex items-center gap-x-4">
                      <.icon name="tabler-check" class="size-6 sm:size-8 text-success" />
                      <span class="text-success tabular-nums font-bold">13</span> UI updates
                    </li>
                    <li class="flex items-center gap-x-4">
                      <.icon name="tabler-check" class="size-6 sm:size-8 text-success" />
                      <span class="text-success tabular-nums font-bold">68</span> New Features
                    </li>
                    <li class="flex items-center gap-x-4">
                      <.icon name="tabler-check" class="size-6 sm:size-8 text-success" />
                      <span class="text-success tabular-nums font-bold">18</span> Integrations
                    </li>
                  </ul>
                </div>
              </div>
            </div>

            <div class="mx-auto mt-16 max-w-6xl gap-8 text-sm leading-6 sm:mt-32">
              <div class="grid grid-cols-1 items-center gap-x-16 gap-y-8 lg:grid-cols-11">
                <div class="lg:col-span-5 order-first lg:order-last">
                  <div class="relative flex aspect-[1091/1007] items-center justify-center overflow-hidden rounded-2xl bg-gray-800">
                    <img
                      src={~p"/images/people/josh-pigford.png"}
                      alt="Josh Pigford"
                      class="object-cover"
                      loading="lazy"
                    />
                  </div>
                </div>
                <div class="lg:col-span-6 order-last lg:order-first">
                  <h3 class="text-xl sm:text-2xl xl:text-3xl font-display font-bold leading-[1.2] sm:leading-[2rem] xl:leading-[3rem]">
                    <span class="text-success">Let's offer a bounty</span>
                    to say "Hey, someone please prioritize this, who has the skillset for it?" I think long term I'd like to make it a
                    <span class="text-success">very consistent</span>
                    part of our development process.
                  </h3>
                  <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-12">
                    <div class="flex items-center gap-4">
                      <div>
                        <div class="text-xl sm:text-2xl xl:text-3xl font-semibold text-foreground">
                          Josh Pigford
                        </div>
                        <div class="pt-2 text-base sm:text-lg xl:text-2xl font-medium text-muted-foreground">
                          Co-founder & CEO at Maybe
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="mx-auto mt-16 max-w-6xl gap-8 text-sm leading-6 sm:mt-32">
              <div class="grid grid-cols-1 items-center gap-x-16 gap-y-8 lg:grid-cols-11">
                <div class="lg:col-span-6">
                  <div class="relative flex items-center justify-center">
                    <img
                      src="https://pbs.twimg.com/profile_images/1771489509798236160/jGsCqm25_400x400.jpg"
                      alt="John A De Goes"
                      class="object-cover size-84 rounded-2xl"
                      loading="lazy"
                    />
                  </div>
                </div>
                <div class="lg:col-span-5">
                  <h3 class="text-xl sm:text-2xl xl:text-3xl font-display font-bold leading-[1.2] sm:leading-[2rem] xl:leading-[3rem]">
                    We used Algora extensively at Ziverge to reward over
                    <span class="text-success">$70,000</span>
                    in bounties and introduce a whole
                    <span class="text-success">new generation of contributors</span>
                    to the ZIO ecosystem.
                  </h3>
                  <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-12">
                    <div class="flex items-center gap-4">
                      <div>
                        <div class="text-xl sm:text-2xl xl:text-3xl font-semibold text-foreground">
                          John A De Goes
                        </div>
                        <div class="pt-2 text-base sm:text-lg xl:text-2xl font-medium text-muted-foreground">
                          Founder & CEO at Ziverge
                        </div>
                      </div>
                    </div>
                  </div>
                  <%!-- <dl class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-8 xl:flex-nowrap">
                    <div class="flex flex-col-reverse">
                      <dt class="text-lg text-muted-foreground font-medium whitespace-nowrap">
                        Total awarded
                      </dt>
                      <dd class="font-display text-5xl font-bold tracking-tight text-white">
                        $77,175
                      </dd>
                    </div>
                    <div class="flex flex-col-reverse">
                      <dt class="text-lg text-muted-foreground font-medium whitespace-nowrap">
                        Bounties completed
                      </dt>
                      <dd class="font-display text-5xl font-bold tracking-tight text-white">
                        359
                      </dd>
                    </div>
                    <div class="flex flex-col-reverse">
                      <dt class="text-lg text-muted-foreground font-medium whitespace-nowrap">
                        Contributors rewarded
                      </dt>
                      <dd class="font-display text-5xl font-bold tracking-tight text-white">
                        79
                      </dd>
                    </div>
                  </dl> --%>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section class="relative isolate overflow-hidden bg-black py-16 sm:py-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-4">
              Hire by building product
            </h2>
            <p class="text-center font-medium text-base text-muted-foreground mb-12 max-w-2xl mx-auto">
              Find your next team member through real-world collaboration. Use bounties to evaluate developers based on actual contributions to your codebase.
            </p>
            <div class="mx-auto mt-16 max-w-6xl gap-8 text-sm leading-6 sm:mt-32">
              <div class="grid grid-cols-1 items-center gap-x-16 gap-y-8 lg:grid-cols-12">
                <div class="lg:col-span-6 order-first lg:order-last">
                  <.modal_video
                    class="rounded-xl lg:rounded-2xl"
                    src="https://www.youtube.com/embed/FXQVD02rfg8"
                    start={8}
                    title="How Nick got a job with Open Source Software"
                    poster="https://img.youtube.com/vi/FXQVD02rfg8/maxresdefault.jpg"
                    alt="Eric Allam"
                  />
                </div>
                <div class="lg:col-span-6 order-last lg:order-first">
                  <h3 class="text-xl sm:text-2xl xl:text-3xl font-display font-bold leading-[1.2] sm:leading-[2rem] xl:leading-[3rem]">
                    It was the <span class="text-success">easiest hire</span>
                    because we already knew how great he was
                  </h3>
                  <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-12">
                    <div class="flex items-center gap-4">
                      <div>
                        <div class="text-xl sm:text-2xl xl:text-3xl font-semibold text-foreground">
                          Eric Allam
                        </div>
                        <div class="pt-2 text-base sm:text-lg xl:text-2xl font-medium text-muted-foreground">
                          Co-founder & CTO at Trigger.dev (YC W23)
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="mx-auto mt-16 max-w-6xl gap-8 text-sm leading-6 sm:mt-32">
              <div class="grid grid-cols-1 items-center gap-x-16 gap-y-8 lg:grid-cols-11">
                <div class="lg:col-span-5">
                  <.modal_video
                    class="rounded-xl lg:rounded-2xl"
                    src="https://www.youtube.com/embed/3wZGDuoPajk"
                    start={13}
                    title="OSS Bounties & Hiring engineers on Algora.io | Founder Testimonial"
                    poster="https://img.youtube.com/vi/3wZGDuoPajk/maxresdefault.jpg"
                    alt="Tushar Mathur"
                  />
                </div>
                <div class="lg:col-span-6">
                  <h3 class="text-xl sm:text-2xl xl:text-3xl font-display font-bold leading-[1.2] sm:leading-[2rem] xl:leading-[3rem]">
                    Bounties help us control our burn rate, get work done & meet new hires. I've made
                    <span class="text-success">3 full-time hires</span>
                    using Algora
                  </h3>
                  <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-12">
                    <div class="flex items-center gap-4">
                      <div>
                        <div class="text-xl sm:text-2xl xl:text-3xl font-semibold text-foreground">
                          Tushar Mathur
                        </div>
                        <div class="pt-2 text-base sm:text-lg xl:text-2xl font-medium text-muted-foreground">
                          Founder & CEO at Tailcall
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <%!-- mogery --%>
            <div class="mx-auto mt-16 max-w-6xl gap-8 text-sm leading-6 sm:mt-32">
              <.link
                class="font-bold font-display text-3xl whitespace-nowrap flex items-center justify-center brightness-0 invert"
                aria-label="Logo"
                navigate={~p"/org/mendableai"}
              >
                🔥
                Firecrawl
              </.link>
              <h2 class="mt-2 font-display text-3xl font-semibold tracking-tight text-foreground sm:text-5xl text-center mb-4 !leading-[1.25]">
                Open source contributor to full-time engineer
              </h2>
              <div class="flex items-center justify-center gap-8">
                <div class="flex-1 flex flex-wrap items-center justify-end gap-x-8 gap-y-4">
                  <div class="flex items-center gap-4">
                    <div class="text-right">
                      <div class="text-base font-medium text-foreground whitespace-nowrap">
                        Nicolas Camara
                      </div>
                      <div class="pt-1 text-sm font-medium text-muted-foreground whitespace-nowrap">
                        Founder & CTO
                      </div>
                    </div>
                    <img
                      src="https://pbs.twimg.com/profile_images/1599993355089465344/R6Al_s_H_400x400.jpg"
                      alt="Nicolas Camara"
                      class="size-12 rounded-full object-cover"
                      loading="lazy"
                    />
                  </div>
                </div>
                <.icon
                  name="tabler-git-merge"
                  class="size-6 sm:size-8 text-purple-400 hidden sm:block"
                />
                <div class="flex-1 flex flex-wrap items-center gap-x-8 gap-y-4">
                  <div class="flex items-center gap-4">
                    <img
                      src="https://github.com/mogery.png"
                      alt="Gergő Móricz"
                      class="size-12 rounded-full object-cover"
                      loading="lazy"
                    />
                    <div>
                      <div class="text-base font-semibold text-foreground whitespace-nowrap">
                        Gergő Móricz
                      </div>
                      <div class="pt-2 text-sm font-medium text-muted-foreground whitespace-nowrap">
                        Contributor
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div class="pt-8 sm:pt-12 flex gap-8 lg:gap-x-16">
                <div class="w-[24%]">
                  <.modal_video
                    class="aspect-[9/16] rounded-xl lg:rounded-2xl"
                    src="https://www.youtube.com/embed/j4fLNIJCywk"
                    title="High school student solves #opensource bounties"
                    poster="https://img.youtube.com/vi/j4fLNIJCywk/maxresdefault.jpg"
                    alt="Gergő Móricz"
                  />
                </div>
                <div class="w-[76%]">
                  <.modal_video
                    class="rounded-xl lg:rounded-2xl"
                    src="https://www.youtube.com/embed/HhTT-GX5tjQ"
                    start={293}
                    title="🧑🏻‍💻 Building your bounty hunter reputation & Mendable contributions 💸"
                    poster={~p"/images/people/mogery.png"}
                    alt="Gergő Móricz"
                  />
                </div>
              </div>
            </div>
          </div>
        </section>

        <section class="relative isolate overflow-hidden bg-black py-16 sm:py-40">
          <div class="mx-auto 2xl:max-w-[90rem] px-6 lg:px-8">
            <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-4">
              Did you know?
            </h2>
            <p class="text-center font-medium text-base text-muted-foreground mb-8 sm:mb-16">
              You can tip your favorite open source contributors with Algora.
            </p>

            <div class="flex flex-col lg:flex-row gap-8">
              <div class="w-full lg:max-w-6xl relative rounded-2xl bg-black/25 p-4 sm:p-8 lg:p-12 ring-1 ring-blue-500/20 transition-colors backdrop-blur-sm">
                <div class="grid grid-cols-1 items-center lg:grid-cols-7 gap-8 h-full">
                  <div class="lg:col-span-3 text-base leading-6">
                    <h3 class="text-2xl sm:text-3xl font-semibold text-foreground">
                      Tip any contributor <br class="hidden lg:block" />
                      <span class="text-blue-500 drop-shadow-[0_1px_5px_#60a5fa80]">instantly</span>
                    </h3>
                    <p class="mt-4 text-base sm:text-lg font-medium text-muted-foreground">
                      Support the maintainers behind your favorite open source projects
                    </p>
                    <div class="mt-4 sm:mt-6 space-y-3">
                      <div class="flex items-center gap-2 text-sm text-muted-foreground">
                        <.icon name="tabler-check" class="h-5 w-5 text-blue-400 flex-none" />
                        <span>Send tips directly to GitHub usernames</span>
                      </div>
                      <div class="flex items-center gap-2 text-sm text-muted-foreground">
                        <.icon name="tabler-check" class="h-5 w-5 text-blue-400 flex-none" />
                        <span>Algora handles payouts, compliance & 1099s</span>
                      </div>
                    </div>
                  </div>

                  <.form
                    for={@tip_form}
                    phx-submit="create_tip"
                    class="lg:col-span-4 space-y-4 sm:space-y-6"
                  >
                    <div class="grid grid-cols-1 xl:grid-cols-2 gap-y-4 sm:gap-y-6 gap-x-3">
                      <.input
                        label="GitHub Username"
                        field={@tip_form[:github_handle]}
                        placeholder="jsmith"
                      />
                      <.input
                        label="Amount"
                        icon="tabler-currency-dollar"
                        field={@tip_form[:amount]}
                        class="placeholder:text-blue-500"
                      />
                    </div>
                    <.input
                      label="URL"
                      field={@tip_form[:url]}
                      placeholder="https://github.com/owner/repo/issues/123"
                      helptext="We'll comment to notify the developer."
                    />
                    <div class="flex flex-col gap-2">
                      <.button
                        size="lg"
                        class="w-full drop-shadow-[0_1px_5px_#60a5fa80]"
                        variant="blue"
                      >
                        Tip contributor
                      </.button>
                    </div>
                  </.form>
                </div>
              </div>

              <div>
                <img
                  src={~p"/images/screenshots/tip-remotion.png"}
                  alt="Tip contributor"
                  class="w-full h-full object-contain"
                  loading="lazy"
                />
              </div>
            </div>
          </div>
        </section>

        <section class="relative isolate overflow-hidden bg-background py-16 sm:py-40">
          <div class="z-30 relative mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="mb-8 text-3xl font-bold text-card-foreground text-center">
              <span class="text-muted-foreground">The open source</span>
              <span class="block sm:inline">Upwork for engineers</span>
            </h2>
            <div class="flex justify-center gap-4">
              <.button navigate={~p"/auth/signup"}>
                Get started
              </.button>
              <.button href={AlgoraWeb.Constants.get(:github_repo_url)} variant="secondary">
                <.icon name="github" class="size-4 mr-2 -ml-1" /> View source code
              </.button>
            </div>
          </div>
        </section>

        <div class="relative isolate overflow-hidden bg-gradient-to-br from-black to-background">
          <Footer.footer />
          <div class="mx-auto max-w-2xl px-6 pb-4 text-center text-[0.6rem] text-muted-foreground/50">
            Upwork® is a registered trademark of Upwork Global Inc. Algora is not affiliated with, sponsored by, or endorsed by Upwork Global Inc, mmmkay?
          </div>
        </div>
      </main>
    </div>

    <.dialog
      id="video-modal"
      show={false}
      class="aspect-video h-full sm:h-auto w-full lg:max-w-none p-2 sm:p-4 lg:p-[5rem]"
      on_cancel={
        %JS{}
        |> JS.set_attribute({"src", ""}, to: "#video-modal-iframe")
        |> JS.set_attribute({"title", ""}, to: "#video-modal-iframe")
      }
    >
      <.dialog_content class="flex items-center justify-center">
        <iframe
          id="video-modal-iframe"
          frameborder="0"
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
          referrerpolicy="strict-origin-when-cross-origin"
          allowfullscreen
          class="aspect-[9/16] sm:aspect-video w-full bg-black"
        >
        </iframe>
      </.dialog_content>
    </.dialog>
    """
  end

  @impl true
  def handle_event("create_bounty" = event, %{"bounty_form" => params} = unsigned_params, socket) do
    changeset =
      %BountyForm{}
      |> BountyForm.changeset(params)
      |> Map.put(:action, :validate)

    amount = get_field(changeset, :amount)
    ticket_ref = get_field(changeset, :ticket_ref)

    if changeset.valid? do
      if user = socket.assigns[:current_user] do
        case Bounties.create_bounty(%{creator: user, owner: user, amount: amount, ticket_ref: ticket_ref}) do
          {:ok, _bounty} ->
            user |> change(last_context: user.handle) |> Repo.update()

            {:noreply,
             socket
             |> put_flash(:info, "Bounty created")
             |> redirect(to: AlgoraWeb.UserAuth.generate_login_path(user.email))}

          {:error, :already_exists} ->
            {:noreply, put_flash(socket, :warning, "You have already created a bounty for this ticket")}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Something went wrong")}
        end
      else
        {:noreply,
         socket
         |> assign(:pending_action, {event, unsigned_params})
         |> push_event("open_popup", %{url: socket.assigns.oauth_url})}
      end
    else
      {:noreply, assign(socket, :bounty_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("create_tip" = event, %{"tip_form" => params} = unsigned_params, socket) do
    changeset =
      %TipForm{}
      |> TipForm.changeset(params)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      if user = socket.assigns[:current_user] do
        with {:ok, token} <- Accounts.get_access_token(user),
             {:ok, recipient} <-
               Workspace.ensure_user(token, get_field(changeset, :github_handle)),
             {:ok, checkout_url} <-
               Bounties.create_tip(%{
                 creator: user,
                 owner: user,
                 recipient: recipient,
                 amount: get_field(changeset, :amount)
               }) do
          user |> change(last_context: user.handle) |> Repo.update()
          {:noreply, redirect(socket, to: AlgoraWeb.UserAuth.generate_login_path(user.email, checkout_url))}
        else
          {:error, reason} ->
            Logger.error("Failed to create tip: #{inspect(reason)}")
            {:noreply, put_flash(socket, :error, "Something went wrong")}
        end
      else
        {:noreply,
         socket
         |> assign(:pending_action, {event, unsigned_params})
         |> push_event("open_popup", %{url: socket.assigns.oauth_url})}
      end
    else
      {:noreply, assign(socket, :tip_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("submit_repo", %{"repo_form" => params}, socket) do
    changeset =
      %RepoForm{}
      |> RepoForm.changeset(params)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      url = get_field(changeset, :url)

      case Algora.Util.parse_github_url(url) do
        {:ok, {repo_owner, repo_name}} ->
          token = Github.TokenPool.get_token()

          case Workspace.ensure_repository(token, repo_owner, repo_name) do
            {:ok, _repo} ->
              {:noreply, push_navigate(socket, to: ~p"/go/#{repo_owner}/#{repo_name}")}

            {:error, reason} ->
              Logger.error("Failed to create repository: #{inspect(reason)}")
              {:noreply, assign(socket, :repo_form, to_form(add_error(changeset, :url, "Repository not found")))}
          end

        {:error, message} ->
          {:noreply, assign(socket, :repo_form, to_form(add_error(changeset, :url, message)))}
      end
    else
      {:noreply, assign(socket, :repo_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_info({:authenticated, user}, socket) do
    socket = assign(socket, :current_user, user)

    case socket.assigns.pending_action do
      {event, params} ->
        socket = assign(socket, :pending_action, nil)
        handle_event(event, params, socket)

      nil ->
        {:noreply, socket}
    end
  end

  defp dev_card(assigns) do
    ~H"""
    <.link navigate={User.url(@dev)} target="_blank" class="relative">
      <img
        src={@dev.avatar_url}
        alt={@dev.name}
        class="aspect-square w-full rounded-xl rounded-b-none bg-muted object-cover shadow-lg ring-1 ring-border"
      />
      <div class="font-display mt-1 rounded-xl rounded-t-none bg-card/50 p-3 text-sm ring-1 ring-border backdrop-blur-sm">
        <div class="font-semibold text-foreground">
          {@dev.name} {Algora.Misc.CountryEmojis.get(@dev.country)}
        </div>
        <div class="mt-0.5 text-xs font-medium text-foreground line-clamp-2">{@dev.bio}</div>
        <div class="hidden mt-1 text-sm">
          <div class="-ml-1 flex h-6 flex-wrap gap-1 overflow-hidden p-px text-sm">
            <%= for tech <- @dev.tech_stack do %>
              <span class="rounded-xl bg-muted/50 px-2 py-0.5 text-xs text-muted-foreground ring-1 ring-border">
                {tech}
              </span>
            <% end %>
          </div>
        </div>
        <div class="mt-0.5 text-xs text-muted-foreground">
          <span class="font-medium">Total Earned:</span>
          <span class="text-sm font-bold text-success">
            {Money.to_string!(@dev.total_earned, no_fraction_if_integer: true)}
          </span>
        </div>
      </div>
    </.link>
    """
  end

  defp get_total_paid_out do
    subtotal =
      Repo.one(
        from(t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          select: sum(t.net_amount)
        )
      ) || Money.new(0, :USD)

    subtotal |> Money.add!(PlatformStats.get().extra_paid_out) |> Money.round(currency_digits: 0)
  end

  defp get_completed_bounties_count do
    bounties_subtotal =
      Repo.one(
        from(t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          where: not is_nil(t.bounty_id),
          select: count(fragment("DISTINCT (?, ?)", t.bounty_id, t.user_id))
        )
      ) || 0

    tips_subtotal =
      Repo.one(
        from(t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          where: not is_nil(t.tip_id),
          select: count(fragment("DISTINCT (?, ?)", t.tip_id, t.user_id))
        )
      ) || 0

    bounties_subtotal + tips_subtotal + PlatformStats.get().extra_completed_bounties
  end

  defp get_contributors_count do
    subtotal =
      Repo.one(
        from(t in Transaction,
          where: t.type == :credit,
          where: t.status == :succeeded,
          where: not is_nil(t.linked_transaction_id),
          select: count(fragment("DISTINCT ?", t.user_id))
        )
      ) || 0

    subtotal + PlatformStats.get().extra_contributors
  end

  defp get_countries_count do
    Repo.one(
      from(u in User,
        join: t in Transaction,
        on: t.user_id == u.id,
        where: t.type == :credit,
        where: t.status == :succeeded,
        where: not is_nil(t.linked_transaction_id),
        where: not is_nil(u.country) and u.country != "",
        select: count(fragment("DISTINCT ?", u.country))
      )
    ) || 0
  end

  defp format_money(money), do: money |> Money.round(currency_digits: 0) |> Money.to_string!(no_fraction_if_integer: true)

  defp format_number(number), do: Number.Delimit.number_to_delimited(number, precision: 0)

  defp yc_logo_cloud(assigns) do
    ~H"""
    <div>
      <div class="grid grid-cols-3 lg:grid-cols-3 items-center justify-center gap-x-5 gap-y-4 sm:gap-x-12 sm:gap-y-12">
        <.link
          class="font-bold font-display text-base sm:text-3xl whitespace-nowrap flex items-center justify-center"
          navigate={~p"/org/browser-use"}
        >
          <img
            class="size-4 sm:size-7 mr-2 sm:mr-4"
            src="https://browser-use.com/logo.svg"
            loading="lazy"
          /> Browser Use
        </.link>
        <.link class="relative flex items-center justify-center" navigate={~p"/org/outerbase"}>
          <svg viewBox="0 0 123 16" fill="none" xmlns="http://www.w3.org/2000/svg" class="w-[80%]">
            <path
              fill-rule="evenodd"
              clip-rule="evenodd"
              d="M73.862 4.6368C74.3447 4.1028 75.3921 3.2509 77.1721 3.2509C79.7667 3.2509 81.7277 5.8024 81.7321 9.1846C81.7321 13.5714 79.7063 15.9195 76.5946 15.9195C74.6451 15.9195 73.915 14.6081 73.8687 14.5248C73.8674 14.5225 73.8664 14.5208 73.8664 14.5208H73.5431C73.1207 15.2456 72.3277 15.733 71.4183 15.733L68.4617 15.7288C68.3323 15.7288 68.2246 15.6228 68.2246 15.4957V15.0082C68.2246 14.9362 68.2548 14.8684 68.3109 14.826L68.8108 14.4276C69.3581 13.991 69.677 13.3341 69.677 12.6432L69.6814 3.0856C69.6814 2.3905 69.3624 1.7335 68.8108 1.297L68.4143 0.9833C68.2936 0.8858 68.2246 0.7417 68.2246 0.5891V0.5044C68.2246 0.2246 68.453 0 68.7375 0H71.8666C72.9656 0.0042 73.862 0.8816 73.862 1.9666V4.6368ZM75.3706 13.9232C76.1205 13.9232 76.6722 13.3341 77.0084 12.1685C77.323 11.0792 77.3574 9.795 77.3532 9.2906C77.3532 6.5695 76.6463 5.1327 75.3016 5.1327C74.5861 5.1327 73.8577 5.9168 73.8577 6.6882L73.8922 12.2702C73.8922 13.3425 74.6551 13.9232 75.3706 13.9232Z"
              fill="currentColor"
            >
            </path>
            <path
              fill-rule="evenodd"
              clip-rule="evenodd"
              d="M8.03335 0.2C3.60316 0.2 0 3.74183 0 8.09995C0 12.454 3.60316 16 8.03335 16C12.4635 16 16.0667 12.4582 16.0667 8.09995C16.0667 3.74183 12.4635 0.2 8.03335 0.2ZM11.0196 13.5382L10.9793 13.5892C10.5591 14.0952 10.045 14.261 9.68735 14.3077C9.59348 14.3205 9.49961 14.3248 9.4013 14.3248C8.42674 14.3248 7.44325 13.6742 6.5581 12.4369C5.83837 11.4292 5.21251 10.0856 4.79676 8.6527C4.05914 6.0973 4.14408 3.76731 5.01134 2.71287C5.43156 2.20686 5.94566 2.04104 6.30329 1.99429C7.31807 1.85816 8.35521 2.44071 9.294 3.67372C10.0718 4.69425 10.7424 6.10161 11.1895 7.64501C11.9181 10.1622 11.8466 12.4667 11.0196 13.5382Z"
              fill="currentColor"
            >
            </path>
            <path
              d="M42.4345 13.3935C42.1543 13.4825 41.8267 13.5292 41.469 13.5292C40.176 13.5292 39.4046 12.6476 39.4046 11.1726C39.4046 10.5101 39.4126 8.05114 39.4177 6.50448L39.4178 6.4819C39.4201 5.78395 39.4218 5.27668 39.4218 5.2134V4.9591C39.4218 4.9549 39.426 4.9548 39.426 4.9548H41.7406C42.0465 4.9548 42.2922 4.7133 42.2922 4.4123V4.0945C42.2922 3.7935 42.0465 3.5519 41.7406 3.5519H39.4088C39.4046 3.5519 39.4046 3.5477 39.4046 3.5477V1.1276C39.4046 0.775796 39.1158 0.491797 38.758 0.491797H38.4994C38.2495 0.491797 38.0125 0.606196 37.8658 0.805397C37.3831 1.4582 36.06 2.9501 33.7455 3.4587C33.53 3.5307 33.3835 3.7342 33.3835 3.9588V4.3742C33.3835 4.6709 33.6292 4.9125 33.9309 4.9125H35.198C35.2023 4.9125 35.2023 4.9167 35.2023 4.9167V11.961C35.2023 12.9061 35.4825 15.9832 39.1029 15.9832C41.0768 15.9832 42.3741 14.5506 42.8439 13.9361C42.9257 13.8259 42.9387 13.6775 42.8697 13.5546C42.7836 13.4105 42.6026 13.3427 42.4345 13.3935Z"
              fill="currentColor"
            >
            </path>
            <path
              fill-rule="evenodd"
              clip-rule="evenodd"
              d="M43.4471 9.63387C43.4471 6.13297 46.2399 3.28477 49.6707 3.28477C52.9677 3.28477 55.3598 5.95497 55.3555 9.62967C55.3555 9.71447 55.3555 9.80347 55.3512 9.88817C55.3468 10.0323 55.2218 10.1468 55.071 10.1468H47.8475L47.9596 10.4859C48.6017 12.4355 49.9336 13.3807 52.0368 13.3807C53.3384 13.3807 54.1357 13.1476 54.5581 12.9611C54.6659 12.9145 54.7866 12.9441 54.8641 13.0289L54.8685 13.0332C54.9503 13.1306 54.9547 13.2663 54.8771 13.3637C54.4116 13.9741 52.6446 15.9831 49.6707 15.9831C46.2399 15.9831 43.4471 13.1349 43.4471 9.63387ZM48.507 4.67497C47.6018 4.82327 47.2356 6.46357 47.5847 8.76927H51.3688C50.774 6.59917 49.6016 4.49697 48.507 4.67497Z"
              fill="currentColor"
            >
            </path>
            <path
              d="M105.626 8.70137L105.621 8.69968C104.213 8.1536 102.88 7.63637 102.88 6.47197C102.88 5.60736 103.501 5.02666 104.428 5.02666C105.751 5.02666 106.307 6.15407 106.484 6.63727C106.518 6.73477 106.621 6.80256 106.733 6.80687C106.837 6.80687 107.466 6.80686 108.013 6.81106C108.483 6.81106 108.862 6.43386 108.858 5.97606L108.845 4.36976C108.841 3.91626 108.466 3.54746 108.005 3.54746H107.72C107.358 3.54746 107.018 3.71706 106.806 4.00946L106.471 4.47147C106.471 4.47147 105.548 3.29316 103.174 3.29316C100.527 3.29316 98.2902 5.04786 98.2902 7.12896C98.2902 9.97589 100.72 10.7794 102.68 11.4272L102.691 11.431C103.945 11.8421 105.023 12.1981 105.023 13.0458C105.023 13.4654 104.772 13.9655 103.583 13.9655C102.109 13.9655 100.876 12.7279 100.54 12.1642C100.493 12.0837 100.402 12.0328 100.307 12.0328L99.2168 12.0371C98.7944 12.0371 98.454 12.3761 98.454 12.7915V14.9997C98.454 15.4151 98.7944 15.7499 99.2168 15.7542H99.5271C99.8202 15.7542 100.096 15.6312 100.286 15.4151L100.88 14.7369C100.88 14.7369 102.075 15.9957 104.531 15.9957C107.501 15.9957 109.651 14.6267 109.651 12.7406C109.651 10.2654 107.514 9.43466 105.626 8.70137Z"
              fill="currentColor"
            >
            </path>
            <path
              d="M25.3246 3.54336H31.2853C31.5999 3.54336 31.8585 3.79346 31.8542 4.10286C31.8542 4.27236 31.7766 4.43346 31.643 4.53946L31.3888 4.74286C30.7638 5.23876 30.3974 5.98896 30.3974 6.78156V12.4823C30.3974 13.2748 30.7638 14.025 31.3931 14.5252L31.643 14.7244C31.7766 14.8303 31.8542 14.9914 31.8542 15.1609C31.8542 15.4746 31.5956 15.7246 31.281 15.7246H28.514C27.5917 15.7246 26.803 15.1948 26.4323 14.4319L26.1522 14.4362C26.1522 14.4362 24.7471 15.9874 22.5533 15.9874C19.9501 15.9874 18.3037 14.2412 18.3037 11.4354V6.56966C18.2865 5.89576 17.9718 5.26416 17.4374 4.84036L17.0624 4.54366C16.9288 4.43766 16.8512 4.27666 16.8512 4.10706C16.8512 3.79346 17.1098 3.54336 17.4245 3.54336H20.7345C21.7042 3.54336 22.493 4.31906 22.493 5.27266V11.5117C22.493 11.5133 22.4928 11.5149 22.4926 11.5165C22.4923 11.5184 22.4919 11.5202 22.4914 11.522L22.4908 11.5243C22.4897 11.5285 22.4886 11.5328 22.4886 11.5371C22.4973 12.9993 23.2472 13.9445 24.3979 13.9445C25.4841 13.9445 26.1521 12.9866 26.2082 12.9019V6.78576C26.2082 5.99316 25.8418 5.23876 25.2126 4.74286L24.9626 4.54366C24.829 4.43766 24.7514 4.27666 24.7514 4.10706C24.7514 3.79346 25.01 3.54336 25.3246 3.54336Z"
              fill="currentColor"
            >
            </path>
            <path
              d="M65.4149 3.25098C63.9496 3.25098 62.885 4.23428 62.2816 5.45488L61.9928 5.45918L61.9885 5.45488C61.8118 4.37408 60.8635 3.54758 59.7128 3.54758H56.9458C56.6312 3.54758 56.3726 3.79768 56.3726 4.11138C56.3726 4.28088 56.4502 4.44198 56.5838 4.54788L56.9587 4.84458C57.5105 5.28118 57.8294 5.93808 57.8294 6.63318V12.6475C57.8294 13.3384 57.5105 13.9953 56.9631 14.4319L56.5838 14.7328C56.4502 14.8388 56.3726 14.9998 56.3726 15.1694C56.3726 15.4788 56.6269 15.7331 56.9458 15.7331H62.9066C63.2212 15.7331 63.4798 15.483 63.4798 15.1694C63.4798 14.9998 63.4022 14.8388 63.2686 14.7328L62.8935 14.4361C62.3419 13.9996 62.023 13.3426 62.023 12.6475V7.05278C62.023 6.71798 62.3074 6.25598 62.704 6.25598C62.9887 6.25598 63.1994 6.52205 63.4552 6.84495C63.8498 7.34321 64.3516 7.97678 65.3977 7.97678C66.751 7.97678 67.7595 6.93408 67.7595 5.60328C67.7553 4.01388 66.6993 3.25098 65.4149 3.25098Z"
              fill="currentColor"
            >
            </path>
            <path
              fill-rule="evenodd"
              clip-rule="evenodd"
              d="M117.099 3.28477C113.668 3.28477 110.875 6.13297 110.875 9.63387C110.875 13.1349 113.668 15.9831 117.099 15.9831C120.072 15.9831 121.84 13.9741 122.305 13.3637C122.383 13.2663 122.379 13.1306 122.296 13.0332L122.292 13.0289C122.215 12.9441 122.094 12.9145 121.986 12.9611C121.564 13.1476 120.767 13.3807 119.465 13.3807C117.361 13.3807 116.03 12.4355 115.388 10.4859L115.276 10.1468H122.499C122.65 10.1468 122.775 10.0323 122.779 9.88817C122.783 9.80347 122.783 9.71447 122.783 9.62967C122.787 5.95497 120.392 3.28477 117.099 3.28477ZM115.008 8.76927C114.66 6.46357 115.026 4.82327 115.931 4.67497C117.026 4.49697 118.197 6.59917 118.792 8.76927H115.008Z"
              fill="currentColor"
            >
            </path>
            <path
              fill-rule="evenodd"
              clip-rule="evenodd"
              d="M96.6568 4.54368L96.4068 4.74288C95.7776 5.23878 95.4156 5.98898 95.4156 6.78578V12.6433C95.4156 13.3384 95.7345 13.9911 96.2819 14.4277L96.6611 14.7286C96.7948 14.8345 96.8724 14.9956 96.8724 15.1651C96.8724 15.4788 96.6138 15.7288 96.2991 15.7288L92.8813 15.7458C92.4891 15.7458 92.1356 15.5169 91.9805 15.1609L91.5408 14.1522L91.2133 14.1564C91.2133 14.1564 91.2114 14.1593 91.2088 14.1635C91.1314 14.288 90.0758 15.9874 88.0067 15.9874C85.4078 15.9874 83.451 13.4359 83.451 10.0494C83.451 5.92118 85.5242 3.25098 88.7308 3.25098C90.4763 3.25098 91.5279 4.68778 91.5366 4.70048L91.7176 4.95478L92.1787 4.03928C92.3296 3.73408 92.6054 3.54338 92.9718 3.54338H96.2948C96.6138 3.54338 96.868 3.79768 96.868 4.10708C96.868 4.27668 96.7904 4.43768 96.6568 4.54368ZM87.8214 9.61278C87.8214 12.2449 88.5153 13.6351 89.8255 13.6351C90.4978 13.6351 91.1788 12.9357 91.2262 12.2152V11.27L91.2004 6.73068C91.2004 5.69228 90.4591 5.13278 89.7609 5.13278C89.0281 5.13278 88.4894 5.70498 88.1618 6.83238C87.8559 7.88348 87.8214 9.12538 87.8214 9.61278Z"
              fill="currentColor"
            >
            </path>
          </svg>
        </.link>
        <.link class="relative flex items-center justify-center" navigate={~p"/org/triggerdotdev"}>
          <img
            src="https://algora.io/banners/triggerdotdev.png"
            alt="Trigger.dev"
            class="col-auto sm:w-[90%] saturate-0"
            loading="lazy"
          />
        </.link>
        <.link class="relative flex items-center justify-center" navigate={~p"/org/traceloop"}>
          <img
            src="https://cdn.prod.website-files.com/664553b7af7a800a7911b9f0/664553f95f4ec29495eb8eb9_traceloop%20logo%20dark%20bg.png"
            alt="Traceloop"
            class="sm:w-[90%] col-auto saturate-0"
            loading="lazy"
          />
        </.link>
        <.link
          class="font-bold font-display text-base sm:text-3xl whitespace-nowrap flex items-center justify-center"
          navigate={~p"/org/trieve"}
        >
          <img
            src="https://cdn.trieve.ai/trieve-logo.png"
            alt="Trieve logo"
            class="size-8 sm:size-12 mr-2 brightness-0 invert"
            loading="lazy"
          /> Trieve
        </.link>
        <.link
          class="font-bold font-display text-base sm:text-3xl whitespace-nowrap flex items-center justify-center"
          navigate={~p"/org/twentyhq"}
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            xmlns:xlink="http://www.w3.org/1999/xlink"
            viewBox="0 0 40 40"
            class="shrink-0 size-4 sm:size-7 mr-2 sm:mr-4"
          >
            <path
              fill="currentColor"
              d="M 34.95 0 L 5.05 0 C 2.262 0 0 2.262 0 5.05 L 0 34.95 C 0 37.738 2.262 40 5.05 40 L 34.95 40 C 37.738 40 40 37.738 40 34.95 L 40 5.05 C 40 2.262 37.738 0 34.95 0 Z M 8.021 14.894 C 8.021 12.709 9.794 10.935 11.979 10.935 L 19.6 10.935 C 19.712 10.935 19.815 11.003 19.862 11.106 C 19.909 11.209 19.888 11.329 19.812 11.415 L 18.141 13.229 C 17.85 13.544 17.441 13.726 17.012 13.726 L 12 13.726 C 11.344 13.726 10.812 14.259 10.812 14.915 L 10.812 17.909 C 10.812 18.294 10.5 18.606 10.115 18.606 L 8.721 18.606 C 8.335 18.606 8.024 18.294 8.024 17.909 L 8.024 14.894 Z M 31.729 25.106 C 31.729 27.291 29.956 29.065 27.771 29.065 L 24.532 29.065 C 22.347 29.065 20.574 27.291 20.574 25.106 L 20.574 19.438 C 20.574 19.053 20.718 18.682 20.979 18.397 L 22.868 16.347 C 22.947 16.262 23.071 16.232 23.182 16.274 C 23.291 16.318 23.365 16.421 23.365 16.538 L 23.365 25.088 C 23.365 25.744 23.897 26.276 24.553 26.276 L 27.753 26.276 C 28.409 26.276 28.941 25.744 28.941 25.088 L 28.941 14.915 C 28.941 14.259 28.409 13.726 27.753 13.726 L 24.032 13.726 C 23.606 13.726 23.2 13.906 22.909 14.218 L 11.812 26.276 L 18.479 26.276 C 18.865 26.276 19.176 26.588 19.176 26.974 L 19.176 28.368 C 19.176 28.753 18.865 29.065 18.479 29.065 L 9.494 29.065 C 8.679 29.065 8.018 28.403 8.018 27.588 L 8.018 26.85 C 8.018 26.479 8.156 26.124 8.409 25.85 L 20.85 12.335 C 21.674 11.441 22.829 10.935 24.044 10.935 L 27.768 10.935 C 29.953 10.935 31.726 12.709 31.726 14.894 L 31.726 25.106 Z"
            />
          </svg>
          Twenty
        </.link>
        <.link class="relative flex items-center justify-center" navigate={~p"/org/aidenybai"}>
          <img
            src="https://algora.io/banners/million.png"
            alt="Million"
            class="col-auto w-[80%] saturate-0"
            loading="lazy"
          />
        </.link>
        <.link class="relative flex items-center justify-center" navigate={~p"/org/moonrepo"}>
          <img src="https://moonrepo.dev/img/logo.svg" alt="moon" class="w-[80%]" loading="lazy" />
        </.link>
        <.link class="relative flex items-center justify-center" navigate={~p"/org/highlight"}>
          <img
            src="https://algora.io/banners/highlight.png"
            alt="Highlight"
            class="col-auto sm:w-[90%] saturate-0"
            loading="lazy"
          />
        </.link>
        <.link class="relative flex items-center justify-center" navigate={~p"/org/dittofeed"}>
          <img
            src="https://algora.io/banners/dittofeed.png"
            alt="Dittofeed"
            class="col-auto w-[80%] brightness-0 invert"
            loading="lazy"
          />
        </.link>

        <.link
          class="relative flex items-center justify-center brightness-0 invert"
          navigate={~p"/org/onyx-dot-app"}
        >
          <img
            src="https://onyx.app/Onyx.png"
            alt="Onyx Logo"
            class="object-contain w-[60%]"
            loading="lazy"
          />
        </.link>

        <.link
          class="font-bold font-display text-base sm:text-3xl whitespace-nowrap flex items-center justify-center brightness-0 invert"
          aria-label="Logo"
          navigate={~p"/org/mendableai"}
        >
          🔥
          Firecrawl
        </.link>

        <.link class="relative flex items-center justify-center" navigate={~p"/org/keephq"}>
          <img
            src={~p"/images/wordmarks/keep.png"}
            alt="Keep"
            class="col-auto w-[70%] sm:w-[50%]"
            loading="lazy"
          />
        </.link>

        <.link
          class="font-bold font-display text-base sm:text-3xl whitespace-nowrap flex items-center justify-center"
          navigate={~p"/org/windmill-labs"}
        >
          <img
            src="https://windmill.dev/img/windmill.svg"
            alt="Windmill"
            class="size-4 sm:size-10 mr-2 saturate-0"
            loading="lazy"
          /> Windmill
        </.link>

        <.link class="relative flex items-center justify-center" navigate={~p"/org/panoratech"}>
          <img
            src="https://getpanora.com/wp-content/uploads/2023/09/logo-panora.png"
            alt="Panora"
            class="col-auto w-[60%] sm:w-[50%] saturate-0 brightness-0 invert"
            loading="lazy"
          />
        </.link>
      </div>
    </div>
    """
  end

  defp pattern(assigns) do
    ~H"""
    <div
      class="absolute inset-x-0 -top-40 -z-10 transform overflow-hidden blur-3xl sm:-top-80"
      aria-hidden="true"
    >
      <div
        class="left-[calc(50%-11rem)] aspect-[1155/678] w-[36.125rem] rotate-[30deg] relative -translate-x-1/2 bg-gradient-to-tr from-gray-400 to-secondary opacity-20 sm:left-[calc(50%-30rem)] sm:w-[72.1875rem]"
        style="clip-path: polygon(74.1% 44.1%, 100% 61.6%, 97.5% 26.9%, 85.5% 0.1%, 80.7% 2%, 72.5% 32.5%, 60.2% 62.4%, 52.4% 68.1%, 47.5% 58.3%, 45.2% 34.5%, 27.5% 76.7%, 0.1% 64.9%, 17.9% 100%, 27.6% 76.8%, 76.1% 97.7%, 74.1% 44.1%)"
      >
      </div>
    </div>

    <div class="[mask-image:radial-gradient(32rem_32rem_at_center,white,transparent)] absolute inset-x-0 -z-10 h-screen w-full stroke-border">
      <defs>
        <pattern
          id="grid-pattern"
          width="200"
          height="200"
          x="50%"
          y="-1"
          patternUnits="userSpaceOnUse"
        >
          <path d="M.5 200V.5H200" fill="none" />
        </pattern>
      </defs>
      <rect width="100%" height="100%" stroke-width="0" fill="url(#grid-pattern)" opacity="0.25" />
    </div>

    <div class="absolute inset-x-0 -z-10 transform overflow-hidden blur-3xl" aria-hidden="true">
      <div
        class="left-[calc(50%+3rem)] aspect-[1155/678] w-[36.125rem] relative -translate-x-1/2 bg-gradient-to-tr from-gray-400 to-secondary opacity-20 sm:left-[calc(50%+36rem)] sm:w-[72.1875rem]"
        style="clip-path: polygon(74.1% 44.1%, 100% 61.6%, 97.5% 26.9%, 85.5% 0.1%, 80.7% 2%, 72.5% 32.5%, 60.2% 62.4%, 52.4% 68.1%, 47.5% 58.3%, 45.2% 34.5%, 27.5% 76.7%, 0.1% 64.9%, 17.9% 100%, 27.6% 76.8%, 76.1% 97.7%, 74.1% 44.1%)"
      >
      </div>
    </div>
    """
  end
end
