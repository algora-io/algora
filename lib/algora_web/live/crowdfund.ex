defmodule AlgoraWeb.CrowdfundLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

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
  def mount(params, _session, socket) do
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
     |> assign(:page_title, "Crowdfund")
     |> assign(:page_image, "#{AlgoraWeb.Endpoint.url()}/og/crowdfund")
     |> assign(:screenshot?, not is_nil(params["screenshot"]))
     |> assign(:oauth_url, Github.authorize_url(%{socket_id: socket.id}))
     |> assign(:featured_devs, Accounts.list_featured_developers())
     |> assign(:stats, stats)
     |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
     |> assign(:tip_form, to_form(TipForm.changeset(%TipForm{}, %{})))
     |> assign(:repo_form, to_form(RepoForm.changeset(%RepoForm{}, %{})))
     |> assign(:pending_action, nil)
     |> assign(:plans1, AlgoraWeb.PricingLive.get_plans1())
     |> assign(:plans2, AlgoraWeb.PricingLive.get_plans2())}
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

      <main class="bg-black relative overflow-hidden">
        <section class="relative isolate py-16 sm:py-40">
          <div class="hidden md:block">
            <.pattern />
          </div>
          <div class="mx-auto 2xl:max-w-[90rem] px-6 lg:px-8 pt-24 xl:pt-0">
            <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-2 sm:mb-4">
              Crowdfund GitHub issues
            </h2>
            <p class="text-center font-medium text-base text-muted-foreground mb-8 sm:mb-16">
              Fund GitHub issues with USD rewards and pay when work is merged
            </p>
            <div class="flex flex-col">
              <div class="relative grid items-center grid-cols-1 lg:grid-cols-5 w-full gap-8 lg:gap-x-12 rounded-xl bg-black/25 p-4 sm:p-8 lg:p-12 ring-2 ring-success/20 transition-colors">
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
                <div class="lg:col-span-3 text-sm text-muted-foreground">
                  <.icon name="tabler-sparkles" class="size-4 text-current mr-1" /> Comment
                  <code class="px-1 py-0.5 text-success">/bounty $1000</code>
                  on GitHub issues and PRs (requires GitHub auth)
                </div>
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
                      src={~p"/images/people/alex-klimaj.jpg"}
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
                      src={~p"/images/people/andrew-wilkins.jpg"}
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
                  href={~p"/coollabsio"}
                  rel="noopener"
                  class="relative flex flex-col sm:flex-row items-start sm:items-center gap-4 sm:gap-x-4 rounded-xl bg-black p-4 sm:p-6 ring-1 ring-border transition-colors"
                >
                  <div class="flex -space-x-4 shrink-0">
                    <img
                      class="size-20 rounded-full z-0"
                      src={~p"/images/logos/coolify.jpg"}
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

        <section class="relative isolate py-16 sm:py-40">
          <div class="mx-auto 2xl:max-w-[90rem] px-6 lg:px-8">
            <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-2 sm:mb-4">
              Did you know?
            </h2>
            <p class="text-center font-medium text-base text-muted-foreground mb-8 sm:mb-16">
              You can tip your favorite open source contributors with Algora.
            </p>

            <div class="flex flex-col lg:flex-row gap-8">
              <div class="w-full lg:max-w-6xl relative rounded-2xl bg-black/25 p-4 sm:p-8 lg:p-12 ring-1 ring-indigo-500/20 transition-colors backdrop-blur-sm">
                <div class="grid grid-cols-1 items-center lg:grid-cols-7 gap-8 h-full">
                  <div class="lg:col-span-3 text-base leading-6">
                    <h3 class="text-2xl sm:text-3xl font-semibold text-foreground">
                      Tip any contributor <br class="hidden lg:block" />
                      <span class="text-indigo-500 drop-shadow-[0_1px_5px_#60a5fa80]">instantly</span>
                    </h3>
                    <p class="mt-4 text-base sm:text-lg font-medium text-muted-foreground">
                      Support the maintainers behind your favorite open source projects
                    </p>
                    <div class="mt-4 sm:mt-6 space-y-3">
                      <div class="flex items-center gap-2 text-sm text-muted-foreground">
                        <.icon name="tabler-check" class="h-5 w-5 text-indigo-400 flex-none" />
                        <span>Send tips directly to GitHub usernames</span>
                      </div>
                      <div class="flex items-center gap-2 text-sm text-muted-foreground">
                        <.icon name="tabler-check" class="h-5 w-5 text-indigo-400 flex-none" />
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
                        label="GitHub handle"
                        field={@tip_form[:github_handle]}
                        placeholder="jsmith"
                      />
                      <.input
                        label="Amount"
                        icon="tabler-currency-dollar"
                        field={@tip_form[:amount]}
                        class="placeholder:text-indigo-500"
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
                        class="w-full drop-shadow-[0_1px_5px_#818cf880]"
                        variant="indigo"
                      >
                        Tip contributor
                      </.button>
                    </div>
                  </.form>
                </div>
              </div>

              <div class="order-first lg:order-last">
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

        <section class="relative isolate py-16 sm:py-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="mb-8 text-3xl font-bold text-card-foreground text-center">
              <span class="text-muted-foreground">The open source</span>
              <span class="block sm:inline">Upwork for engineers</span>
            </h2>
            <div class="flex justify-center gap-4">
              <.button navigate={~p"/auth/signup"}>
                Get started
              </.button>
              <.button
                class="pointer-events-none opacity-75"
                href={AlgoraWeb.Constants.get(:github_repo_url)}
                variant="secondary"
              >
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
            {:noreply, put_flash(socket, :warning, "You already have a bounty for this ticket")}

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
          token = Algora.Admin.token()

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
