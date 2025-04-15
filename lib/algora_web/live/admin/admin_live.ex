defmodule AlgoraWeb.Admin.AdminLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.Activity

  alias Algora.Activities
  alias Algora.Admin.Mainthings
  alias Algora.Admin.Mainthings.Mainthing
  alias Algora.Analytics
  alias Algora.Markdown

  def mount(_params, _session, socket) do
    {:ok, analytics} = Analytics.get_company_analytics()
    funnel_data = Analytics.get_funnel_data()
    :ok = Activities.subscribe()

    mainthing = Mainthings.get_latest()

    notes_changeset =
      Mainthing.changeset(%Mainthing{content: (mainthing && mainthing.content) || ""}, %{})

    # Get saved queries from settings
    saved_queries = get_saved_queries()

    timezone = if(params = get_connect_params(socket), do: params["timezone"])

    {:ok,
     socket
     |> assign(:ip_address, AlgoraWeb.Util.get_ip(socket))
     |> assign(:timezone, timezone)
     |> assign(:analytics, analytics)
     |> assign(:funnel_data, funnel_data)
     |> assign(:selected_period, "30d")
     |> assign(:notes_form, to_form(notes_changeset))
     |> assign(:notes_preview, (mainthing && Markdown.render_unsafe(mainthing.content)) || "")
     |> assign(:mainthing, mainthing)
     |> assign(:notes_edit_mode, false)
     |> assign(:notes_full_screen, false)
     |> assign(:plausible_embed_url, Application.get_env(:algora, :plausible_embed_url))
     |> assign(:posthog_project_id, Application.get_env(:algora, :posthog_project_id))
     # Start with empty query
     |> assign(:sql_query, "")
     |> assign(:query_results, nil)
     |> assign(:saved_queries, saved_queries)
     |> assign(:save_dialog, false)
     |> assign(:new_query_name, "")
     |> stream(:activities, [])
     |> start_async(:get_activities, fn -> Activities.all() end)}
  end

  def cell(%{value: %NaiveDateTime{} = value} = assigns) do
    ~H"""
    <span :if={@timezone} class="tabular-nums whitespace-nowrap text-sm">
      {Calendar.strftime(
        DateTime.from_naive!(value, "Etc/UTC") |> DateTime.shift_zone!(@timezone),
        "%Y/%m/%d, %H:%M:%S"
      )}
    </span>
    """
  end

  def cell(%{value: value} = assigns) when is_binary(value) do
    cond do
      String.starts_with?(value, "https://github.com/") ->
        ~H"""
        <div class="flex items-center gap-2 text-sm">
          <.link
            href={@value}
            rel="noopener"
            target="_blank"
            class="h-8 w-8 rounded-lg bg-muted flex items-center justify-center hover:bg-muted-foreground/40"
          >
            <.icon name="github" class="h-4 w-4" />
          </.link>
          {@value |> String.replace("https://github.com/", "")}
        </div>
        """

      String.starts_with?(value, "https://algora-console.fly.storage.tigris.dev") or
        String.starts_with?(value, "https://avatars.githubusercontent.com") or
        String.starts_with?(value, "https://app.algora.io/asset") or
        String.starts_with?(value, "https://console.algora.io/asset") or
        String.starts_with?(value, "https://algora.io/asset") or
        String.starts_with?(value, "https://www.gravatar.com") or
        String.starts_with?(value, "https://media.licdn.com") or
        String.starts_with?(value, "https://pbs.twimg.com") or
          String.starts_with?(value, "https://gravatar.com") ->
        ~H"""
        <div class="flex justify-center">
          <img src={@value} class="h-6 w-6 rounded-full" />
        </div>
        """

      String.match?(value, ~r/^[^\s]+@[^\s]+$/) && assigns.posthog_project_id ->
        ~H"""
        <div class="flex items-center gap-2 text-sm">
          <.link
            href={"https://us.posthog.com/project/#{@posthog_project_id}/person/#{@value}#activeTab=sessionRecordings"}
            rel="noopener"
            target="_blank"
            class="h-8 w-8 rounded-lg bg-muted flex items-center justify-center hover:bg-muted-foreground/40"
          >
            <.icon name="tabler-video" class="h-4 w-4" />
          </.link>
          {@value}
        </div>
        """

      String.match?(value, ~r/^[^\s]+@[^\s]+$/) ->
        ~H"""
        {@value}
        """

      String.length(value) == 2 ->
        country_emoji = Algora.Misc.CountryEmojis.get(value)

        ~H"""
        <div class="flex justify-center">
          {if country_emoji, do: country_emoji, else: @value}
        </div>
        """

      true ->
        ~H"""
        <span class="text-sm">
          {@value}
        </span>
        """
    end
  end

  def cell(%{value: value} = assigns) when is_list(value) do
    ~H"""
    <div class="flex gap-2 whitespace-nowrap">
      <%= for item <- @value do %>
        <.badge>{item}</.badge>
      <% end %>
    </div>
    """
  end

  def cell(%{value: value} = assigns) when is_map(value) do
    ~H"""
    <pre class="flex gap-2 whitespace-pre-wrap font-mono">
      {Jason.encode!(@value, pretty: true)}
    </pre>
    """
  end

  def cell(%{value: {currency, amount}} = assigns) do
    ~H"""
    <div class="font-display font-medium text-base text-emerald-400 tabular-nums text-right">
      {Money.new!(currency, amount)}
    </div>
    """
  end

  def cell(assigns) do
    ~H"""
    <span class="text-sm">
      {@value}
    </span>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-8 p-8">
      <div class="text-sm text-muted-foreground">
        Connected from: <code class="font-mono">{@ip_address}</code>
      </div>
      <section id="sql" class="scroll-mt-16">
        <div class="mb-4">
          <h1 class="text-2xl font-bold">SQL Query</h1>
          <div class="mt-2 flex flex-wrap gap-2">
            <%= for {name, _query} <- @saved_queries do %>
              <.badge
                variant="success"
                phx-click="load_query"
                phx-value-name={name}
                class="cursor-pointer"
              >
                {name}
              </.badge>
            <% end %>
          </div>
        </div>
        <.simple_form for={%{}} phx-submit="save_query">
          <div class="flex items-center justify-between gap-4 w-full">
            <div class="flex-1 w-full">
              <.input type="text" name="query_name" value={@new_query_name} placeholder="Query name" />
            </div>
            <.button type="submit">Save</.button>
          </div>
        </.simple_form>
        <.simple_form for={%{}} phx-submit="execute_query" phx-change="validate_query" class="pt-4">
          <.input
            type="textarea"
            name="query"
            value={@sql_query}
            rows={if @sql_query != "", do: "12"}
            class="font-mono"
            phx-hook="CtrlEnterSubmit"
          />
        </.simple_form>

        <div class="mt-4 overflow-x-auto">
          <%= case @query_results do %>
            <% {:ok, results} -> %>
              <table class="w-full">
                <thead>
                  <tr class="border-b border-border">
                    <%= for column <- Enum.map(results.columns, &String.to_atom/1) do %>
                      <th class="p-4 text-left font-mono">{column}</th>
                    <% end %>
                  </tr>
                </thead>
                <tbody>
                  <%= for row <- results.rows do %>
                    <tr class="border-b border-border">
                      <%= for value <- row do %>
                        <td class="p-4">
                          <.cell
                            value={value}
                            timezone={@timezone}
                            posthog_project_id={@posthog_project_id}
                          />
                        </td>
                      <% end %>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            <% {:error, error} -> %>
              <.alert variant="destructive">{error.postgres.message}</.alert>
            <% _ -> %>
          <% end %>
        </div>
      </section>

      <section id="notes" class="scroll-mt-16">
        <div class="mb-4 flex items-center justify-between">
          <h1 class="text-2xl font-bold">Notes</h1>
          <div class="flex gap-2">
            <.button
              type="button"
              phx-click="notes-toggle"
              variant={if @notes_edit_mode, do: "secondary", else: "default"}
            >
              {if @notes_edit_mode, do: "Preview", else: "Edit"}
            </.button>
            <.button type="button" variant="secondary" phx-click="notes-fullscreen-toggle">
              {if @notes_full_screen, do: "Minimize", else: "Maximize"}
            </.button>
          </div>
        </div>

        <div
          id="notes-container"
          class={[
            "overflow-hidden transition-all duration-300",
            if(@notes_full_screen,
              do: "max-h-none",
              else: "max-h-[60svh] overflow-y-auto scrollbar-thin"
            )
          ]}
        >
          <div id="notes-edit" class={if @notes_edit_mode, do: "block", else: "hidden"}>
            <.simple_form for={@notes_form} phx-change="validate_notes" phx-submit="save_notes">
              <div>
                <.input
                  field={@notes_form[:content]}
                  type="textarea"
                  class="h-full scrollbar-thin"
                  phx-debounce="300"
                  rows={10}
                />
              </div>
              <div class="flex justify-end">
                <.button type="submit">Save Notes</.button>
              </div>
            </.simple_form>
          </div>

          <div
            id="notes-preview"
            class={["h-full", if(@notes_edit_mode, do: "hidden", else: "block")]}
          >
            <div class="h-full rounded-lg border bg-muted/40 p-4 overflow-y-auto">
              <div class="prose prose-sm max-w-none prose-invert">
                {raw(@notes_preview)}
              </div>
            </div>
          </div>
        </div>
      </section>

      <section id="metrics" class="scroll-mt-16">
        <div class="mb-4">
          <h1 class="text-2xl font-bold">Metrics</h1>
        </div>
        <div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
          <.stat_card
            title="Total Companies"
            value={@analytics.current_companies}
            change={@analytics.companies_change}
            trend={@analytics.companies_trend}
          />
          <.stat_card
            title="Active Companies"
            value={@analytics.active_current}
            change={@analytics.active_change}
            trend={@analytics.active_trend}
          />
          <.stat_card
            title="Avg Time to Fill"
            value={"#{@analytics.avg_time_to_fill}d"}
            change={@analytics.time_to_fill_change}
            trend={@analytics.time_to_fill_trend}
          />
          <.stat_card
            title="Bounty Success Rate"
            value={"#{@analytics.bounty_success_rate}%"}
            change={@analytics.success_rate_change}
            trend={@analytics.success_rate_trend}
          />
        </div>
      </section>

      <section id="customers" class="scroll-mt-16">
        <div class="mb-4">
          <h1 class="text-2xl font-bold">Customers</h1>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead>
              <tr class="border-b border-border">
                <th class="p-4 text-left">Company</th>
                <th class="p-4 text-left">Joined</th>
                <th class="p-4 text-left">Status</th>
                <th class="p-4 text-left">Bounties</th>
                <th class="p-4 text-left">Success Rate</th>
                <th class="p-4 text-left">Last Active</th>
              </tr>
            </thead>
            <tbody>
              <%= for company <- @analytics.companies do %>
                <tr class="border-b border-border">
                  <td class="p-4">
                    <div class="flex items-center gap-3">
                      <.avatar class="h-8 w-8">
                        <.avatar_image src={company.avatar_url} />
                      </.avatar>
                      <div>
                        <div class="font-medium">{company.name}</div>
                        <div class="text-sm text-muted-foreground">@{company.handle}</div>
                      </div>
                    </div>
                  </td>
                  <td class="p-4 text-sm">
                    {Calendar.strftime(company.joined_at, "%b %d, %Y")}
                  </td>
                  <td class="p-4">
                    <.badge variant={status_color(company.status)}>
                      {company.status}
                    </.badge>
                  </td>
                  <td class="p-4 text-sm">
                    {company.total_bounties}
                  </td>
                  <td class="p-4 text-sm">
                    {company.success_rate}%
                  </td>
                  <td class="p-4 text-sm text-muted-foreground">
                    {Calendar.strftime(company.last_active_at, "%b %d, %Y")}
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </section>

      <section id="funnel" class="scroll-mt-16">
        <div class="mx-auto h-500 flex">
          <div class="w-3/4 p-0">
            <.card>
              <.card_header>
                <.card_title>Funnel</.card_title>
              </.card_header>
              <.card_content>
                <div class="h-[400px]" phx-update="ignore" id="funnel-chart">
                  <canvas id="funnelChart"></canvas>
                </div>
              </.card_content>
            </.card>
          </div>
          <.scroll_area class="w-1/4 ml-4 pr-4">
            <.card class="h-[500px]">
              <.card_header>
                <.card_title>Recent Activities</.card_title>
              </.card_header>
              <.activities_timeline id="admin-activities-timeline" activities={@streams.activities} />
            </.card>
          </.scroll_area>
        </div>
      </section>

      <section id="traffic" class="scroll-mt-16">
        <div class="mb-4">
          <h1 class="text-2xl font-bold">Traffic</h1>
        </div>
        <iframe
          :if={@plausible_embed_url}
          src={@plausible_embed_url}
          plausible-embed=""
          loading="lazy"
          style="width: 1; min-width: 1280px; height: 2100px; margin-left: -1rem;"
        />
      </section>
    </div>
    """
  end

  def status_color(:active), do: "success"
  def status_color(:pending), do: "warning"
  def status_color(_), do: "secondary"

  def handle_event("select_period", %{"period" => period}, socket) do
    {:ok, analytics} = Analytics.get_company_analytics(period)
    funnel_data = Analytics.get_funnel_data(period)

    {:noreply,
     socket
     |> assign(:analytics, analytics)
     |> assign(:funnel_data, funnel_data)
     |> assign(:selected_period, period)}
  end

  def handle_event("validate_notes", %{"mainthing" => %{"content" => content}}, socket) do
    changeset =
      %Mainthing{}
      |> Mainthing.changeset(%{content: content})
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:notes_form, to_form(changeset))
     |> assign(:notes_preview, Markdown.render_unsafe(content))}
  end

  def handle_event("save_notes", %{"mainthing" => params}, socket) do
    case_result =
      case socket.assigns.mainthing do
        nil -> Mainthings.create(params)
        mainthing -> Mainthings.update(mainthing, params)
      end

    case case_result do
      {:ok, mainthing} ->
        {:noreply,
         socket
         |> assign(:mainthing, mainthing)
         |> assign(:notes_preview, Markdown.render_unsafe(mainthing.content))
         |> assign(:notes_edit_mode, false)
         |> put_flash(:info, "Notes saved successfully")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:notes_form, to_form(changeset))
         |> put_flash(:error, "Error saving notes")}
    end
  end

  def handle_event("notes-toggle", _, socket) do
    {:noreply, assign(socket, :notes_edit_mode, !socket.assigns.notes_edit_mode)}
  end

  def handle_event("notes-fullscreen-toggle", _, socket) do
    {:noreply, assign(socket, :notes_full_screen, !socket.assigns.notes_full_screen)}
  end

  def handle_event("validate_query", %{"query" => query}, socket) do
    {:noreply, assign(socket, :sql_query, query)}
  end

  def handle_event("execute_query", %{"query" => query}, socket) do
    results = execute_sql_query(query)
    {:noreply, socket |> assign(:sql_query, query) |> assign(:query_results, results)}
  end

  def handle_event("save_query", %{"query_name" => name}, socket) when byte_size(name) > 0 do
    save_query(name, socket.assigns.sql_query)
    saved_queries = get_saved_queries()

    {:noreply, assign(socket, :saved_queries, saved_queries)}
  end

  def handle_event("load_query", %{"name" => name}, socket) do
    queries = get_saved_queries()
    query = Map.get(queries, name)
    {:noreply, assign(socket, sql_query: query, new_query_name: name)}
  end

  def handle_info(%Activities.Activity{} = activity, socket) do
    {:noreply, stream_insert(socket, :activities, activity, at: 0)}
  end

  def handle_async(:get_activities, {:ok, fetched}, socket) do
    {:noreply, stream(socket, :activities, fetched)}
  end

  defp execute_sql_query(query) do
    output =
      Algora.Repo.transaction(fn ->
        case Ecto.Adapters.SQL.query(Algora.Repo, query, [], timeout: 1_000) do
          {:ok, results} ->
            Algora.Repo.rollback({:ok, results})

          {:error, error} ->
            Algora.Repo.rollback({:error, error})
        end
      end)

    case output do
      {:error, {:ok, results}} -> {:ok, results}
      {:error, {:error, reason}} -> {:error, reason}
    end
  end

  defp get_saved_queries do
    Algora.Settings.get("saved_queries") || %{}
  end

  defp save_query(name, query) do
    queries = get_saved_queries()
    updated_queries = Map.put(queries, name, query)
    Algora.Settings.set("saved_queries", updated_queries)
  end
end
