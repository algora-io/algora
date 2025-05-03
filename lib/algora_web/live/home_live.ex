defmodule AlgoraWeb.HomeLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

  import AlgoraWeb.Components.ModalVideo
  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Jobs
  alias Algora.Jobs.JobPosting
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias AlgoraWeb.Components.Footer
  alias AlgoraWeb.Components.Header
  alias AlgoraWeb.Data.PlatformStats
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
         |> assign(:featured_devs, featured_devs)
         |> assign(:stats, stats)
         |> assign(:form, to_form(JobPosting.changeset(%JobPosting{}, %{})))
         |> assign(:jobs_by_user, jobs_by_user)
         |> assign(:user_metadata, AsyncResult.loading())
         |> assign_user_applications()}
    end
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
        <section class="relative isolate lg:min-h-[100svh] bg-gradient-to-b from-background to-black">
          <.pattern />
          <div class="mx-auto max-w-7xl pt-24 pb-12 xl:pt-24">
            <div class="mx-auto lg:mx-0 flex lg:max-w-none items-center justify-center min-h-[21rem] lg:min-h-[calc(100svh-10rem)] text-center">
              <div class={
                classes([
                  # "px-6 lg:px-8 lg:pr-0 xl:py-20 relative w-full lg:max-w-xl lg:shrink-0 xl:max-w-[52rem]",
                  "flex flex-col items-center justify-center",
                  @screenshot? && "pt-24"
                ])
              }>
                <.wordmark :if={@screenshot?} class="h-8 mb-6" />
                <h1 class="font-display text-4xl sm:text-4xl md:text-5xl xl:text-7xl font-semibold tracking-tight text-foreground">
                  <span class="text-emerald-400">Hire the top 1%</span>
                  <br />open source engineers
                </h1>
                <p class="mt-4 sm:mt-8 text-base sm:text-lg xl:text-2xl/8 font-medium text-muted-foreground sm:max-w-md lg:max-w-none">
                  Algora connects companies and engineers<br class="lg:hidden" />
                  for full-time and contract work
                </p>
                <div :if={!@screenshot?} class="mt-6 sm:mt-10 flex gap-4">
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
                <%!-- <div class="flex flex-col gap-4 pt-6 sm:pt-10">
                  <.events transactions={@transactions} />
                </div> --%>
              </div>
              <!-- Featured devs -->
              <%!-- <div class={
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
              </div> --%>
            </div>
          </div>
        </section>

        <div class="container mx-auto max-w-7xl space-y-6 p-4 md:p-6 lg:px-8">
          <%= if not Enum.empty?(@jobs_by_user) do %>
            <.section>
              <div class="grid grid-cols-1 gap-12">
                <%= for {user, jobs} <- @jobs_by_user do %>
                  <.card class="flex flex-col p-6">
                    <div class="flex items-start md:items-center gap-4">
                      <.avatar class="h-16 w-16">
                        <.avatar_image src={user.avatar_url} />
                        <.avatar_fallback>
                          {Algora.Util.initials(user.name)}
                        </.avatar_fallback>
                      </.avatar>
                      <div>
                        <div class="text-lg text-foreground font-bold font-display">
                          {user.name}
                        </div>
                        <div class="text-sm text-muted-foreground line-clamp-2 md:line-clamp-1">
                          {user.bio}
                        </div>
                        <div class="flex gap-2 items-center">
                          <%= for {platform, icon} <- social_icons(),
                      url = social_link(user, platform),
                      not is_nil(url) do %>
                            <.link
                              href={url}
                              target="_blank"
                              class="text-muted-foreground hover:text-foreground"
                            >
                              <.icon name={icon} class="size-4" />
                            </.link>
                          <% end %>
                        </div>
                      </div>
                    </div>

                    <div class="pt-8 grid gap-8">
                      <%= for job <- jobs do %>
                        <div class="flex flex-col md:flex-row justify-between gap-4">
                          <div>
                            <div>
                              <div class="text-lg lg:text-2xl text-success font-semibold">
                                {job.title}
                              </div>
                            </div>
                            <div :if={job.description} class="pt-1 text-sm text-muted-foreground">
                              {job.description}
                            </div>
                            <div class="pt-2 flex flex-wrap gap-2">
                              <%= for tech <- job.tech_stack do %>
                                <.badge variant="outline">
                                  <span class="flex items-center text-foreground text-[11px] gap-1">
                                    <img
                                      src={"https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/#{String.downcase(tech)}/#{String.downcase(tech)}-original.svg"}
                                      class="w-4 h-4 invert saturate-0"
                                    /> {tech}
                                  </span>
                                </.badge>
                              <% end %>
                            </div>
                          </div>
                          <%= if MapSet.member?(@user_applications, job.id) do %>
                            <.button disabled class="opacity-50">
                              <.icon name="tabler-check" class="h-4 w-4 mr-2 -ml-1" /> Applied
                            </.button>
                          <% else %>
                            <.button phx-click="apply_job" phx-value-job-id={job.id}>
                              <.icon name="github" class="h-4 w-4 mr-2" /> Apply with GitHub
                            </.button>
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  </.card>
                <% end %>
              </div>
            </.section>
          <% end %>

          <.section class="pt-24">
            <h2 class="font-display text-4xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-2 sm:mb-4">
              <span class="text-success-300 drop-shadow-[0_1px_5px_#34d39980]">
                Screen on autopilot
              </span>
              <br />for OSS contribution<span class="md:hidden">s</span>
              <span class="hidden md:inline">
                history
              </span>
            </h2>
            <p class="text-center font-medium text-base text-muted-foreground sm:text-xl mb-12 mx-auto">
              Receive applications on Algora <br class="md:hidden" />
              or import your existing applicants.<br />Algora will highlight applicants with relevant OSS contribution history in your tech stack.
            </p>
            <video
              src={~p"/videos/import-applicants.mp4"}
              autoplay
              loop
              muted
              playsinline
              class="mt-8 w-full h-full object-cover mx-auto border border-border rounded-xl"
              speed={2}
              playbackspeed={2}
            />
          </.section>

          <.section class="pt-24">
            <h2 class="font-display text-4xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-2 sm:mb-4">
              Publish jobs and <br />
              <span class="text-success-300 drop-shadow-[0_1px_5px_#34d39980]">
                invite top matches
              </span>
            </h2>
            <p class="text-center font-medium text-base text-muted-foreground sm:text-xl mb-12 mx-auto">
              Access your top matches from Algora based on your tech stack and preferences
            </p>

            <img
              alt="Algora dashboard"
              width="1485"
              height="995"
              loading="lazy"
              class="my-auto border border-border rounded-lg [box-shadow:0px_80px_60px_0px_rgba(0,0,0,0.35),0px_35px_28px_0px_rgba(0,0,0,0.25),0px_18px_15px_0px_rgba(0,0,0,0.20),0px_10px_8px_0px_rgba(0,0,0,0.17),0px_5px_4px_0px_rgba(0,0,0,0.14),0px_2px_2px_0px_rgba(0,0,0,0.10)]"
              src={~p"/images/screenshots/job-matches-typescript.png"}
            />
          </.section>

          <.section class="pt-24">
            <section class="relative isolate">
              <div class="mx-auto max-w-7xl px-6 lg:px-8">
                <h2 class="font-display text-4xl font-semibold tracking-tight text-foreground sm:text-7xl text-center mb-2 sm:mb-4">
                  Interview with <br />
                  <span class="text-success-300 drop-shadow-[0_1px_5px_#34d39980]">
                    paid projects
                  </span>
                </h2>
                <p class="text-center font-medium text-base text-muted-foreground sm:text-xl mb-12 mx-auto">
                  Use bounties and contract work to trial your top candidates before hiring them full-time.
                </p>

                <div class="mx-auto max-w-6xl gap-8 text-sm leading-6">
                  <div class="flex gap-4 sm:gap-8">
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
                        class="relative flex aspect-[1121/1343] w-full items-center justify-center overflow-hidden rounded-xl lg:rounded-2xl lg:rounded-l-none"
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
                </div>

                <div class="mx-auto mt-16 max-w-6xl gap-8 text-sm leading-6">
                  <img
                    class="aspect-[1200/500] object-cover object-top w-full rounded-xl lg:rounded-2xl"
                    src={~p"/images/people/golem-team.jpeg"}
                    alt="Golem Team"
                    loading="lazy"
                  />
                  <div class="pt-8 grid grid-cols-1 items-center gap-x-16 gap-y-8 lg:grid-cols-12">
                    <div class="lg:col-span-6 order-last lg:order-first">
                      <h3 class="text-xl font-medium">
                        I always wanted to work on some Rust project and get to use the language, but I never found a good opportunity to do so. Now with huge bounty attached to this issue, it was a very good opportunity to play around with Rust.
                      </h3>
                      <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-4 sm:pt-6">
                        <div class="flex items-center gap-4">
                          <img src="https://github.com/mschuwalow.png" class="h-12 w-12 rounded-full" loading="lazy" />
                          <div>
                            <div class="text-xl sm:text-2xl font-semibold text-foreground">
                              Maxim Schuwalow
                            </div>
                            <div class="text-sm sm:text-lg font-medium text-muted-foreground">
                              Software Engineer at Golem Cloud
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                    <div class="lg:col-span-6 order-last lg:order-first">
                      <h3 class="text-xl font-medium">
                        After a few decades of actively hiring engineers, what I found out is, a lot of times people who are very active in open source software, those engineers make fantastic additions to your team.
                      </h3>
                      <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-4 sm:pt-6">
                        <div class="flex items-center gap-4">
                          <img
                            src={~p"/images/people/john-de-goes.jpg"}
                            class="h-12 w-12 rounded-full"
                            loading="lazy"
                          />

                          <div>
                            <div class="text-xl sm:text-2xl font-semibold text-foreground">
                              John A De Goes
                            </div>
                            <div class="text-sm sm:text-lg font-medium text-muted-foreground">
                              Founder &amp; CEO at Golem Cloud
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

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
                      <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-4 sm:pt-12">
                        <div class="flex items-center gap-4">
                          <div>
                            <div class="text-xl sm:text-2xl xl:text-3xl font-semibold text-foreground">
                              Eric Allam
                            </div>
                            <div class="sm:pt-2 text-sm sm:text-lg xl:text-2xl font-medium text-muted-foreground">
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
                        <span class="text-success">4 full-time hires</span>
                        using Algora
                      </h3>
                      <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-4 sm:pt-12">
                        <div class="flex items-center gap-4">
                          <div>
                            <div class="text-xl sm:text-2xl xl:text-3xl font-semibold text-foreground">
                              Tushar Mathur
                            </div>
                            <div class="sm:pt-2 text-sm sm:text-lg xl:text-2xl font-medium text-muted-foreground">
                              Founder & CEO at Tailcall
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </section>
          </.section>

          <.section class="pt-24">
            <h2 class="font-display text-4xl font-semibold tracking-tight text-foreground sm:text-6xl text-center mb-2 sm:mb-4">
              <span class="text-success-300 drop-shadow-[0_1px_5px_#34d39980]">
                Hire the best
              </span>
              <br />using open source
            </h2>
            <p class="text-center font-medium text-base text-muted-foreground sm:text-xl mb-12 mx-auto">
              Source, screen, interview and onboard <span class="hidden lg:inline">with Algora</span>.<br />
              Guarantee role fit and job performance.
            </p>
            <ul class="space-y-3 mt-4 text-xl grid grid-cols-1 md:grid-cols-2 gap-4">
              <li class="flex items-center gap-4">
                <div class="shrink-0 flex items-center justify-center rounded-full bg-success-300/10 size-12 border border-success-300/20">
                  <.icon name="tabler-speakerphone" class="size-8 text-success-300" />
                </div>
                <span>
                  <span class="font-semibold text-success-300">Reach 50K+ devs</span>
                  <br class="md:hidden" /> with unlimited job postings
                </span>
              </li>
              <li class="flex items-center gap-4">
                <div class="shrink-0 flex items-center justify-center rounded-full bg-success-300/10 size-12 border border-success-300/20">
                  <.icon name="tabler-lock-open" class="size-8 text-success-300" />
                </div>
                <span>
                  <span class="font-semibold text-success-300">Access top 1% users</span>
                  <br class="md:hidden" /> matching your preferences
                </span>
              </li>
              <li class="flex items-center gap-4">
                <div class="shrink-0 flex items-center justify-center rounded-full bg-success-300/10 size-12 border border-success-300/20">
                  <.icon name="tabler-wand" class="size-8 text-success-300" />
                </div>
                <span>
                  <span class="font-semibold text-success-300">Auto-rank applicants</span>
                  <br class="md:hidden" /> for OSS contribution history
                </span>
              </li>
              <li class="flex items-center gap-4">
                <div class="shrink-0 flex items-center justify-center rounded-full bg-success-300/10 size-12 border border-success-300/20">
                  <.icon name="tabler-currency-dollar" class="size-8 text-success-300" />
                </div>
                <span>
                  <span class="font-semibold text-success-300">Trial top candidates</span>
                  <br class="md:hidden" /> using contracts and bounties
                </span>
              </li>
            </ul>
          </.section>

          <.section class="pt-12 pb-20">
            <div class="max-w-2xl mx-auto border ring-1 ring-transparent rounded-xl overflow-hidden">
              <div class="bg-card/75 flex flex-col h-full p-4 rounded-xl border-t-4 sm:border-t-0 sm:border-l-4 border-emerald-400">
                <div class="flex flex-col md:flex-row gap-8 p-4 sm:p-6">
                  <div class="flex-1 flex flex-col justify-center items-center">
                    <.simple_form
                      for={@form}
                      phx-change="validate_job"
                      phx-submit="create_job"
                      class="w-full space-y-6"
                    >
                      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <.input
                          id="final_section_email"
                          field={@form[:email]}
                          label="Email"
                          data-domain-target
                          phx-hook="DeriveDomain"
                          phx-change="email_changed"
                          phx-debounce="300"
                        />
                        <.input id="final_section_url" field={@form[:url]} label="Job Posting URL" />
                        <.input
                          id="final_section_company_url"
                          field={@form[:company_url]}
                          label="Company URL"
                          data-domain-source
                        />
                        <.input
                          id="final_section_company_name"
                          field={@form[:company_name]}
                          label="Company Name"
                        />
                      </div>

                      <div class="flex flex-col items-center gap-4">
                        <.button size="xl" class="w-full">
                          <div class="flex flex-col items-center gap-1 font-semibold">
                            <span>Hire now</span>
                          </div>
                        </.button>
                        <div>
                          <div
                            :if={
                              @user_metadata.ok? &&
                                get_in(@user_metadata.result, [:org, :favicon_url])
                            }
                            class="flex items-center gap-3"
                          >
                            <%= if logo = get_in(@user_metadata.result, [:org, :favicon_url]) do %>
                              <img src={logo} class="h-16 w-16 rounded-2xl" />
                            <% end %>
                            <div>
                              <div class="text-lg text-foreground font-bold font-display line-clamp-1">
                                {get_change(@form.source, :company_name)}
                              </div>
                              <%= if description = get_in(@user_metadata.result, [:org, :og_description]) do %>
                                <div class="text-sm text-muted-foreground line-clamp-1">
                                  {description}
                                </div>
                              <% end %>
                            </div>
                          </div>
                        </div>
                      </div>
                    </.simple_form>
                  </div>
                </div>
              </div>
            </div>
          </.section>
        </div>

        <div class="relative isolate overflow-hidden bg-gradient-to-br from-black to-background">
          <Footer.footer />
        </div>
      </main>
    </div>

    <.modal_video_dialog />
    """
  end

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
      Algora.Admin.alert("Job posting initialized: #{job.company_name}", :critical)
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
        {:noreply,
         socket
         |> push_event("store-session", %{user_return_to: "/jobs"})
         |> redirect(external: Algora.Github.authorize_url())}
      end
    else
      {:noreply,
       socket
       |> push_event("store-session", %{user_return_to: "/jobs"})
       |> redirect(external: Algora.Github.authorize_url())}
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

  defp social_icons do
    %{
      website: "tabler-world",
      github: "github",
      twitter: "tabler-brand-x",
      youtube: "tabler-brand-youtube",
      twitch: "tabler-brand-twitch",
      discord: "tabler-brand-discord",
      slack: "tabler-brand-slack",
      linkedin: "tabler-brand-linkedin"
    }
  end

  defp social_link(user, :github), do: if(login = user.provider_login, do: "https://github.com/#{login}")
  defp social_link(user, platform), do: Map.get(user, :"#{platform}_url")

  defp assign_user_applications(socket) do
    user_applications =
      if socket.assigns[:current_user] do
        Jobs.list_user_applications(socket.assigns.current_user)
      else
        MapSet.new()
      end

    assign(socket, :user_applications, user_applications)
  end
end
