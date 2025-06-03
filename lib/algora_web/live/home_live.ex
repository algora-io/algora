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
  alias AlgoraWeb.Data.PlatformStats
  alias AlgoraWeb.Forms.BountyForm
  alias AlgoraWeb.Forms.TipForm
  alias Phoenix.LiveView.AsyncResult

  require Logger

  defmodule Form do
    @moduledoc false
    use Ecto.Schema

    @primary_key false
    @derive {Jason.Encoder, only: [:email, :job_description, :candidate_description]}
    embedded_schema do
      field :email, :string
      field :job_description, :string
      field :candidate_description, :string
    end

    def changeset(form, attrs \\ %{}) do
      form
      |> Ecto.Changeset.cast(attrs, [:email, :job_description, :candidate_description])
      |> Ecto.Changeset.validate_required([:email, :job_description])
      |> Ecto.Changeset.validate_format(:email, ~r/@/)
    end
  end

  defp placeholder_text do
    """
    - GitHub looks like a green carpet, red flag if wearing suit in pfp
    - Has contributions to open source inference engines (like vLLM)
    - Posts regularly on X and LinkedIn
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
         |> assign(:form, to_form(Form.changeset(%Form{}, %{})))
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
        <Header.header class="container" />
      <% end %>

      <main class="bg-black relative overflow-hidden">
        <section class="relative isolate xl:pb-16 2xl:pb-44">
          <div class="h-full mx-auto container px-6 lg:px-8 flex flex-col items-center justify-center pt-28 2xl:pt-48 pb-12">
            <div class="h-full mx-auto lg:mx-0 flex lg:max-w-none items-center justify-center text-center w-full">
              <div class="w-full flex flex-col lg:flex-row lg:justify-center gap-6">
                <div class="w-full flex flex-col items-center lg:items-start text-center lg:text-left">
                  <h1 class="font-display text-4xl sm:text-5xl md:text-6xl font-semibold tracking-tight text-foreground">
                    Meet your <br class="xl:hidden" />
                    <span class="text-emerald-400">new hire today</span>
                  </h1>
                  <p class="mt-2 2xl:mt-4 text-base xl:text-lg text-foreground max-w-2xl">
                    Access a network of top 1% engineers,<br class="xl:hidden" />
                    pre-vetted through OSS contributions. <br />
                    <span class="font-semibold">Only pay when you hire.</span>
                  </p>
                  <ul class="mt-2 2xl:mt-6 flex flex-col gap-1 xl:gap-2 text-sm">
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
                    class="-ml-2 mt-4 2xl:mt-10 object-cover w-full max-w-xl xl:max-w-[45rem]"
                    style="aspect-ratio: 1524/737;"
                  />
                </div>
                <div class="w-full max-w-xl mx-auto lg:max-w-lg 2xl:max-w-[34rem] text-left">
                  <div class="rounded-xl bg-card text-card-foreground shadow-2xl ring-1 ring-white/15">
                    <div class="p-6 2xl:p-10">
                      <h2 class="text-2xl 2xl:text-3xl font-semibold leading-7 text-white">
                        View your candidates
                      </h2>
                      <p class="pt-2 text-sm text-muted-foreground">
                        Share JD to receive matches within hours
                      </p>

                      <.form
                        for={@form}
                        phx-submit="submit"
                        class="mt-4 2xl:mt-6 flex flex-col gap-4 2xl:gap-6"
                      >
                        <.input
                          field={@form[:job_description]}
                          type="textarea"
                          label="Job description / careers URL"
                          rows="3"
                          placeholder="Tell us about the role and your requirements..."
                          class="resize-none"
                        />
                        <.input
                          field={@form[:candidate_description]}
                          type="textarea"
                          label="Describe your ideal candidate, heuristics, green/red flags etc."
                          rows="3"
                          placeholder={placeholder_text()}
                          class="resize-none"
                        />
                        <.input
                          field={@form[:email]}
                          type="email"
                          label="Work email"
                          placeholder="you@company.com"
                        />
                        <div class="flex flex-col gap-4">
                          <.button class="w-full" type="submit">Receive your candidates</.button>
                          <div class="text-xs text-muted-foreground text-center">
                            No credit card required - only pay when you hire
                          </div>
                        </div>
                      </.form>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section class="relative isolate pb-16 sm:pb-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8 pt-24 xl:pt-0">
            <img
              src={~p"/images/logos/yc.svg"}
              class="h-16 sm:h-24 mx-auto"
              alt="Y Combinator Logo"
              loading="lazy"
            />
            <h2 class="mt-4 sm:mt-8 font-display text-xl sm:text-3xl md:text-4xl lg:text-5xl xl:text-6xl font-semibold tracking-tight text-foreground text-center mb-4 !leading-[1.25]">
              Trusted by <br class="md:hidden" /> open source YC founders
            </h2>

            <div class="pt-4 sm:pt-8 flex flex-col md:flex-row gap-8 px-4">
              <div class="flex-1 mx-auto max-w-xl flex flex-col justify-between border ring-1 ring-border transition-all bg-card group rounded-xl text-card-foreground shadow p-6">
                <figure class="relative flex flex-col h-full">
                  <blockquote class="text-base xl:text-lg font-medium text-foreground/90 flex-grow">
                    <p>
                      "Algora helped us meet Nick, who after being contracted a few months, joined the Trigger founding team full-time.
                    </p>
                    <p class="pt-2 xl:pt-4">
                      It was the easiest hire and turned out to be very very good."
                    </p>
                  </blockquote>
                  <figcaption class="mt-4 xl:mt-8 flex items-center gap-3 xl:gap-4">
                    <img
                      src="/images/people/eric-allam.jpg"
                      alt="Eric Allam"
                      class="size-12 xl:size-16 rounded-full object-cover bg-gray-800"
                      loading="lazy"
                    />
                    <div>
                      <div class="text-sm xl:text-base font-semibold text-foreground">
                        Eric Allam
                      </div>
                      <div class="text-xs xl:text-sm text-foreground/90 font-medium">
                        Co-founder & CTO
                      </div>
                      <div class="text-xs xl:text-sm text-foreground/90 font-medium">
                        Trigger.dev <span class="text-orange-400">(YC W23)</span>
                      </div>
                    </div>
                  </figcaption>
                </figure>
              </div>

              <div class="flex-1 mx-auto max-w-xl flex flex-col justify-between border ring-1 ring-border transition-all bg-card group rounded-xl text-card-foreground shadow p-6">
                <figure class="relative flex flex-col h-full">
                  <blockquote class="text-base xl:text-lg font-medium text-foreground/90 flex-grow">
                    <p>
                      "Algora helped us meet Gergő and I couldn't be happier with the results. He's been working full-time with us for over a year now and is a key contributor to our product.
                    </p>

                    <p class="pt-2 xl:pt-4">
                      I think you realized this by now, but you have such a powerful sourcing/hiring engine in your hands!"
                    </p>
                  </blockquote>
                  <figcaption class="mt-4 xl:mt-8 flex items-center gap-3 xl:gap-4">
                    <img
                      src="/images/people/nicolas-camara.jpg"
                      alt="Nicolas Camara"
                      class="size-12 xl:size-16 rounded-full object-cover bg-gray-800"
                      loading="lazy"
                    />
                    <div>
                      <div class="text-sm xl:text-base font-semibold text-foreground">
                        Nicolas Camara
                      </div>
                      <div class="text-xs xl:text-sm text-foreground/90 font-medium">
                        Co-founder & CEO
                      </div>
                      <div class="text-xs xl:text-sm text-foreground/90 font-medium">
                        Firecrawl <span class="text-orange-400">(YC S22)</span>
                      </div>
                    </div>
                  </figcaption>
                </figure>
              </div>
            </div>
            <div class="mx-auto mt-8 max-w-5xl gap-12 text-sm leading-6 sm:mt-16">
              <.yc_logo_cloud />
            </div>
          </div>
        </section>

        <section class="relative isolate pb-16 sm:pb-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="font-display text-xl sm:text-3xl md:text-4xl lg:text-5xl xl:text-6xl font-semibold tracking-tight text-foreground text-center mb-4 !leading-[1.25]">
              Community highlights
            </h2>
            <p class="mt-2 text-lg text-muted-foreground text-center">
              See what's poppin' on Algora
            </p>

            <div class="mt-8 grid gap-4 max-w-2xl mx-auto">
              <%= for event <- events() do %>
                <.event_card event={event} />
              <% end %>
            </div>
          </div>
        </section>

        <section class="relative isolate pb-16 sm:pb-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <h2 class="font-display text-xl sm:text-3xl xl:text-6xl font-semibold tracking-tight text-foreground text-center !leading-[1.25]">
              Meet your new teammates today
            </h2>
            <div class="mt-6 sm:mt-10 flex gap-4 justify-center">
              <.button
                navigate={~p"/onboarding/org"}
                class="h-10 sm:h-14 rounded-md px-8 sm:px-12 text-sm sm:text-xl"
              >
                Start hiring
              </.button>
              <.button
                navigate={~p"/platform"}
                variant="secondary"
                class="h-10 sm:h-14 rounded-md px-8 sm:px-12 text-sm sm:text-xl"
              >
                Explore platform
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
  def handle_event("submit", %{"form" => params}, socket) do
    case %Form{} |> Form.changeset(params) |> Ecto.Changeset.apply_action(:save) do
      {:ok, data} ->
        Algora.Activities.alert(Jason.encode!(data), :critical)
        {:noreply, put_flash(socket, :info, "We'll send you matching candidates within the next few hours.")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
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

  defp yc_logo_cloud(assigns) do
    ~H"""
    <div>
      <div class="grid grid-cols-3 lg:grid-cols-3 items-center justify-center gap-x-5 gap-y-4 sm:gap-x-8 sm:gap-y-6  lg:gap-x-12 lg:gap-y-12">
        <.link
          class="font-bold font-display text-base sm:text-2xl lg:text-4xl whitespace-nowrap flex items-center justify-center"
          navigate={~p"/browser-use"}
        >
          <img
            class="size-4 sm:size-7 lg:size-10 mr-2 lg:mr-4"
            src={~p"/images/wordmarks/browser-use.svg"}
            loading="lazy"
          /> Browser Use
        </.link>
        <.link class="relative flex items-center justify-center" navigate={~p"/outerbase"}>
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
        <.link class="relative flex items-center justify-center" navigate={~p"/triggerdotdev"}>
          <img
            src={~p"/images/wordmarks/triggerdotdev.png"}
            alt="Trigger.dev"
            class="col-auto lg:w-[90%] saturate-0"
            loading="lazy"
          />
        </.link>
        <.link class="relative flex items-center justify-center" navigate={~p"/traceloop"}>
          <img
            src={~p"/images/wordmarks/traceloop.png"}
            alt="Traceloop"
            class="lg:w-[90%] col-auto saturate-0"
            loading="lazy"
          />
        </.link>
        <.link
          class="font-bold font-display text-base sm:text-3xl lg:text-5xl whitespace-nowrap flex items-center justify-center"
          navigate={~p"/trieve"}
        >
          <img
            src={~p"/images/wordmarks/trieve.png"}
            alt="Trieve logo"
            class="size-8 sm:size-12 lg:size-16 mr-2 brightness-0 invert"
            loading="lazy"
          /> Trieve
        </.link>
        <.link
          class="font-bold font-display text-base sm:text-3xl lg:text-5xl whitespace-nowrap flex items-center justify-center"
          navigate={~p"/twentyhq"}
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            xmlns:xlink="http://www.w3.org/1999/xlink"
            viewBox="0 0 40 40"
            class="shrink-0 size-4 sm:size-8 lg:size-10 mr-2 lg:mr-4"
          >
            <path
              fill="currentColor"
              d="M 34.95 0 L 5.05 0 C 2.262 0 0 2.262 0 5.05 L 0 34.95 C 0 37.738 2.262 40 5.05 40 L 34.95 40 C 37.738 40 40 37.738 40 34.95 L 40 5.05 C 40 2.262 37.738 0 34.95 0 Z M 8.021 14.894 C 8.021 12.709 9.794 10.935 11.979 10.935 L 19.6 10.935 C 19.712 10.935 19.815 11.003 19.862 11.106 C 19.909 11.209 19.888 11.329 19.812 11.415 L 18.141 13.229 C 17.85 13.544 17.441 13.726 17.012 13.726 L 12 13.726 C 11.344 13.726 10.812 14.259 10.812 14.915 L 10.812 17.909 C 10.812 18.294 10.5 18.606 10.115 18.606 L 8.721 18.606 C 8.335 18.606 8.024 18.294 8.024 17.909 L 8.024 14.894 Z M 31.729 25.106 C 31.729 27.291 29.956 29.065 27.771 29.065 L 24.532 29.065 C 22.347 29.065 20.574 27.291 20.574 25.106 L 20.574 19.438 C 20.574 19.053 20.718 18.682 20.979 18.397 L 22.868 16.347 C 22.947 16.262 23.071 16.232 23.182 16.274 C 23.291 16.318 23.365 16.421 23.365 16.538 L 23.365 25.088 C 23.365 25.744 23.897 26.276 24.553 26.276 L 27.753 26.276 C 28.409 26.276 28.941 25.744 28.941 25.088 L 28.941 14.915 C 28.941 14.259 28.409 13.726 27.753 13.726 L 24.032 13.726 C 23.606 13.726 23.2 13.906 22.909 14.218 L 11.812 26.276 L 18.479 26.276 C 18.865 26.276 19.176 26.588 19.176 26.974 L 19.176 28.368 C 19.176 28.753 18.865 29.065 18.479 29.065 L 9.494 29.065 C 8.679 29.065 8.018 28.403 8.018 27.588 L 8.018 26.85 C 8.018 26.479 8.156 26.124 8.409 25.85 L 20.85 12.335 C 21.674 11.441 22.829 10.935 24.044 10.935 L 27.768 10.935 C 29.953 10.935 31.726 12.709 31.726 14.894 L 31.726 25.106 Z"
            />
          </svg>
          Twenty
        </.link>
        <.link class="relative flex items-center justify-center" navigate={~p"/aidenybai"}>
          <img
            src={~p"/images/wordmarks/million.png"}
            alt="Million"
            class="col-auto w-[80%] saturate-0"
            loading="lazy"
          />
        </.link>
        <.link class="relative flex items-center justify-center" navigate={~p"/moonrepo"}>
          <img src={~p"/images/wordmarks/moonrepo.svg"} alt="moon" class="w-[80%]" loading="lazy" />
        </.link>
        <.link class="relative flex items-center justify-center" navigate={~p"/dittofeed"}>
          <img
            src={~p"/images/wordmarks/dittofeed.png"}
            alt="Dittofeed"
            class="col-auto w-[80%] brightness-0 invert"
            loading="lazy"
          />
        </.link>

        <.link
          class="relative flex items-center justify-center brightness-0 invert"
          navigate={~p"/onyx-dot-app"}
        >
          <img
            src={~p"/images/wordmarks/onyx.png"}
            alt="Onyx Logo"
            class="object-contain w-[60%]"
            loading="lazy"
          />
        </.link>

        <.link
          class="font-bold font-display text-base sm:text-3xl lg:text-4xl whitespace-nowrap flex items-center justify-center brightness-0 invert"
          aria-label="Logo"
          navigate={~p"/mendableai"}
        >
          🔥
          Firecrawl
        </.link>

        <.link class="relative flex items-center justify-center" navigate={~p"/keephq"}>
          <img
            src={~p"/images/wordmarks/keep.png"}
            alt="Keep"
            class="col-auto w-[70%] lg:w-[50%]"
            loading="lazy"
          />
        </.link>

        <.link
          class="font-bold font-display text-base sm:text-3xl lg:text-5xl whitespace-nowrap flex items-center justify-center"
          navigate={~p"/windmill-labs"}
        >
          <img
            src={~p"/images/wordmarks/windmill.svg"}
            alt="Windmill"
            class="size-4 sm:size-10 lg:size-14 mr-2 saturate-0"
            loading="lazy"
          /> Windmill
        </.link>

        <.link class="relative flex items-center justify-center" navigate={~p"/panoratech"}>
          <img
            src={~p"/images/wordmarks/panora.png"}
            alt="Panora"
            class="col-auto w-[60%] lg:w-[50%] saturate-0 brightness-0 invert"
            loading="lazy"
          />
        </.link>

        <.link class="relative flex items-center justify-center" navigate={~p"/highlight"}>
          <img
            src={~p"/images/wordmarks/highlight.png"}
            alt="Highlight"
            class="col-auto lg:w-[90%] saturate-0"
            loading="lazy"
          />
        </.link>
      </div>
    </div>
    """
  end

  def event_card(assigns) do
    ~H"""
    <.link
      navigate={@event.link}
      class="group relative flex items-center gap-4 bg-card p-4 md:p-6 rounded-xl border-l-8 transition-all mb-6 z-10 hover:scale-[1.03] border-[color:var(--event-theme-color)] shadow-[0px_0px_3px_var(--event-theme-color-10),_0px_0px_6px_var(--event-theme-color-15),_0px_0px_8px_var(--event-theme-color-20)]"
      style={"--event-theme-color: #{@event.theme_color}; --event-theme-color-05: #ffffff0D; --event-theme-color-08: #ffffff14; --event-theme-color-10: #ffffff1A; --event-theme-color-15: #ffffff26; --event-theme-color-20: #ffffff33;"}
    >
      <div class="size-12 md:size-16 rounded-xl bg-background flex-shrink-0 overflow-hidden">
        <img src={@event.logo} alt={@event.alt} class="w-full h-full object-contain" />
      </div>
      <div class="flex-1">
        <div class="flex items-center gap-2">
          <p class="text-sm md:text-lg font-semibold text-foreground">
            {@event.title}
          </p>
        </div>
        <p class="text-xs md:text-sm text-muted-foreground flex items-center gap-2 mt-1">
          {@event.date}
        </p>
      </div>
      <.icon
        name="tabler-chevron-right"
        class="size-4 md:size-6 text-muted-foreground group-hover:text-[color:var(--event-theme-color)] transition-colors"
      />
    </.link>
    """
  end

  defp events do
    [
      %{
        title: "Turso launches open source challenge!",
        date: "Jun 3, 2025",
        logo: "https://avatars.githubusercontent.com/u/139391156?s=200&v=4",
        alt: "Turso",
        theme_color: "#50f5d2",
        link: "/challenges/turso"
      },
      %{
        title: ".txt is hiring with Algora!",
        date: "Jun 2, 2025",
        logo: "https://avatars.githubusercontent.com/u/142257755?s=200&v=4",
        alt: "DotTxt",
        theme_color: "#ffffff",
        link: "/candidates/dottxt-ai"
      },
      %{
        title: "Prequel launches bounty program!",
        date: "May 31, 2025",
        logo: "https://avatars.githubusercontent.com/u/129894407?v=4",
        alt: "Prequel",
        theme_color: "#ffffff",
        link: "/prequel-dev/home"
      },
      %{
        title: "Notes hired with Algora!",
        date: "May 28, 2025",
        logo: "https://notes.fm/images/favicon.png",
        alt: "Notes",
        theme_color: "#0029ff",
        link: "/notes/home"
      },
      %{
        title: "Outspeed is hiring with Algora!",
        date: "May 26, 2025",
        logo: "https://avatars.githubusercontent.com/u/181807673?s=200&v=4",
        alt: "Outspeed",
        theme_color: "#00ffff",
        link: "/candidates/outspeed"
      },
      %{
        title: "Unsiloed launches bounty program!",
        date: "May 11, 2025",
        logo: "https://avatars.githubusercontent.com/u/194294730?s=200&v=4",
        alt: "Unsiloed",
        theme_color: "#ffffff",
        link: "/unsiloed-ai/home"
      },
      %{
        title: "Notes hired with Algora!",
        date: "May 1, 2025",
        logo: "https://notes.fm/images/favicon.png",
        alt: "Notes",
        theme_color: "#0029ff",
        link: "/notes/home"
      }
    ]
  end
end
