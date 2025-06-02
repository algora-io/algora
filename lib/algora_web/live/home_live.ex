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

  defp placeholder_text do
    """
    - GitHub looks like a green carpet, red flag if wearing suit
    - Great communication skills, can talk to customers
    - Must be a shark, aggressive, has urgency and agency
    - Has contributions to open source inference engines (like vLLM)
    """
  end

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
        <section class="relative isolate min-h-[calc(100vh)]">
          <div class="h-full mx-auto max-w-[88rem] px-6 lg:px-8 flex flex-col items-center justify-center pt-32 pb-12">
            <div class="h-full mx-auto lg:mx-0 flex lg:max-w-none items-center justify-center text-center w-full">
              <div class="w-full flex flex-col lg:flex-row lg:justify-center gap-6">
                <div class="w-full flex flex-col items-center lg:items-start text-center lg:text-left">
                  <h1 class="font-display text-3xl sm:text-lg md:text-5xl xl:text-[3.25rem] font-semibold tracking-tight text-foreground">
                    Meet your new <span class="text-emerald-400">hire today</span>
                  </h1>
                  <p class="mt-4 text-lg leading-8 text-muted-foreground max-w-2xl">
                    Access a network of top 1% engineers, pre-vetted through their OSS contributions.
                    <span class="font-semibold">Only pay when you hire.</span>
                  </p>
                  <ul class="mt-2 flex flex-col gap-2 text-sm">
                    <li class="flex items-center text-left text-foreground/80">
                      <.icon
                        name="tabler-square-rounded-number-1"
                        class="size-6 mr-2 shrink-0 text-foreground/80"
                      />
                      <span class="font-medium leading-7 whitespace-nowrap">
                        Submit JD
                      </span>
                    </li>
                    <li class="flex items-center text-left text-foreground/80">
                      <.icon
                        name="tabler-square-rounded-number-2"
                        class="size-6 mr-2 shrink-0 text-foreground/80"
                      />
                      <span class="font-medium leading-7 whitespace-nowrap">
                        Receive matches <span class="text-emerald-300">within hours</span>
                      </span>
                    </li>
                    <li class="flex items-center text-left text-foreground/80">
                      <.icon
                        name="tabler-square-rounded-number-3"
                        class="size-6 mr-2 shrink-0 text-foreground/80"
                      />
                      <span class="font-medium leading-7 whitespace-nowrap">
                        Interview <span class="text-emerald-300">within days</span>
                      </span>
                    </li>
                  </ul>
                  <img
                    src="/images/screenshots/job-candidates.png"
                    alt="Job candidates"
                    class="-ml-2 mt-4 rounded-xl object-cover max-w-[48rem]"
                    style="aspect-ratio: 1556/816;"
                  />
                  <%!-- <div class="pt-4 sm:max-w-[40rem] grid w-full grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-y-4 gap-x-4 mx-auto items-center justify-center sm:ml-0">
                    <.link class="relative flex items-center justify-center" href={~p"/cal"}>
                      <Wordmarks.calcom class="w-[80%] col-auto" alt="Cal.com" />
                    </.link>
                    <.link class="relative flex items-center justify-center" href={~p"/qdrant"}>
                      <Wordmarks.qdrant class="w-[80%] col-auto" alt="Qdrant" />
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
                    <.link class="relative flex items-center justify-center" href={~p"/golemcloud"}>
                      <Wordmarks.golemcloud class="col-auto w-[80%]" alt="Golem Cloud" />
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
                  </div> --%>
                </div>

                <div class="w-full max-w-[34rem] text-left -mt-4">
                  <div class="rounded-xl bg-card text-card-foreground shadow-2xl ring-1 ring-white/10">
                    <div class="p-8">
                      <h2 class="text-3xl font-semibold leading-7 text-white">
                        View your candidates
                      </h2>
                      <p class="pt-2 text-sm text-muted-foreground">
                        Share your JD to receive your candidates within hours.
                      </p>

                      <form class="mt-6 flex flex-col gap-6">
                        <.input
                          type="textarea"
                          name="job_description"
                          value=""
                          label="Job description / careers URL"
                          rows="4"
                          placeholder="Tell us about the role and your requirements..."
                        />
                        <.input
                          type="textarea"
                          name="job_description"
                          value=""
                          label="Describe your ideal candidate, heuristics, green/red flags etc."
                          rows="4"
                          placeholder={placeholder_text()}
                        />
                        <.input
                          name="email"
                          value=""
                          label="Work email"
                          placeholder="you@company.com"
                        />
                        <div class="flex flex-col gap-4">
                          <.button class="w-full">Receive your candidates</.button>
                          <div class="text-xs text-muted-foreground text-center">
                            No credit card required - only pay when you hire
                          </div>
                        </div>
                      </form>
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
              Latest from the community
            </h2>
            <div class="grid gap-4 max-w-2xl mx-auto">
              <div class="flex items-center gap-4 rounded-lg bg-card p-4">
                <img
                  src="https://notes.fm/images/favicon.png"
                  alt="Notes"
                  class="size-12 rounded-lg bg-background p-2"
                />
                <div class="flex-1">
                  <p class="text-foreground">Notes hired with Algora</p>
                  <p class="text-sm text-muted-foreground">May 5, 2025</p>
                </div>
              </div>

              <div class="flex items-center gap-4 rounded-lg bg-card p-4">
                <img
                  src="https://notes.fm/images/favicon.png"
                  alt="Notes"
                  class="size-12 rounded-lg bg-background p-2"
                />
                <div class="flex-1">
                  <p class="text-foreground">Notes hired with Algora</p>
                  <p class="text-sm text-muted-foreground">May 5, 2025</p>
                </div>
              </div>

              <div class="flex items-center gap-4 rounded-lg bg-card p-4">
                <img
                  src="https://avatars.githubusercontent.com/u/181807673?s=200&v=4"
                  alt="Outspeed"
                  class="size-12 rounded-lg bg-background p-2"
                />
                <div class="flex-1">
                  <p class="text-foreground">Outspeed is hiring with Algora</p>
                  <p class="text-sm text-muted-foreground">May 12, 2025</p>
                </div>
              </div>

              <div class="flex items-center gap-4 rounded-lg bg-card p-4">
                <img
                  src="https://avatars.githubusercontent.com/u/142257755?s=200&v=4"
                  alt="DotTxt"
                  class="size-12 rounded-lg bg-background p-2"
                />
                <div class="flex-1">
                  <p class="text-foreground">.txt is hiring with Algora</p>
                  <p class="text-sm text-muted-foreground">May 15, 2025</p>
                </div>
              </div>

              <div class="flex items-center gap-4 rounded-lg bg-card p-4">
                <img
                  src="https://avatars.githubusercontent.com/u/139391156?s=200&v=4"
                  alt="Turso"
                  class="size-12 rounded-lg bg-background p-2"
                />
                <div class="flex-1">
                  <p class="text-foreground">Turso launches open source challenge</p>
                  <p class="text-sm text-muted-foreground">May 18, 2025</p>
                </div>
              </div>

              <div class="flex items-center gap-4 rounded-lg bg-card p-4">
                <img
                  src="https://avatars.githubusercontent.com/u/129894407?v=4"
                  alt="Prequel"
                  class="size-12 rounded-lg bg-background p-2"
                />
                <div class="flex-1">
                  <p class="text-foreground">Prequel launches bounty program</p>
                  <p class="text-sm text-muted-foreground">May 22, 2025</p>
                </div>
              </div>

              <div class="flex items-center gap-4 rounded-lg bg-card p-4">
                <img
                  src="https://avatars.githubusercontent.com/u/194294730?s=200&v=4"
                  alt="Unsiloed"
                  class="size-12 rounded-lg bg-background p-2"
                />
                <div class="flex-1">
                  <p class="text-foreground">Unsiloed launches bounty program</p>
                  <p class="text-sm text-muted-foreground">May 25, 2025</p>
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
