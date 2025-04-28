defmodule AlgoraWeb.JobsLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.ModalVideo
  import Ecto.Changeset

  alias Algora.Accounts
  alias Algora.Jobs
  alias Algora.Jobs.JobPosting
  alias Phoenix.LiveView.AsyncResult

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    # Group jobs by user
    jobs_by_user = Enum.group_by(Jobs.list_jobs(), & &1.user)
    changeset = JobPosting.changeset(%JobPosting{}, %{})

    {:ok,
     socket
     |> assign(:page_title, "Jobs")
     |> assign(:jobs_by_user, jobs_by_user)
     |> assign(:form, to_form(changeset))
     |> assign(:user_metadata, AsyncResult.loading())
     |> assign_user_applications()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative">
      <div class={
        if(!@current_user,
          do: "-z-10 fixed inset-0 bg-gradient-to-br from-black to-background",
          else: ""
        )
      } />
      <div class={
        classes([
          "mx-auto max-w-7xl px-4 md:px-6 lg:px-8",
          if(!@current_user, do: "py-16 sm:py-24", else: "py-4 md:py-6 lg:py-8")
        ])
      }>
        <div class={
          classes([
            if(!@current_user, do: "text-center", else: "")
          ])
        }>
          <h2 class="font-display text-3xl font-semibold tracking-tight text-foreground sm:text-6xl mb-2">
            Jobs
          </h2>
          <p class="font-medium text-base text-muted-foreground">
            Open positions at top open source companies
          </p>
        </div>

        <.section class="pt-8">
          <%= if Enum.empty?(@jobs_by_user) do %>
            <.card class="rounded-lg bg-card py-12 text-center lg:rounded-[2rem]">
              <.card_header>
                <div class="mx-auto mb-2 rounded-full bg-muted p-4">
                  <.icon name="tabler-briefcase" class="h-8 w-8 text-muted-foreground" />
                </div>
                <.card_title>No jobs yet</.card_title>
                <.card_description>
                  Open positions will appear here once created
                </.card_description>
              </.card_header>
            </.card>
          <% else %>
            <div class="grid gap-12">
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
                            <div class="text-lg font-semibold">
                              {job.title}
                            </div>
                          </div>
                          <div :if={job.description} class="pt-1 text-sm text-muted-foreground">
                            {job.description}
                          </div>
                          <div class="pt-2 flex flex-wrap gap-2">
                            <%= for tech <- job.tech_stack do %>
                              <.badge variant="outline">{tech}</.badge>
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
          <% end %>
        </.section>

        <.section class="pt-12">
          <div class="border ring-1 ring-transparent rounded-xl overflow-hidden">
            <div class="bg-card/75 flex flex-col h-full p-4 rounded-xl border-t-4 sm:border-t-0 sm:border-l-4 border-emerald-400">
              <div class="flex flex-col md:flex-row gap-8 p-4 sm:p-6">
                <div class="flex-1">
                  <h3 class="text-3xl font-semibold text-foreground">
                    <span class="text-success-300 drop-shadow-[0_1px_5px_#34d39980]">
                      Hire top talent
                    </span>
                    on auto-pilot
                  </h3>
                  <ul class="space-y-3 mt-4 text-base">
                    <li class="flex items-start md:items-center gap-2">
                      <div class="flex items-center justify-center rounded-full bg-success-300/10 size-8 border border-success-300/20">
                        <.icon name="tabler-speakerphone" class="h-5 w-5 text-success-300" />
                      </div>
                      <span>
                        <span class="font-semibold text-success-300">Reach 50K+ devs</span>
                        with unlimited job postings
                      </span>
                    </li>
                    <li class="flex items-start md:items-center gap-2">
                      <div class="flex items-center justify-center rounded-full bg-success-300/10 size-8 border border-success-300/20">
                        <.icon name="tabler-lock-open" class="h-5 w-5 text-success-300" />
                      </div>
                      <span>
                        <span class="font-semibold text-success-300">Access top 1% users</span>
                        matching your preferences
                      </span>
                    </li>
                    <li class="flex items-start md:items-center gap-2">
                      <div class="flex items-center justify-center rounded-full bg-success-300/10 size-8 border border-success-300/20">
                        <.icon name="tabler-wand" class="h-5 w-5 text-success-300" />
                      </div>
                      <span>
                        <span class="font-semibold text-success-300">Auto-rank applicants</span>
                        for OSS contribution history
                      </span>
                    </li>
                    <li class="flex items-start md:items-center gap-2">
                      <div class="flex items-center justify-center rounded-full bg-success-300/10 size-8 border border-success-300/20">
                        <.icon name="tabler-currency-dollar" class="h-5 w-5 text-success-300" />
                      </div>
                      <span>
                        <span class="font-semibold text-success-300">Trial top candidates</span>
                        using contracts and bounties
                      </span>
                    </li>
                  </ul>
                  <%!-- <div class="[transform:perspective(4101px)_rotateX(51deg)_rotateY(-13deg)_rotateZ(40deg)]"> --%>
                  <div class="my-auto pt-8">
                    <img
                      alt="Algora dashboard"
                      width="1200"
                      height="630"
                      loading="lazy"
                      class="my-auto border border-border rounded-lg [box-shadow:0px_80px_60px_0px_rgba(0,0,0,0.35),0px_35px_28px_0px_rgba(0,0,0,0.25),0px_18px_15px_0px_rgba(0,0,0,0.20),0px_10px_8px_0px_rgba(0,0,0,0.17),0px_5px_4px_0px_rgba(0,0,0,0.14),0px_2px_2px_0px_rgba(0,0,0,0.10)]"
                      src={~p"/images/screenshots/job.png"}
                    />
                  </div>
                  <%!-- </div> --%>
                </div>
                <div class="flex-1 flex flex-col justify-center items-center">
                  <.simple_form
                    for={@form}
                    phx-change="validate_job"
                    phx-submit="create_job"
                    class="w-full space-y-6"
                  >
                    <div class="grid grid-cols-1 gap-4">
                      <.input
                        field={@form[:email]}
                        label="Email"
                        data-domain-target
                        phx-hook="DeriveDomain"
                        phx-change="email_changed"
                        phx-debounce="300"
                      />
                      <.input field={@form[:url]} label="Job Posting URL" />
                      <.input field={@form[:company_url]} label="Company URL" data-domain-source />
                      <.input field={@form[:company_name]} label="Company Name" />
                    </div>

                    <div class="flex flex-col items-center gap-4">
                      <.button
                        class="group bg-emerald-900/10 text-emerald-300 transition-colors duration-75 hover:bg-emerald-800/10 hover:text-emerald-300 hover:drop-shadow-[0_1px_5px_#34d39980] focus:bg-emerald-800/10 focus:text-emerald-300 focus:outline-none focus:drop-shadow-[0_1px_5px_#34d39980] border border-emerald-400/40 hover:border-emerald-400/50 focus:border-emerald-400/50 h-[8rem] w-full"
                        size="xl"
                        href={AlgoraWeb.Constants.get(:calendar_url)}
                      >
                        <div class="flex flex-col items-center gap-1 font-semibold">
                          <span>Activate subscription</span>
                        </div>
                      </.button>
                      <div>
                        <div
                          :if={
                            @user_metadata.ok? && get_in(@user_metadata.result, [:org, :favicon_url])
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

        <.section>
          <%!-- <h2 class="font-display text-4xl font-semibold tracking-tight text-foreground sm:text-7xl text-center mb-2 sm:mb-4">
            Auto-rank applicants for OSS contribution history
          </h2>
          <p class="text-center font-medium text-base text-muted-foreground sm:text-xl mb-12 mx-auto">
            Import and we'll do the rest
          </p> --%>
          <video
            src={~p"/videos/import-applicants.mp4"}
            autoplay
            loop
            muted
            playsinline
            class="mt-8 w-full h-full object-cover max-w-4xl mx-auto border border-border rounded-xl"
            speed={2}
            playbackspeed={2}
          />
        </.section>

        <.cta_section />
      </div>
    </div>
    """
  end

  @impl true
  def handle_params(%{"status" => "paid"}, _uri, socket) do
    {:noreply, put_flash(socket, :info, "Payment received, your job will go live shortly!")}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
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
         {:ok, job} <- params |> Map.put("user_id", user.id) |> Jobs.create_job_posting(),
         {:ok, url} <- Jobs.create_payment_session(job) do
      Algora.Admin.alert("Job posting initialized: #{job.company_name}", :info)
      {:noreply, redirect(socket, external: url)}
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

  defp assign_user_applications(socket) do
    user_applications =
      if socket.assigns[:current_user] do
        Jobs.list_user_applications(socket.assigns.current_user)
      else
        MapSet.new()
      end

    assign(socket, :user_applications, user_applications)
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

  defp cta_section(assigns) do
    ~H"""
    <section class="relative isolate py-16 sm:py-40">
      <div class="mx-auto max-w-7xl px-6 lg:px-8">
        <h2 class="font-display text-4xl font-semibold tracking-tight text-foreground sm:text-7xl text-center mb-2 sm:mb-4">
          Hire by building product
        </h2>
        <p class="text-center font-medium text-base text-muted-foreground sm:text-xl mb-12 mx-auto">
          Use bounties to evaluate developers based on actual contributions to your codebase.
        </p>
        <div class="mx-auto mt-16 max-w-6xl gap-8 text-sm leading-6">
          <div class="grid grid-cols-1 items-center gap-x-16 gap-y-8 lg:grid-cols-12">
            <div class="lg:col-span-6 order-first lg:order-last">
              <.modal_video
                class="aspect-[1200/630] rounded-xl lg:rounded-2xl lg:rounded-r-none"
                src="https://www.youtube.com/embed/xObOGcUdtY0"
                start={122}
                title="$15,000 Open source bounty to hire a Rust engineer"
                poster={~p"/images/people/john-de-goes-2.jpg"}
                alt="John A De Goes"
              />
              <.modal_video_dialog />
            </div>
            <div class="lg:col-span-6 order-last lg:order-first">
              <h3 class="text-xl sm:text-2xl font-display font-bold leading-[1.2] sm:leading-[2rem] xl:leading-[3rem]">
                After a few decades of actively hiring engineers, what I found out is, a lot of times people who are very active in open source software, those engineers make fantastic additions to your team
              </h3>
              <div class="flex flex-wrap items-center gap-x-8 gap-y-4 pt-4 sm:pt-6">
                <div class="flex items-center gap-4">
                  <div>
                    <div class="text-xl sm:text-2xl font-semibold text-foreground">
                      John A De Goes
                    </div>
                    <div class="sm:pt-2 text-sm sm:text-lg font-medium text-muted-foreground">
                      Founder &amp; CEO at Golem Cloud
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="mx-auto mt-16 max-w-4xl gap-8 text-sm leading-6">
          <div class="flex gap-4 sm:gap-8">
            <div>
              <a
                href="https://github.com/golemcloud/golem/issues/1004"
                target="_blank"
                rel="noopener"
                class="relative flex aspect-[1369/641] w-full items-center justify-center overflow-hidden rounded-xl lg:rounded-2xl lg:rounded-l-none"
                data-phx-id="m50-phx-GDqOYd-JM6dzJeWB"
              >
                <img
                  src="/images/screenshots/bounty-to-hire-merged.png"
                  alt="Golem bounty to hire"
                  class="object-cover"
                  loading="lazy"
                />
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end
end
