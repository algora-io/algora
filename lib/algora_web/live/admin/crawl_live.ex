defmodule AlgoraWeb.Admin.CrawlLive do
  @moduledoc false

  use AlgoraWeb, :live_view

  import Ecto.Changeset

  alias AlgoraCloud.OrgSeeder
  alias AlgoraWeb.LocalStore
  alias Phoenix.LiveView.AsyncResult

  require Logger

  defmodule Form do
    @moduledoc false
    use Ecto.Schema

    embedded_schema do
      field :urls, :string
    end

    def changeset(form, attrs \\ %{}) do
      form
      |> cast(attrs, [:urls])
      |> validate_required([:urls])
      |> validate_length(:urls, min: 1)
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Algora.PubSub, "crawl_logs")
    end

    {:ok,
     socket
     |> assign(:page_title, "Crawl Organizations")
     |> assign(:form, to_form(Form.changeset(%Form{}, %{urls: "https://infisical.com"})))
     |> assign(:crawl_results, AsyncResult.loading())
     |> assign(:jobs, [])
     |> assign(:images, [])
     |> assign(:logs, [])}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> LocalStore.init(key: __MODULE__, ttl: :infinity)
     |> LocalStore.subscribe()}
  end

  @impl true
  def handle_event("restore_settings", params, socket) do
    {:noreply, LocalStore.restore(socket, params)}
  end

  @impl true
  def handle_event("crawl", %{"form" => params}, socket) do
    pid = self()

    urls =
      params["urls"]
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    broadcast_log("🎯 Starting crawl of #{length(urls)} URLs")

    socket =
      socket
      |> assign(:jobs, [])
      |> assign(:images, [])
      |> start_async(:crawl_task, fn ->
        results =
          urls
          |> Task.async_stream(
            fn url ->
              broadcast_log("🔄 Processing URL: #{url}")

              {url,
               OrgSeeder.fetch_org_data(url, fn x ->
                 dbg(x)
                 send(pid, {:update_jobs, x})
                 :ok
               end)}
            end,
            max_concurrency: 5,
            timeout: :infinity
          )
          |> Enum.to_list()

        broadcast_log("✅ Completed processing #{length(results)} URLs")
        results
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_async(:crawl_task, {:ok, results}, socket) do
    Logger.info("✅ Crawl task completed successfully")

    images =
      Enum.reduce(results, [], fn
        {:ok, {_url, {_jobs, images}}}, images_acc ->
          images_acc ++ images

        {url, {:error, error}}, acc ->
          Logger.error("❌ Failed to process #{url}: #{inspect(error)}")
          acc
      end)

    jobs =
      Enum.reduce(results, [], fn
        {:ok, {_url, {jobs, _images}}}, jobs_acc ->
          jobs_acc ++ jobs

        {url, {:error, error}}, acc ->
          Logger.error("❌ Failed to process #{url}: #{inspect(error)}")
          acc
      end)

    {:noreply,
     socket
     |> assign(:images, images)
     |> assign(:jobs, jobs)}
  end

  @impl true
  def handle_async(:crawl_task, {:exit, reason}, socket) do
    Logger.error("❌ Crawl task failed: #{inspect(reason)}")

    {:noreply, put_flash(socket, :error, "Crawl failed: #{inspect(reason)}")}
  end

  @impl true
  def handle_info({:crawl_log, message}, socket) do
    {:noreply, update_log(socket, message)}
  end

  @impl true
  def handle_info({:update_jobs, {:ok, %AlgoraCloud.JobCrawler{job_postings: jobs}}}, socket) do
    dbg(jobs)
    {:noreply, assign(socket, :jobs, jobs)}
  end

  @impl true
  def handle_info({:update_jobs, {:partial, %AlgoraCloud.JobCrawler{job_postings: jobs}}}, socket) do
    dbg(jobs)
    {:noreply, assign(socket, :jobs, jobs)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-background" phx-hook="LocalStateStore" id="crawl-page" data-storage="localStorage">
      <div class="max-w-7xl mx-auto py-8 space-y-8">
        <.header>
          Crawl Organizations
          <:subtitle>Crawl organization data from multiple URLs</:subtitle>
        </.header>

        <.form for={@form} phx-submit="crawl" class="space-y-4">
          <.input
            type="textarea"
            field={@form[:urls]}
            label="URLs"
            placeholder="Enter URLs (one per line)"
            helptext="Enter organization URLs to crawl (one per line)"
          />

          <div class="flex justify-between items-center">
            <.button type="submit">
              Start Crawl
            </.button>
          </div>
        </.form>

        <%= if @logs != [] do %>
          <div class="bg-muted flex flex-col-reverse font-mono gap-2 overflow-y-auto p-4 rounded-lg text-sm max-h-[100px]">
            <%= for log <- Enum.reverse(@logs) do %>
              <div>{log}</div>
            <% end %>
          </div>
        <% end %>

        <div class="space-y-8">
          <%= if @jobs != [] do %>
            <div>
              <div class="flex justify-between items-center mb-4">
                <h2 class="text-lg font-semibold">Jobs ({length(@jobs)})</h2>
                <.button
                  type="button"
                  variant="outline"
                  onclick={"navigator.clipboard.writeText(#{Jason.encode!(jobs_to_csv(@jobs))}); alert('Copied to clipboard!')"}
                >
                  Copy as CSV
                </.button>
              </div>

              <div class="-mx-4 overflow-x-auto">
                <.table id="jobs" rows={@jobs}>
                  <:col :let={job} label="Title">{job.title}</:col>
                  <:col :let={job} label="URL">
                    <.link href={job.url} target="_blank" class="text-foreground hover:underline">
                      {job.url}
                    </.link>
                  </:col>
                  <:col :let={job} label="Location">{job.location}</:col>
                  <:col :let={job} label="Tech Stack">
                    <div class="flex gap-2 flex-wrap">
                      <%= for tech <- job.tech_stack || [] do %>
                        <.badge>{tech}</.badge>
                      <% end %>
                    </div>
                  </:col>
                </.table>
              </div>
            </div>
          <% end %>

          <%= if @images != [] do %>
            <div>
              <h2 class="text-lg font-semibold mb-4">Images ({length(@images)})</h2>
              <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
                <%= for image <- @images do %>
                  <a href={image} target="_blank" class="aspect-square rounded-lg overflow-hidden">
                    <img src={image} alt="" class="w-full h-full object-cover" />
                  </a>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp jobs_to_csv(jobs) do
    headers = ~w(title url description tech_stack location)

    rows =
      for job <- jobs do
        [
          job.title || "",
          job.url || "",
          job.description || "",
          Enum.join(job.tech_stack || [], ","),
          job.location || ""
        ]
      end

    ([headers] ++ rows)
    |> CSV.encode()
    |> Enum.join("")
  end

  defp broadcast_log(message) do
    Logger.info(message)
    Phoenix.PubSub.broadcast(Algora.PubSub, "crawl_logs", {:crawl_log, message})
  end

  defp update_log(socket, message) do
    update(socket, :logs, fn logs -> [message | logs] end)
  end
end
