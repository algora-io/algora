defmodule AlgoraWeb.Onboarding.OrgLive do
  @moduledoc false
  use AlgoraWeb, :live_view
  use LiveSvelte.Components

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

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :form, to_form(Form.changeset(%Form{}, %{})))}
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

      <div class="flex-1 p-4 md:py-4 flex items-center justify-center overflow-hidden">
        <div class="w-full">
          <!-- Cal.com embed -->
          <div style="width: 100%; height: 100%; overflow: scroll" id="cal-embed"></div>
          <script type="text/javascript">
            (function (C, A, L) {
              let p = function (a, ar) {
                a.q.push(ar);
              };
              let d = C.document;
              C.Cal =
                C.Cal ||
                function () {
                  let cal = C.Cal;
                  let ar = arguments;
                  if (!cal.loaded) {
                    cal.ns = {};
                    cal.q = cal.q || [];
                    d.head.appendChild(d.createElement("script")).src = A;
                    cal.loaded = true;
                  }
                  if (ar[0] === L) {
                    const api = function () {
                      p(api, arguments);
                    };
                    const namespace = ar[1];
                    api.q = api.q || [];
                    if (typeof namespace === "string") {
                      cal.ns[namespace] = cal.ns[namespace] || api;
                      p(cal.ns[namespace], ar);
                      p(cal, ["initNamespace", namespace]);
                    } else p(cal, ar);
                    return;
                  }
                  p(cal, ar);
                };
            })(window, "https://app.cal.com/embed/embed.js", "init");
            Cal("init", { origin: "https://app.cal.com" });

            Cal("inline", {
              elementOrSelector: "#cal-embed",
              calLink: "ioannisflo/15min",
              config: {
                theme: "dark",
              },
            });
          </script>
          
    <!-- Commented out original form -->
          <!--
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
                field={@form[:candidate_description]}
                type="textarea"
                label="Describe your ideal candidate, heuristics, green/red flags etc."
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
          -->
        </div>
      </div>

      <footer class="w-full py-4 border-t border-white/20">
        <div class="container mx-auto px-4">
          <div class="flex flex-col md:flex-row items-center justify-between gap-6">
            <div class="text-sm text-muted-foreground text-center md:text-left w-full md:w-auto">
              © 2025 Algora PBC. All rights reserved.
            </div>
            <div class="grid grid-cols-1 md:flex md:flex-row items-stretch gap-2 w-full md:w-auto">
              <.link
                class="w-full md:w-auto flex items-center justify-center gap-2 rounded-lg border border-gray-700 py-2 pl-2 pr-3.5 text-xs text-muted-foreground hover:text-foreground transition-colors hover:border-gray-600"
                href={AlgoraWeb.Constants.get(:calendar_url)}
                rel="noopener"
              >
                <.icon name="tabler-calendar-clock" class="size-4" />
                <span>Schedule a call</span>
              </.link>
              <.link
                class="w-full md:w-auto flex items-center justify-center gap-2 rounded-lg border border-gray-700 py-2 pl-2 pr-3.5 text-xs text-muted-foreground hover:text-foreground transition-colors hover:border-gray-600"
                href="tel:+16504202207"
              >
                <.icon name="tabler-phone" class="size-4" /> US <span>+1 (650) 420-2207</span>
              </.link>
              <.link
                class="w-full md:w-auto flex items-center justify-center gap-2 rounded-lg border border-gray-700 py-2 pl-2 pr-3.5 text-xs text-muted-foreground hover:text-foreground transition-colors hover:border-gray-600"
                href="tel:+306973184144"
              >
                <.icon name="tabler-phone" class="size-4" /> EU <span>+30 (697) 318-4144</span>
              </.link>
            </div>
          </div>
        </div>
      </footer>
    </main>
    """
  end
end
