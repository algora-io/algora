defmodule AlgoraWeb.Org.JobsLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.ModalVideo

  alias Algora.Accounts
  alias Algora.Jobs
  alias Algora.Markdown

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    jobs = Jobs.list_jobs(user_id: socket.assigns.current_org.id)
    media = Accounts.list_user_media(socket.assigns.current_org)

    {:ok,
     socket
     |> assign(:page_title, "Jobs")
     |> assign(:jobs, jobs)
     |> assign(:media, media)
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
          if(!@current_user, do: "py-8", else: "py-4 md:py-6 lg:py-8")
        ])
      }>
        <div class={
          classes([
            if(!@current_user, do: "text-center", else: "text-center")
          ])
        }>
          <div class="flex items-start md:items-center justify-center gap-4">
            <.avatar class="h-16 w-16">
              <.avatar_image src={@current_org.avatar_url} />
              <.avatar_fallback>
                {Algora.Util.initials(@current_org.name)}
              </.avatar_fallback>
            </.avatar>
            <%!-- <div>
              <div class="text-lg text-foreground font-bold font-display">
                {@current_org.name}
              </div>
              <div class="text-sm text-muted-foreground line-clamp-2 md:line-clamp-1">
                {@current_org.bio}
              </div>
              <div class="flex gap-2 items-center">
                <%= for {platform, icon} <- social_icons(),
                      url = social_link(@current_org, platform),
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
            </div> --%>
          </div>

          <h2 class="pt-4 font-display text-3xl font-semibold tracking-tight text-foreground sm:text-6xl mb-2">
            Engineering at {@current_org.name}
          </h2>
          <p class="pt-1 font-medium text-base text-muted-foreground">
            Open software engineering positions at {@current_org.name}
          </p>
          <div class="pt-2 flex gap-2 items-center justify-center">
            <%= for {platform, icon} <- social_icons(),
                      url = social_link(@current_org, platform),
                      not is_nil(url) do %>
              <.link href={url} target="_blank" class="text-muted-foreground hover:text-foreground">
                <.icon name={icon} class="size-5" />
              </.link>
            <% end %>
          </div>
        </div>

        <%= if not Enum.empty?(@media) do %>
          <div class="max-w-xl mx-auto mt-8 flex flex-row justify-center gap-4">
            <%= for media <- @media |> Enum.take(3) do %>
              <div class="w-1/3 aspect-video w-full rounded-lg overflow-hidden">
                <%= if Algora.Accounts.youtube_url?(media.url) do %>
                  <.modal_video
                    src={media.url}
                    poster={"https://img.youtube.com/vi/#{media.url |> String.split("/") |> List.last()}/maxresdefault.jpg"}
                  />
                  <.modal_video_dialog />
                <% else %>
                  <img src={media.url} class="w-full h-full object-cover object-cover" />
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>

        <.section class="pt-8">
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
            <h2 class="text-sm font-semibold uppercase text-muted-foreground">Open positions</h2>
            <.card class="mt-4 flex flex-col p-6">
              <div class="grid gap-8">
                <%= for job <- @jobs do %>
                  <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div>
                      <div>
                        <%= if @current_user_role in [:admin, :mod] do %>
                          <.link
                            navigate={~p"/org/#{@current_org.handle}/jobs/#{job.id}"}
                            class="text-lg sm:text-2xl font-semibold underline"
                          >
                            {job.title}
                          </.link>
                        <% else %>
                          <div class="text-lg font-semibold">
                            {job.title}
                          </div>
                        <% end %>
                      </div>
                      <div
                        :if={job.description}
                        class="pt-1 text-sm text-muted-foreground prose prose-invert max-w-none"
                      >
                        <div
                          id={"job-description-#{job.id}"}
                          class="line-clamp-3 transition-all duration-200 [&>p]:m-0"
                          phx-hook="ExpandableText"
                          data-expand-id={"expand-#{job.id}"}
                          data-class="line-clamp-3"
                        >
                          {Phoenix.HTML.raw(Markdown.render(job.description))}
                        </div>
                        <button
                          id={"expand-#{job.id}"}
                          type="button"
                          class="text-xs text-foreground font-bold mt-2 hidden"
                          data-content-id={"job-description-#{job.id}"}
                          phx-hook="ExpandableTextButton"
                        >
                          ...see more
                        </button>
                      </div>
                      <div class="pt-2 flex flex-wrap gap-2">
                        <%= for tech <- job.tech_stack do %>
                          <.tech_badge tech={tech} />
                        <% end %>
                      </div>
                    </div>
                    <%= if MapSet.member?(@user_applications, job.id) do %>
                      <.button disabled class="opacity-50" size="lg">
                        <.icon name="tabler-check" class="h-6 w-6 mr-2 -ml-1" /> Applied
                      </.button>
                    <% else %>
                      <.button phx-click="apply_job" phx-value-job-id={job.id} size="lg">
                        <.icon name="github" class="h-6 w-6 mr-2" /> Apply with GitHub
                      </.button>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </.card>
          <% end %>
        </.section>
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
         redirect(socket,
           external: Algora.Github.authorize_url(%{return_to: "/org/#{socket.assigns.current_org.handle}/jobs"})
         )}
      end
    else
      {:noreply,
       redirect(socket,
         external: Algora.Github.authorize_url(%{return_to: "/org/#{socket.assigns.current_org.handle}/jobs"})
       )}
    end
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
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
end
