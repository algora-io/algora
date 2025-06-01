defmodule AlgoraWeb.HomeLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

  import AlgoraWeb.Components.ModalVideo
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Bounties
  alias Algora.Jobs
  alias Algora.Jobs.JobPosting
  alias Algora.Payments
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias AlgoraWeb.Components.Footer
  alias AlgoraWeb.Components.Header
  alias AlgoraWeb.Components.Wordmarks
  alias AlgoraWeb.Data.PlatformStats
  alias AlgoraWeb.Forms.BountyForm
  alias AlgoraWeb.Forms.TipForm
  alias Phoenix.LiveView.AsyncResult

  require Logger

  @impl true
  def mount(params, _session, socket) do
    total_contributors = get_contributors_count()
    total_countries = get_countries_count()

    stats = [
      %{label: "Paid Out", value: format_money(get_total_paid_out())},
      %{label: "Completed Bounties", value: format_number(get_completed_bounties_count())},
      %{label: "Contributors", value: format_number(total_contributors)},
      %{label: "Countries", value: format_number(total_countries)}
    ]

    featured_devs = Accounts.list_featured_developers()

    jobs_by_user = Enum.group_by(Jobs.list_jobs(), & &1.user)

    bounties0 =
      Bounties.list_bounties(
        status: :open,
        owner_handles: Algora.Settings.get_featured_orgs()
      )

    bounties1 =
      Bounties.list_bounties(
        status: :open,
        limit: 3,
        amount_gt: Money.new(:USD, 500)
      )

    bounties = bounties0 ++ bounties1

    case socket.assigns[:current_user] do
      %{handle: handle} = user when is_binary(handle) ->
        {:ok, redirect(socket, to: AlgoraWeb.UserAuth.signed_in_path(user))}

      _ ->
        {:ok,
         socket
         |> assign(:page_title, "Algora - Hire the top 1% open source engineers")
         |> assign(:page_title_suffix, "")
         |> assign(:page_image, "#{AlgoraWeb.Endpoint.url()}/images/og/home.png")
         |> assign(:screenshot?, not is_nil(params["screenshot"]))
         |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
         |> assign(:tip_form, to_form(TipForm.changeset(%TipForm{}, %{})))
         |> assign(:featured_devs, featured_devs)
         |> assign(:stats, stats)
         |> assign(:form, to_form(JobPosting.changeset(%JobPosting{}, %{})))
         |> assign(:jobs_by_user, jobs_by_user)
         |> assign(:user_metadata, AsyncResult.loading())
         |> assign(:transactions, Payments.list_featured_transactions())
         |> assign(:bounties, bounties)
         |> assign_events()
         |> assign_user_applications()}
    end
  end

  defp assign_events(socket) do
    events =
      (socket.assigns.transactions || [])
      |> Enum.map(fn tx -> %{item: tx, type: :transaction, timestamp: tx.succeeded_at} end)
      |> Enum.concat(
        (socket.assigns.jobs_by_user || [])
        |> Enum.flat_map(fn {_user, jobs} -> jobs end)
        |> Enum.map(fn job -> %{item: job, type: :job, timestamp: job.inserted_at} end)
      )
      |> Enum.concat(
        Enum.map(socket.assigns.bounties || [], fn bounty ->
          %{item: bounty, type: :bounty, timestamp: bounty.inserted_at}
        end)
      )
      |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})

    assign(socket, :events, events)
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
        <section class="relative isolate">
          <div class="h-full mx-auto max-w-7xl px-6 lg:px-8 flex flex-col items-center justify-center pt-36 pb-12">
            <div class="h-full mx-auto lg:mx-0 flex lg:max-w-none items-center justify-center text-center w-full">
              <div class="w-full flex flex-col lg:flex-row gap-6">
                <div class="flex-1 flex flex-col items-center lg:items-start text-center lg:text-left">
                  <h1 class="font-display text-3xl sm:text-lg md:text-5xl xl:text-[3.25rem] font-semibold tracking-tight text-foreground">
                    Meet your new <span class="text-emerald-400">hire today</span>
                  </h1>
                  <p class="mt-6 text-lg leading-8 text-muted-foreground max-w-xl">
                    Access a curated network of top 1% engineers, pre-vetted through their open source contributions. Only pay when you hire.
                  </p>
                  <div class="pt-6 flex-1 mr-auto max-w-xl flex flex-col justify-between">
                    <figure class="relative flex flex-col rounded-xl bg-card text-card-foreground shadow-2xl ring-1 ring-white/10 p-6">
                      <blockquote class="text-base font-medium text-foreground/90 flex-grow">
                        <p>
                          "Algora helped us meet Nick, who after being contracted a few months, joined the Trigger founding team full-time.
                        </p>
                        <p class="pt-4">
                          It was the easiest hire and turned out to be very very good."
                        </p>
                      </blockquote>
                      <figcaption class="mt-4 flex items-center gap-x-4">
                        <img
                          src="/images/people/eric-allam.jpg"
                          alt="Eric Allam"
                          class="h-12 w-12 rounded-full object-cover bg-gray-800"
                          loading="lazy"
                        />
                        <div class="text-xs">
                          <div class="text-sm font-semibold text-foreground">Eric Allam</div>
                          <div class="text-foreground/90 font-medium">Co-founder & CTO</div>
                          <div class="text-muted-foreground font-medium">
                            Trigger.dev <span class="text-orange-400">(YC W23)</span>
                          </div>
                        </div>
                      </figcaption>
                    </figure>
                  </div>
                  <div class="sm:max-w-2xl grid w-full grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-y-4 gap-x-4 mx-auto items-center justify-center sm:ml-0">
                    <.link class="relative flex items-center justify-center" href={~p"/cal"}>
                      <Wordmarks.calcom class="w-[80%] col-auto" alt="Cal.com" />
                    </.link>
                    <.link class="relative flex items-center justify-center" href={~p"/qdrant"}>
                      <Wordmarks.qdrant class="w-[80%] col-auto" alt="Qdrant" />
                    </.link>
                    <.link class="relative flex items-center justify-center" href={~p"/remotion"}>
                      <img
                        loading="eager"
                        src={~p"/images/wordmarks/remotion.png"}
                        alt="Remotion"
                        class="col-auto w-full saturate-0"
                      />
                    </.link>
                    <.link class="relative flex items-center justify-center" href={~p"/zio"}>
                      <img
                        loading="eager"
                        src={~p"/images/wordmarks/zio.png"}
                        alt="ZIO"
                        class="mt-1 sm:mt-3 w-[70%] col-auto brightness-0 invert"
                      />
                    </.link>
                    <.link
                      class="relative flex items-center justify-center"
                      navigate={~p"/activepieces"}
                    >
                      <img
                        loading="eager"
                        src={~p"/images/wordmarks/activepieces.svg"}
                        alt="Activepieces"
                        class="col-auto brightness-0 invert"
                      />
                    </.link>
                    <.link class="relative flex items-center justify-center" href={~p"/tembo"}>
                      <img
                        loading="eager"
                        src={~p"/images/wordmarks/tembo.png"}
                        alt="Tembo"
                        class="col-auto saturate-0"
                      />
                    </.link>
                    <.link class="relative flex items-center justify-center" href={~p"/maybe-finance"}>
                      <img
                        loading="eager"
                        src={~p"/images/wordmarks/maybe.png"}
                        alt="Maybe"
                        class="col-auto w-full saturate-0"
                      />
                    </.link>
                    <.link class="relative flex items-center justify-center" href={~p"/golemcloud"}>
                      <Wordmarks.golemcloud class="col-auto w-[80%]" alt="Golem Cloud" />
                    </.link>
                    <.link class="relative flex items-center justify-center" href={~p"/deskflow"}>
                      <img
                        loading="eager"
                        src={~p"/images/wordmarks/synergy.svg"}
                        alt="Synergy"
                        class="col-auto saturate-0 invert w-[80%]"
                      />
                    </.link>
                    <.link class="relative flex items-center justify-center" href={~p"/Capgo"}>
                      <img
                        loading="eager"
                        src={~p"/images/wordmarks/capgo.png"}
                        alt="Capgo"
                        class="col-auto w-[80%]"
                      />
                    </.link>
                    <.link class="relative flex items-center justify-center" href={~p"/tracemachina"}>
                      <img
                        loading="eager"
                        src={~p"/images/wordmarks/nativelink.png"}
                        alt="Nativelink"
                        class="col-auto saturate-0"
                      />
                    </.link>
                    <.link class="relative flex items-center justify-center" href={~p"/softwaremill"}>
                      <img
                        loading="eager"
                        src={~p"/images/wordmarks/softwaremill.png"}
                        alt="Softwaremill"
                        class="col-auto invert"
                      />
                    </.link>
                    <.link class="relative flex items-center justify-center" href={~p"/CapSoftware"}>
                      <Wordmarks.cap class="col-auto saturate-0 invert w-[80%]" alt="Cap" />
                    </.link>
                    <.link
                      class="relative flex items-center justify-center"
                      href={~p"/spaceandtimelabs"}
                    >
                      <img
                        loading="eager"
                        src={~p"/images/wordmarks/spaceandtimelabs.svg"}
                        alt="Space and Time"
                        class="col-auto saturate-0"
                      />
                    </.link>
                    <.link
                      class="font-bold font-display text-base sm:text-base whitespace-nowrap flex items-center justify-center"
                      navigate={~p"/getkyo"}
                    >
                      <img
                        loading="eager"
                        src={~p"/images/logos/kyo.png"}
                        alt="Kyo"
                        class="size-6 sm:size-5 mr-1 sm:mr-1 saturate-0 invert"
                      /> Kyo
                    </.link>
                    <.link class="relative flex items-center justify-center" href={~p"/permitio"}>
                      <img
                        loading="eager"
                        src={~p"/images/wordmarks/permit.svg"}
                        alt="Permit"
                        class="col-auto saturate-0"
                      />
                    </.link>
                    <.link
                      class="font-bold font-display text-lg sm:text-lg whitespace-nowrap flex items-center justify-center"
                      navigate={~p"/coollabsio"}
                    >
                      Coolify
                    </.link>
                    <.link class="relative flex items-center justify-center" href={~p"/encoredev"}>
                      <img
                        loading="eager"
                        src={~p"/images/wordmarks/encore.svg"}
                        alt="Encore"
                        class="col-auto invert w-[70%]"
                      />
                    </.link>
                    <.link class="relative flex items-center justify-center" href={~p"/tolgee"}>
                      <img
                        loading="eager"
                        src={~p"/images/wordmarks/tolgee.png"}
                        alt="Tolgee"
                        class="col-auto w-[80%]"
                      />
                    </.link>
                    <.link
                      class="font-bold font-display text-base sm:text-base whitespace-nowrap flex items-center justify-center"
                      navigate={~p"/keygen-sh"}
                    >
                      <img
                        loading="eager"
                        src={~p"/images/wordmarks/keygen.svg"}
                        alt="Keygen"
                        class="saturate-0 w-5 sm:w-4 mr-1 sm:mr-1"
                      /> keygen
                    </.link>
                    <.link
                      class="font-bold font-display text-sm sm:text-base whitespace-nowrap flex items-center justify-center"
                      navigate={~p"/browser-use"}
                    >
                      <img
                        loading="eager"
                        src={~p"/images/wordmarks/browser-use.svg"}
                        alt="Browser Use"
                        class="saturate-0 w-4 sm:w-4 mr-1 sm:mr-1"
                      /> Browser Use
                    </.link>
                    <.link
                      class="font-bold font-display text-base sm:text-base whitespace-nowrap flex items-center justify-center"
                      navigate={~p"/tscircuit"}
                    >
                      <img
                        loading="eager"
                        src={~p"/images/logos/tscircuit.svg"}
                        alt="TSC"
                        class="saturate-0 invert w-5 sm:w-5 mr-1 sm:mr-1"
                      /> tscircuit
                    </.link>
                    <.link
                      class="font-bold font-display text-sm sm:text-base whitespace-nowrap flex items-center justify-center"
                      navigate={~p"/prefix-dev"}
                    >
                      <img
                        loading="eager"
                        src={~p"/images/logos/prefix.svg"}
                        alt="TSC"
                        class="saturate-0 w-6 sm:w-5 mr-1 sm:mr-1"
                      /> Prefix.dev
                    </.link>
                    <.link
                      class="font-extrabold font-mono text-base sm:text-base whitespace-nowrap flex items-center justify-center"
                      navigate={~p"/mediar-ai"}
                    >
                      <img
                        loading="eager"
                        src={~p"/images/logos/screenpipe.webp"}
                        alt="Screenpipe"
                        class="shrink-0 saturate-0 w-5 sm:w-6 mr-1 sm:mr-1"
                      /> screenpipe
                    </.link>
                  </div>
                </div>

                <div class="flex-1 max-w-md text-left">
                  <div class="rounded-xl bg-card text-card-foreground shadow-2xl ring-1 ring-white/10">
                    <div class="p-8">
                      <h2 class="text-2xl font-semibold leading-7 text-white">
                        View your candidates today
                      </h2>
                      <ul class="mt-4 space-y-4 md:space-y-1 text-sm">
                        <li class="flex w-full items-center text-left text-white">
                          <.icon name="tabler-square-rounded-number-1" class="size-6 mr-2 shrink-0" />
                          <span class="font-medium leading-7">
                            Submit your job description
                          </span>
                        </li>
                        <li class="flex w-full items-center text-left text-white">
                          <.icon name="tabler-square-rounded-number-2" class="size-6 mr-2 shrink-0" />
                          <span class="font-medium leading-7">
                            Receive your candidates <span class="text-emerald-300">within hours</span>
                          </span>
                        </li>
                        <li class="flex w-full items-center text-left text-white">
                          <.icon name="tabler-square-rounded-number-3" class="size-6 mr-2 shrink-0" />
                          <span class="font-medium leading-7">
                            Interview <span class="text-emerald-300">within days</span>
                          </span>
                        </li>
                      </ul>

                      <form class="mt-8 flex flex-col gap-6">
                        <div>
                          <.input
                            type="textarea"
                            name="job_description"
                            value=""
                            label="Job description / careers URL"
                            rows="4"
                            placeholder="Tell us about the role and your requirements..."
                          />
                        </div>
                        <.input
                          name="email"
                          value=""
                          label="Work email"
                          placeholder="you@company.com"
                        />
                        <.button class="w-full">Receive your candidates</.button>
                      </form>
                    </div>

                    <div class="border-t border-white/10 px-8 py-4">
                      <div class="flex items-center gap-x-3">
                        <.icon name="tabler-shield-check" class="size-5 text-emerald-400" />
                        <div class="text-xs text-muted-foreground">
                          Your information is secure and will never be shared
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
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
            <%!-- <div class="flex justify-center gap-4">
              <.button navigate={~p"/auth/signup"}>
                Get started
              </.button>
              <.button href={AlgoraWeb.Constants.get(:github_repo_url)} variant="secondary">
                <.icon name="github" class="size-4 mr-2 -ml-1" /> View source code
              </.button>
            </div> --%>
          </div>
        </section>

        <div class="relative isolate overflow-hidden bg-gradient-to-br from-black to-background">
          <Footer.footer />
        </div>
      </main>
    </div>

    <.modal_video_dialog />
    """
  end

  @impl true
  def handle_event("create_bounty", _params, socket) do
    {:noreply, redirect(socket, to: ~p"/auth/signup")}
  end

  @impl true
  def handle_event("create_tip", _params, socket) do
    {:noreply, redirect(socket, to: ~p"/auth/signup")}
  end

  @impl true
  def handle_event("email_changed", %{"job_posting" => %{"email" => email}}, socket) do
    if String.match?(email, ~r/^[^\s]+@[^\s]+$/i) do
      {:noreply, start_async(socket, :fetch_metadata, fn -> Algora.Crawler.fetch_user_metadata(email) end)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("validate_job", %{"job_posting" => params}, socket) do
    {:noreply, assign(socket, :form, to_form(JobPosting.changeset(socket.assigns.form.source, params)))}
  end

  @impl true
  def handle_event("create_job", %{"job_posting" => params}, socket) do
    with {:ok, user} <-
           Accounts.get_or_register_user(params["email"], %{type: :organization, display_name: params["company_name"]}),
         {:ok, job} <- params |> Map.put("user_id", user.id) |> Jobs.create_job_posting() do
      Algora.Activities.alert("Job posting initialized: #{job.company_name}", :critical)
      {:noreply, redirect(socket, external: AlgoraWeb.Constants.get(:calendar_url))}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}

      {:error, reason} ->
        Logger.error("Failed to create job posting: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Something went wrong. Please try again.")}
    end
  end

  @impl true
  def handle_event("apply_job", %{"job-id" => job_id}, socket) do
    if socket.assigns[:current_user] do
      if Accounts.has_fresh_token?(socket.assigns.current_user) do
        case Jobs.create_application(job_id, socket.assigns.current_user) do
          {:ok, _application} ->
            {:noreply, assign_user_applications(socket)}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to submit application. Please try again.")}
        end
      else
        {:noreply, redirect(socket, external: Algora.Github.authorize_url(%{return_to: "/jobs"}))}
      end
    else
      {:noreply, redirect(socket, external: Algora.Github.authorize_url(%{return_to: "/jobs"}))}
    end
  end

  @impl true
  def handle_async(:fetch_metadata, {:ok, metadata}, socket) do
    {:noreply,
     socket
     |> assign(:user_metadata, AsyncResult.ok(socket.assigns.user_metadata, metadata))
     |> assign(:form, to_form(change(socket.assigns.form.source, company_name: get_in(metadata, [:org, :og_title]))))}
  end

  @impl true
  def handle_async(:fetch_metadata, {:exit, reason}, socket) do
    {:noreply, assign(socket, :user_metadata, AsyncResult.failed(socket.assigns.user_metadata, reason))}
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

  defp assign_user_applications(socket) do
    user_applications =
      if socket.assigns[:current_user] do
        Jobs.list_user_applications(socket.assigns.current_user)
      else
        MapSet.new()
      end

    assign(socket, :user_applications, user_applications)
  end

  defp events(assigns) do
    ~H"""
    <ul class="w-full pl-10 relative space-y-8">
      <li :for={{event, index} <- @events |> Enum.with_index()} class="relative">
        <.event_item type={event.type} event={event} last?={index == length(@events) - 1} />
      </li>
    </ul>
    """
  end

  defp event_item(%{type: :transaction} = assigns) do
    assigns = assign(assigns, :transaction, assigns.event.item)

    ~H"""
    <div>
      <div class="relative -ml-[2.75rem]">
        <span
          :if={!@last?}
          class="absolute left-1 top-6 h-full w-0.5 block ml-[2.75rem] bg-muted-foreground/25"
          aria-hidden="true"
        >
        </span>
        <.link
          rel="noopener"
          target="_blank"
          class="w-full group inline-flex"
          href={
            if @transaction.ticket.repository,
              do: @transaction.ticket.url,
              else: ~p"/#{@transaction.linked_transaction.user.handle}/home"
          }
        >
          <div class="w-full relative flex space-x-3">
            <div class="w-full flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
              <div class="w-full flex items-center gap-3">
                <div class="flex -space-x-1 ring-8 ring-black">
                  <span class="relative shrink-0 overflow-hidden flex h-9 w-9 sm:h-12 sm:w-12 items-center justify-center rounded-xl ring-4 bg-gray-950 ring-black">
                    <img
                      class="aspect-square h-full w-full"
                      alt={@transaction.user.name}
                      src={@transaction.user.avatar_url}
                    />
                  </span>
                  <span class="relative shrink-0 overflow-hidden flex h-9 w-9 sm:h-12 sm:w-12 items-center justify-center rounded-xl ring-4 bg-gray-950 ring-black">
                    <img
                      class="aspect-square h-full w-full"
                      alt={@transaction.linked_transaction.user.name}
                      src={@transaction.linked_transaction.user.avatar_url}
                    />
                  </span>
                </div>
                <div class="w-full z-10 flex gap-3 items-start xl:items-end">
                  <p class="text-xs transition-colors text-muted-foreground group-hover:text-foreground/90 sm:text-xl text-left">
                    <span class="font-semibold text-foreground/80 group-hover:text-foreground transition-colors">
                      {@transaction.linked_transaction.user.name}
                    </span>
                    awarded
                    <span class="font-semibold text-foreground/80 group-hover:text-foreground transition-colors">
                      {@transaction.user.name}
                    </span>
                    a
                    <span class={
                      classes([
                        "font-bold font-display transition-colors",
                        cond do
                          @transaction.bounty_id && @transaction.ticket.repository ->
                            "text-success-400 group-hover:text-success-300"

                          @transaction.bounty_id && !@transaction.ticket.repository ->
                            "text-blue-400 group-hover:text-blue-300"

                          true ->
                            "text-red-400 group-hover:text-red-300"
                        end
                      ])
                    }>
                      {Money.to_string!(@transaction.net_amount)}
                      <%= if @transaction.bounty_id do %>
                        <%= if @transaction.ticket.repository do %>
                          bounty
                        <% else %>
                          contract
                        <% end %>
                      <% else %>
                        tip
                      <% end %>
                    </span>
                  </p>
                  <div class="ml-auto xl:ml-0 xl:mb-[2px] whitespace-nowrap text-xs text-muted-foreground sm:text-sm">
                    <time datetime={@transaction.succeeded_at}>
                      {cond do
                        @transaction.bounty_id && !@transaction.ticket.repository ->
                          start_month = Calendar.strftime(@transaction.succeeded_at, "%B")
                          end_date = Date.add(@transaction.succeeded_at, 30)
                          end_month = Calendar.strftime(end_date, "%B")

                          if start_month == end_month do
                            "#{start_month} #{Calendar.strftime(end_date, "%Y")}"
                          else
                            "#{start_month} - #{end_month} #{Calendar.strftime(end_date, "%Y")}"
                          end

                        true ->
                          Algora.Util.time_ago(@transaction.succeeded_at)
                      end}
                    </time>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </.link>
      </div>
    </div>
    """
  end

  defp event_item(%{type: :job} = assigns) do
    assigns = assign(assigns, :job, assigns.event.item)

    ~H"""
    <div>
      <div class="relative -ml-[2.75rem]">
        <span
          :if={!@last?}
          class="absolute left-1 top-6 h-full w-0.5 block ml-[2.75rem] bg-muted-foreground/25"
          aria-hidden="true"
        >
        </span>
        <.link
          rel="noopener"
          target="_blank"
          class="w-full group inline-flex"
          href={~p"/#{@job.user.handle}/jobs"}
        >
          <div class="w-full relative flex space-x-3">
            <div class="w-full flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
              <div class="w-full flex items-center gap-3">
                <div class="flex -space-x-1 ring-8 ring-black">
                  <span class="ml-6 relative shrink-0 overflow-hidden flex h-9 w-9 sm:h-12 sm:w-12 items-center justify-center rounded-xl">
                    <img
                      class="aspect-square h-full w-full"
                      alt={@job.user.name}
                      src={@job.user.avatar_url}
                    />
                  </span>
                </div>
                <div class="w-full z-10 flex gap-3 items-start xl:items-end">
                  <p class="text-xs transition-colors text-muted-foreground group-hover:text-foreground/90 sm:text-xl text-left">
                    <span class="font-semibold text-foreground/80 group-hover:text-foreground transition-colors">
                      {@job.user.name}
                    </span>
                    is hiring!
                    <span class="font-semibold text-purple-400 group-hover:text-purple-300 transition-colors">
                      {@job.title}
                    </span>
                  </p>
                  <div class="ml-auto xl:ml-0 xl:mb-[2px] whitespace-nowrap text-xs text-muted-foreground sm:text-sm">
                    <time datetime={@job.inserted_at}>
                      {Algora.Util.time_ago(@job.inserted_at)}
                    </time>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </.link>
      </div>
    </div>
    """
  end

  defp event_item(%{type: :bounty} = assigns) do
    assigns = assign(assigns, :bounty, assigns.event.item)

    ~H"""
    <div>
      <div class="relative -ml-[2.75rem]">
        <span
          :if={!@last?}
          class="absolute left-1 top-6 h-full w-0.5 block ml-[2.75rem] bg-muted-foreground/25"
          aria-hidden="true"
        >
        </span>
        <.link
          rel="noopener"
          target="_blank"
          class="w-full group inline-flex"
          href={
            if @bounty.repository,
              do: @bounty.ticket.url,
              else: ~p"/#{@bounty.owner.handle}/home"
          }
        >
          <div class="w-full relative flex space-x-3">
            <div class="w-full flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
              <div class="w-full flex items-center gap-3">
                <div class="flex -space-x-1 ring-8 ring-black">
                  <span class="ml-6 relative shrink-0 overflow-hidden flex h-9 w-9 sm:h-12 sm:w-12 items-center justify-center rounded-xl bg-gray-950">
                    <img
                      class="aspect-square h-full w-full"
                      alt={@bounty.owner.name}
                      src={@bounty.owner.avatar_url}
                    />
                  </span>
                </div>
                <div class="w-full z-10 flex gap-3 items-start xl:items-end">
                  <p class="text-xs transition-colors text-muted-foreground group-hover:text-foreground/90 sm:text-xl text-left">
                    <span class="font-semibold text-foreground/80 group-hover:text-foreground transition-colors">
                      {@bounty.owner.name}
                    </span>
                    shared a
                    <span class="font-bold font-display transition-colors text-cyan-400 group-hover:text-cyan-300">
                      {Money.to_string!(@bounty.amount)} bounty
                    </span>
                  </p>
                  <div class="ml-auto xl:ml-0 xl:mb-[2px] whitespace-nowrap text-xs text-muted-foreground sm:text-sm">
                    <time datetime={@bounty.inserted_at}>
                      {Algora.Util.time_ago(@bounty.inserted_at)}
                    </time>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </.link>
      </div>
    </div>
    """
  end

  # defp user_features do
  #   [
  #     %{
  #       title: "Bounties & contracts",
  #       description: "Work on new projects and grow your career",
  #       src: ~p"/images/screenshots/user-dashboard.png"
  #     },
  #     %{
  #       title: "Your new resume",
  #       description: "Showcase your open source contributions",
  #       src: ~p"/images/screenshots/profile.png"
  #     },
  #     %{
  #       title: "Embed on your site",
  #       description: "Let anyone share a bounty/contract with you",
  #       src: ~p"/images/screenshots/embed-profile.png"
  #     },
  #     %{
  #       title: "Payment history",
  #       description: "Monitor your earnings in real-time",
  #       src: ~p"/images/screenshots/user-transactions.png"
  #     }
  #   ]
  # end
end
