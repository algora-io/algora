defmodule AlgoraWeb.Onboarding.OrgLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

  import AlgoraCloud.Components.CandidateCard

  alias Algora.Matches
  alias AlgoraCloud.LanguageContributions

  require Logger

  defmodule Form do
    @moduledoc false
    use Ecto.Schema

    @primary_key false
    @derive {Jason.Encoder,
             only: [:email, :job_description, :candidate_description, :comp_range, :location, :location_type, :tech_stack]}
    embedded_schema do
      field :email, :string
      field :job_description, :string
      field :candidate_description, :string
      field :comp_range, :string
      field :location, :string
      field :location_type, :string
      field :tech_stack, {:array, :string}
    end

    def changeset(form, attrs \\ %{}) do
      form
      |> Ecto.Changeset.cast(attrs, [
        :email,
        :job_description,
        :candidate_description,
        :comp_range,
        :location,
        :location_type,
        :tech_stack
      ])
      |> Ecto.Changeset.validate_required([:email, :job_description])
      |> Ecto.Changeset.validate_format(:email, ~r/@/)
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    # Load multiple candidates for carousel - using valid match IDs with different users
    candidate_ids = ["QGFEwrH3K7mipQGB", "ogftjcpCuvTLverF", "bVqi5v6HPYtUg1Fj", "LbJoZ78WJs1K2RVS"]

    candidates_data =
      candidate_ids
      |> Enum.map(&load_candidate_data/1)
      |> Enum.reject(&is_nil/1)

    socket =
      socket
      |> assign(:form, to_form(Form.changeset(%Form{}, %{tech_stack: []})))
      |> assign(:candidates_data, candidates_data)

    {:ok, socket}
  end

  defp load_candidate_data(match_id) do
    case Matches.get_job_match_by_id(match_id) do
      nil ->
        nil

      match ->
        # Preload the nested job_posting.user association
        match = Algora.Repo.preload(match, job_posting: :user)
        user = match.user

        # Fetch contributions for this user
        contributions = Algora.Workspace.list_user_contributions([user.id], exclude_personal: false, display_all: true)

        contributions_map = %{user.id => contributions}

        # Fetch language contributions for this user
        language_contributions_map =
          [user.id]
          |> LanguageContributions.list_language_contributions_batch()
          |> transform_language_contributions()

        # Fetch heatmap data for this user
        heatmaps_map =
          [user.id]
          |> AlgoraCloud.Profiles.list_heatmaps()
          |> Map.new(fn heatmap -> {heatmap.user_id, heatmap.data} end)

        # Build interviews map
        interviews_map = build_interviews_map([match])

        %{
          candidate: %{
            match: match,
            job_posting: match.job_posting,
            job_title: match.job_posting.title || "Software Engineer"
          },
          contributions_map: contributions_map,
          language_contributions_map: language_contributions_map,
          heatmaps_map: heatmaps_map,
          org_badge_data: nil,
          hiring_managers: [],
          interviews_map: interviews_map,
          current_org: match.job_posting.user,
          anonymize: false,
          base_anonymize: false,
          screenshot?: true,
          fullscreen?: false,
          current_user: nil,
          current_user_role: nil,
          tech_stack: match.job_posting.tech_stack || []
        }
    end
  end

  defp transform_language_contributions(contributions_map) do
    # Transform language contributions similar to candidates2_live.ex
    Map.new(contributions_map, fn {user_id, contributions} ->
      transformed =
        contributions
        |> Enum.map(fn contrib ->
          case contrib.language do
            "JavaScript" -> %{contrib | language: "TypeScript"}
            "Jupyter Notebook" -> %{contrib | language: "Python"}
            "Markdown" -> nil
            "MDX" -> nil
            "TeX" -> nil
            "HTML" -> nil
            "CSS" -> nil
            "Nunjucks" -> nil
            "Nushell" -> nil
            "reStructuredText" -> nil
            "Nix" -> nil
            "Makefile" -> nil
            "Emacs Lisp" -> nil
            "Mustache" -> nil
            _ -> contrib
          end
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.group_by(& &1.language)
        |> Enum.map(fn {_language, contribs} ->
          # Combine contributions for the same language
          Enum.reduce(contribs, fn contrib, acc ->
            %{
              acc
              | prs: acc.prs + contrib.prs,
                percentage: Decimal.add(acc.percentage, contrib.percentage)
            }
          end)
        end)
        |> Enum.sort_by(& &1.percentage, {:desc, Decimal})

      {user_id, transformed}
    end)
  end

  defp build_interviews_map(matches) do
    # Build interviews map for matches similar to candidates2_live.ex
    import Ecto.Query

    alias Algora.Repo

    user_ids = matches |> Enum.map(& &1.user_id) |> Enum.uniq()
    job_posting_ids = matches |> Enum.map(& &1.job_posting_id) |> Enum.uniq()

    interviews =
      Repo.all(
        from(ji in Algora.Interviews.JobInterview,
          where: ji.user_id in ^user_ids and ji.job_posting_id in ^job_posting_ids,
          preload: [:user]
        )
      )

    Enum.reduce(interviews, %{}, fn interview, acc ->
      Map.put(acc, {interview.user_id, interview.job_posting_id}, interview)
    end)
  end

  defp placeholder_text do
    """
    - GitHub looks like a green carpet
    - Has contributions to open source inference engines (e.g. vLLM)
    - Posts regularly on X and LinkedIn
    """
  end

  @impl true
  def handle_event("tech_stack_changed", %{"tech_stack" => tech_stack}, socket) do
    changeset = Form.changeset(socket.assigns.form.source, %{tech_stack: tech_stack})
    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("submit", %{"form" => params}, socket) do
    tech_stack =
      Jason.decode!(params["tech_stack"] || "[]") ++
        case String.trim(params["tech_stack_input"] || "") do
          "" -> []
          tech_stack_input -> String.split(tech_stack_input, ",")
        end

    params = Map.put(params, "tech_stack", tech_stack)

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
        location: data.location,
        location_type: data.location_type,
        tech_stack: data.tech_stack,
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
              <div class="mt-1 flex items-center gap-12 overflow-x-auto scrollbar-thin pb-0">
                <img src="/images/wordmarks/coderabbit.svg" alt="CodeRabbit" class="h-8 shrink-0" />
                <img src="/images/wordmarks/comfy.svg" alt="Comfy" class="h-6 shrink-0" />
                <img src="/images/wordmarks/lovable.svg" alt="Lovable" class="h-6 shrink-0" />
                <div class="flex items-center gap-1">
                  <img src="/images/wordmarks/firecrawl.svg" alt="Firecrawl" class="h-10 shrink-0" />
                  <img src="/images/wordmarks/firecrawl2.svg" alt="Firecrawl2" class="h-6 shrink-0" />
                </div>
                <img src="/images/wordmarks/golem.png" alt="Golem" class="h-8 shrink-0" />
                <img src="/images/wordmarks/calcom.png" alt="Cal.com" class="h-6 shrink-0" />
              </div>
            </div>
          </div>
        </div>
      </header>

      <div class="flex-1 p-4 md:py-4 flex items-center justify-center max-h-[calc(100vh-11rem)] overflow-hidden">
        <div class="w-full grid grid-cols-1 lg:grid-cols-[1fr_1.2fr] gap-6 items-center px-4 lg:px-8 max-w-[90rem]">
          <div class="w-full max-w-[32rem] text-left">
            <.form for={@form} phx-submit="submit" class="flex flex-col gap-4">
              <div>
                <label class="block text-sm font-medium text-foreground mb-2">
                  Tech stack
                </label>
                <.TechStack
                  tech={Ecto.Changeset.get_field(@form.source, :tech_stack) || []}
                  socket={@socket}
                  form="form"
                />
              </div>
              <.input
                field={@form[:job_description]}
                type="textarea"
                label="Job description / careers URL"
                rows="3"
                class="resize-none"
                placeholder="Tell us about the role, your requirements, your ideal candidate..."
              />
              <div class="grid grid-cols-2 gap-4">
                <.input
                  field={@form[:comp_range]}
                  type="text"
                  label="Compensation range"
                  placeholder="$150k - $250k"
                />
                <.input
                  field={@form[:location]}
                  type="text"
                  label="Location"
                  placeholder="San Francisco"
                />
              </div>
              <div class="space-y-2">
                <label class="block text-sm font-medium text-foreground">
                  Type
                </label>
                <div class="grid grid-cols-3 gap-3">
                  <label class="group relative flex cursor-pointer rounded-lg px-3 py-2.5 shadow-sm focus:outline-none border-2 bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10 border-border has-[:checked]:border-primary has-[:checked]:bg-primary/10">
                    <input type="radio" name="form[location_type]" value="onsite" class="sr-only" />
                    <div class="flex items-center gap-2">
                      <.icon name="tabler-building" class="h-5 w-5 text-primary shrink-0" />
                      <span class="text-sm text-foreground">
                        Onsite
                      </span>
                    </div>
                  </label>
                  <label class="group relative flex cursor-pointer rounded-lg px-3 py-2.5 shadow-sm focus:outline-none border-2 bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10 border-border has-[:checked]:border-primary has-[:checked]:bg-primary/10">
                    <input type="radio" name="form[location_type]" value="hybrid" class="sr-only" />
                    <div class="flex items-center gap-2">
                      <.icon name="tabler-arrows-shuffle" class="h-5 w-5 text-primary shrink-0" />
                      <span class="text-sm text-foreground">
                        Hybrid
                      </span>
                    </div>
                  </label>
                  <label class="group relative flex cursor-pointer rounded-lg px-3 py-2.5 shadow-sm focus:outline-none border-2 bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10 border-border has-[:checked]:border-primary has-[:checked]:bg-primary/10">
                    <input type="radio" name="form[location_type]" value="remote" class="sr-only" />
                    <div class="flex items-center gap-2">
                      <.icon name="tabler-home" class="h-5 w-5 text-primary shrink-0" />
                      <span class="text-sm text-foreground">
                        Remote
                      </span>
                    </div>
                  </label>
                </div>
              </div>
              <%!-- <.input
                field={@form[:candidate_description]}
                type="textarea"
                label="Describe your ideal candidate"
                rows="3"
                class="resize-none"
                placeholder={placeholder_text()}
              /> --%>
              <.input
                field={@form[:email]}
                type="email"
                label="Your work email"
                placeholder="you@company.com"
              />
              <div class="flex flex-col gap-3 mt-2">
                <.button class="w-full" type="submit">Receive your candidates</.button>
                <div class="text-xs text-muted-foreground text-center">
                  No credit card required - only pay when you hire
                </div>
              </div>
            </.form>
          </div>
          <div :if={length(@candidates_data) > 0} class="hidden lg:flex flex-col gap-3 w-full">
            <div
              id="candidate-carousel-org"
              phx-hook="CandidateCarousel"
              class="relative w-full"
            >
              <%= for {candidate_data, index} <- Enum.with_index(@candidates_data) do %>
                <div
                  data-carousel-item={index}
                  class={"transition-opacity duration-500 #{if index == 0, do: "opacity-100", else: "opacity-0 absolute inset-0"}"}
                >
                  <AlgoraCloud.Components.CandidateCard.candidate_card {Map.merge(candidate_data, %{screenshot?: true, fullscreen?: false, anonymize: true})} />
                </div>
              <% end %>
            </div>
          </div>
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
