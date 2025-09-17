defmodule AlgoraWeb.Onboarding.OrgLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

  require Logger

  defmodule Form do
    @moduledoc false
    use Ecto.Schema

    @primary_key false
    @derive {Jason.Encoder, only: [:email, :job_description, :candidate_description, :comp_range]}
    embedded_schema do
      field :email, :string
      field :job_description, :string
      field :candidate_description, :string
      field :comp_range, :string
    end

    def changeset(form, attrs \\ %{}) do
      form
      |> Ecto.Changeset.cast(attrs, [:email, :job_description, :candidate_description, :comp_range])
      |> Ecto.Changeset.validate_required([:email, :job_description])
      |> Ecto.Changeset.validate_format(:email, ~r/@/)
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :form, to_form(Form.changeset(%Form{}, %{})))}
  end

  defp placeholder_text do
    """
    - GitHub looks like a green carpet
    - Has contributions to open source inference engines (e.g. vLLM)
    - Posts regularly on X and LinkedIn
    """
  end

  @impl true
  def handle_event("submit", %{"form" => params}, socket) do
    case %Form{} |> Form.changeset(params) |> Ecto.Changeset.apply_action(:save) do
      {:ok, data} ->
        # Create alert for immediate notification
        Algora.Activities.alert(Jason.encode!(data), :critical)

        # Create admin task for welcoming the user
        create_welcome_task(data)

        {:noreply, put_flash(socket, :info, "Thanks for submitting your JD! We'll follow up soon")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp create_welcome_task(data) do
    task_attrs = %{
      type: "user_welcome",
      payload: %{
        email: data.email,
        job_description: data.job_description,
        candidate_description: data.candidate_description,
        comp_range: data.comp_range,
        submitted_at: DateTime.utc_now(),
        source: "jd_submission"
      },
      seq: 0,
      origin_id: Nanoid.generate()
    }

    case Algora.Cloud.create_admin_task(task_attrs) do
      {:ok, _task} ->
        Logger.info("Created welcome task for #{data.email}")

      {:error, changeset} ->
        Logger.error("Failed to create welcome task: #{inspect(changeset)}")
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="bg-background relative overflow-hidden min-h-screen flex flex-col">
      <header class="w-full border-b border-white/20">
        <div class="flex items-center bg-background">
          <div class="px-6">
            <.wordmark class="h-8 w-auto" />
          </div>
          <div class="flex-1 h-full flex flex-col bg-black border-l border-white/20 px-6 pl-8 pt-6 pb-3 -mt-5">
            <span class="text-xs text-muted-foreground font-medium">Trusted by</span>
            <div class="relative w-full">
              <div class="mt-1 flex items-center gap-12 overflow-x-auto scrollbar-thin pb-4">
                <img src="/images/wordmarks/keep.png" alt="Keep" class="h-10 saturate-0 shrink-0" />
                <img
                  src="/images/wordmarks/triggerdotdev.png"
                  alt="Trigger.dev"
                  class="h-6 saturate-0 shrink-0"
                />
                <img
                  src="/images/wordmarks/traceloop.png"
                  alt="Traceloop"
                  class="h-6 saturate-0 shrink-0"
                />
                <img
                  src="/images/wordmarks/million.png"
                  alt="Million"
                  class="h-6 saturate-0 shrink-0"
                />
                <img src="/images/wordmarks/moonrepo.svg" alt="moon" class="h-5 shrink-0" />
                <img
                  src="/images/wordmarks/dittofeed.png"
                  alt="Dittofeed"
                  class="h-6 brightness-0 invert shrink-0"
                />
                <img
                  src={~p"/images/wordmarks/highlight.png"}
                  alt="Highlight"
                  class="h-6 saturate-0 shrink-0"
                  loading="lazy"
                />
              </div>
            </div>
          </div>
        </div>
      </header>

      <div class="flex-1 p-4 md:py-4 flex items-center justify-center max-h-[calc(100vh-11rem)] overflow-y-auto scrollbar-thin">
        <div class="w-full max-w-[28rem] text-left">
          <.form for={@form} phx-submit="submit" class="flex flex-col gap-6">
            <.input
              field={@form[:email]}
              type="email"
              label="Work email"
              placeholder="you@company.com"
            />
            <.input
              field={@form[:job_description]}
              type="textarea"
              label="Job description / careers URL"
              rows="3"
              class="resize-none"
              placeholder="Tell us about the role and your requirements..."
            />
            <.input
              field={@form[:comp_range]}
              type="text"
              label="Compensation range"
              placeholder="$150k - $250k"
            />
            <.input
              field={@form[:candidate_description]}
              type="textarea"
              label="Describe your ideal candidate"
              rows="3"
              class="resize-none"
              placeholder={placeholder_text()}
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

      <footer class="w-full py-4 border-t border-white/20">
        <div class="container mx-auto px-4">
          <div class="flex flex-col md:flex-row items-center justify-between gap-6">
            <div class="text-sm text-foreground/90 text-center md:text-left w-full md:w-auto">
              © 2025 Algora PBC. All rights reserved.
            </div>
            <div class="grid grid-cols-1 md:flex md:flex-row items-stretch gap-2 w-full md:w-auto">
              <.link
                class="w-full md:w-auto flex items-center justify-center rounded-lg border border-gray-500 py-2 pl-2 pr-3.5 text-xs text-foreground/90 hover:text-foreground transition-colors hover:border-gray-400"
                href={AlgoraWeb.Constants.get(:calendar_url)}
                rel="noopener"
              >
                <.icon name="tabler-calendar-clock" class="size-4" />
                <span class="ml-2">Schedule a call</span>
              </.link>
              <.link
                class="w-full md:w-auto flex items-center justify-center rounded-lg border border-gray-500 py-2 pl-2 pr-3.5 text-xs text-foreground/90 hover:text-foreground transition-colors hover:border-gray-400"
                href="tel:+16504202207"
              >
                <.icon name="tabler-phone" class="size-4" /> <span class="font-bold ml-1">US</span>
                <span class="ml-2">+1 (650) 420-2207</span>
              </.link>
              <.link
                class="w-full md:w-auto flex items-center justify-center rounded-lg border border-gray-500 py-2 pl-2 pr-3.5 text-xs text-foreground/90 hover:text-foreground transition-colors hover:border-gray-400"
                href="tel:+306973184144"
              >
                <.icon name="tabler-phone" class="size-4" /> <span class="font-bold ml-1">EU</span>
                <span class="ml-2">+30 (697) 318-4144</span>
              </.link>
            </div>
          </div>
        </div>
      </footer>
    </main>
    """
  end
end
