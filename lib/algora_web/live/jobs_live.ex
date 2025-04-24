defmodule AlgoraWeb.JobsLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Jobs
  alias Algora.Jobs.JobPosting

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    jobs = Jobs.list_jobs()
    changeset = JobPosting.changeset(%JobPosting{}, %{})

    {:ok,
     socket
     |> assign(:page_title, "Jobs")
     |> assign(:jobs, jobs)
     |> assign(:form, to_form(changeset))
     |> assign_user_applications()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-6 p-4 md:p-6 lg:px-8">
      <.section title="Jobs" subtitle="Open positions at top companies">
        <%= if Enum.empty?(@jobs) do %>
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
          <div class="grid gap-4">
            <%= for job <- @jobs do %>
              <.card class="flex flex-col gap-4 p-6">
                <div class="flex items-start justify-between gap-4">
                  <div class="flex gap-4">
                    <.avatar class="h-12 w-12">
                      <.avatar_image src={job.user.avatar_url} />
                      <.avatar_fallback>
                        {Algora.Util.initials(job.user.name)}
                      </.avatar_fallback>
                    </.avatar>
                    <div>
                      <.link
                        href={job.url}
                        class="text-lg font-semibold hover:underline"
                        target="_blank"
                      >
                        {job.title}
                      </.link>
                      <div class="text-sm text-muted-foreground">
                        {job.company_name} •
                        <.link href={job.company_url} rel="noopener" target="_blank">
                          {job.company_url |> String.replace("https://", "")}
                        </.link>
                      </div>
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
                <div class="text-sm text-muted-foreground">
                  {job.description}
                </div>
                <div class="flex flex-wrap gap-2">
                  <%= for tech <- job.tech_stack do %>
                    <.badge variant="outline">{tech}</.badge>
                  <% end %>
                </div>
              </.card>
            <% end %>
          </div>
        <% end %>
      </.section>

      <.section>
        <div class="border ring-1 ring-transparent rounded-xl overflow-hidden">
          <div class="bg-card/75 flex flex-col h-full p-4 rounded-xl border-t-4 sm:border-t-0 sm:border-l-4 border-emerald-400">
            <div class="p-4 sm:p-6">
              <div class="text-2xl font-semibold text-foreground">
                Post your job<br class="block sm:hidden" />
                <span class="text-success drop-shadow-[0_1px_5px_#34d39980]">
                  in seconds
                </span>
              </div>
              <div class="pt-1 text-base font-medium text-muted-foreground">
                Reach thousands of developers looking for their next opportunity versed in your tech stack
              </div>
              <.simple_form for={@form} phx-submit="create_job" class="mt-4 space-y-6">
                <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <.input
                    field={@form[:email]}
                    label="Email"
                    data-domain-target
                    phx-hook="DeriveDomain"
                  />
                  <.input field={@form[:company_name]} label="Company Name" />
                  <.input field={@form[:company_url]} label="Company Website" data-domain-source />
                  <.input field={@form[:url]} label="Job Posting URL" />
                </div>

                <div class="flex justify-end">
                  <.button class="flex items-center gap-2" phx-disable-with="Processing...">
                    Post Job
                  </.button>
                </div>
              </.simple_form>
            </div>
          </div>
        </div>
      </.section>
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

  @impl true
  def handle_event("create_job", %{"job_posting" => params}, socket) do
    case Jobs.create_job_posting(params) do
      {:ok, job} ->
        case Jobs.create_payment_session(job) do
          {:ok, url} ->
            {:noreply, redirect(socket, external: url)}

          {:error, reason} ->
            Logger.error("Failed to create payment session: #{inspect(reason)}")
            {:noreply, put_flash(socket, :error, "Something went wrong. Please try again.")}
        end

      {:error, changeset} ->
        Logger.error("Failed to create job posting: #{inspect(changeset)}")
        {:noreply, assign(socket, :form, to_form(changeset))}
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
        {:noreply, redirect(socket, external: Algora.Github.authorize_url())}
      end
    else
      {:noreply, redirect(socket, external: Algora.Github.authorize_url())}
    end
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
end
