defmodule AlgoraWeb.Admin.AdminLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  import AlgoraWeb.Components.Activity
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Activities
  alias Algora.Admin.Mainthings
  alias Algora.Admin.Mainthings.Mainthing
  alias Algora.Analytics
  alias Algora.Markdown
  alias Algora.Payments.Transaction
  alias Algora.Repo
  alias AlgoraWeb.Data.PlatformStats
  alias AlgoraWeb.LocalStore

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

  @impl true
  def mount(_params, _session, socket) do
    {:ok, analytics} = Analytics.get_company_analytics()
    funnel_data = Analytics.get_funnel_data()
    :ok = Activities.subscribe()

    platform_metrics = [
      %{label: "Paid Out", value: format_money(get_total_paid_out())},
      %{label: "Completed Bounties", value: format_number(get_completed_bounties_count())},
      %{label: "Contributors", value: format_number(get_contributors_count())},
      %{label: "Countries", value: format_number(get_countries_count())}
    ]

    # Get user metrics for the last 30 days
    user_metrics = Analytics.Metrics.get_user_metrics(30, :daily)

    mainthing = Mainthings.get_latest()

    notes_changeset =
      Mainthing.changeset(%Mainthing{content: (mainthing && mainthing.content) || ""}, %{})

    # Get saved queries from settings
    saved_queries = get_saved_queries()

    timezone = if(params = get_connect_params(socket), do: params["timezone"])

    {:ok,
     socket
     |> assign(:timezone, timezone)
     |> assign(:analytics, analytics)
     |> assign(:funnel_data, funnel_data)
     |> assign(:user_metrics, user_metrics)
     |> assign(:platform_metrics, platform_metrics)
     |> assign(:selected_period, :daily)
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8 p-8" phx-hook="LocalStateStore" id="admin-page" data-storage="localStorage">
      <section id="user-metrics" class="scroll-mt-16 space-y-4">
        <h1 class="text-2xl font-bold">Metrics</h1>
        <div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
          <%= for metric <- @platform_metrics do %>
            <.stat_card title={metric.label} value={metric.value} />
          <% end %>
        </div>
        <div :if={@timezone} class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
          <%= for {date, metrics} <- Enum.take(@user_metrics, 1) do %>
            <.stat_card
              title="Organization Signups"
              value={metrics.org_signups}
              subtext={format_date(date, @timezone)}
            />
            <.stat_card
              title="Organization Returns"
              value={metrics.org_returns}
              subtext={format_date(date, @timezone)}
            />
            <.stat_card
              title="Developer Signups"
              value={metrics.dev_signups}
              subtext={format_date(date, @timezone)}
            />
            <.stat_card
              title="Developer Returns"
              value={metrics.dev_returns}
              subtext={format_date(date, @timezone)}
            />
          <% end %>
        </div>
      </section>

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
                    <%= for column <- Enum.map(results.columns || [], &String.to_atom/1) do %>
                      <th class="p-4 text-left font-mono">{column}</th>
                    <% end %>
                  </tr>
                </thead>
                <tbody>
                  <%= for row <- (results.rows || []) do %>
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

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> LocalStore.init(key: __MODULE__, ttl: :infinity)
     |> LocalStore.subscribe()}
  end

  @impl true
  def handle_event("restore_settings", params, socket) do
    socket = LocalStore.restore(socket, params)

    {:noreply, assign(socket, :query_results, execute_sql_query(socket.assigns.sql_query))}
  end

  @impl true
  def handle_event("select_period", %{"period" => period}, socket) do
    {:ok, analytics} = Analytics.get_company_analytics()
    funnel_data = Analytics.get_funnel_data()

    {:noreply,
     socket
     |> assign(:analytics, analytics)
     |> assign(:funnel_data, funnel_data)
     |> assign(:selected_period, period)}
  end

  @impl true
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

  @impl true
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

  @impl true
  def handle_event("notes-toggle", _, socket) do
    {:noreply, assign(socket, :notes_edit_mode, !socket.assigns.notes_edit_mode)}
  end

  @impl true
  def handle_event("notes-fullscreen-toggle", _, socket) do
    {:noreply, assign(socket, :notes_full_screen, !socket.assigns.notes_full_screen)}
  end

  @impl true
  def handle_event("validate_query", %{"query" => query}, socket) do
    {:noreply, LocalStore.assign_cached(socket, :sql_query, query)}
  end

  @impl true
  def handle_event("execute_query", %{"query" => query}, socket) do
    results = execute_sql_query(query)

    {:noreply,
     socket
     |> LocalStore.assign_cached(:sql_query, query)
     |> assign(:query_results, results)}
  end

  @impl true
  def handle_event("save_query", %{"query_name" => name}, socket) when byte_size(name) > 0 do
    save_query(name, socket.assigns.sql_query)
    saved_queries = get_saved_queries()

    {:noreply, assign(socket, :saved_queries, saved_queries)}
  end

  @impl true
  def handle_event("load_query", %{"name" => name}, socket) do
    queries = get_saved_queries()
    query = Map.get(queries, name)

    {:noreply,
     socket
     |> LocalStore.assign_cached(:sql_query, query)
     |> LocalStore.assign_cached(:new_query_name, name)
     |> assign(:query_results, execute_sql_query(query))}
  end

  @impl true
  def handle_info(%Activities.Activity{} = activity, socket) do
    {:noreply, stream_insert(socket, :activities, activity, at: 0)}
  end

  @impl true
  def handle_async(:get_activities, {:ok, fetched}, socket) do
    {:noreply, stream(socket, :activities, fetched)}
  end

  defp cell(%{value: %NaiveDateTime{}} = assigns) do
    ~H"""
    <span :if={@timezone} class="tabular-nums whitespace-nowrap text-sm">
      {format_date(@value, @timezone)}
    </span>
    """
  end

  defp cell(%{value: value} = assigns) when is_binary(value) do
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

      String.match?(value, ~r/^[A-Z]{2}$/) ->
        assigns = assign(assigns, :flag, Algora.Misc.CountryEmojis.get(value))

        ~H"""
        <div class="flex justify-center">
          {if @flag, do: @flag, else: @value}
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

  defp cell(%{value: value} = assigns) when is_list(value) do
    ~H"""
    <div class="flex gap-2 whitespace-nowrap">
      <%= for item <- @value do %>
        <.badge>{item}</.badge>
      <% end %>
    </div>
    """
  end

  defp cell(%{value: value} = assigns) when is_map(value) do
    ~H"""
    <pre class="flex gap-2 whitespace-pre-wrap font-mono">
      {Jason.encode!(@value, pretty: true)}
    </pre>
    """
  end

  defp cell(%{value: {currency, amount}} = assigns) do
    assigns = assign(assigns, :money, Money.new!(currency, amount))

    ~H"""
    <div class="font-display font-medium text-base text-emerald-400 tabular-nums text-right">
      {@money}
    </div>
    """
  end

  defp cell(assigns) do
    ~H"""
    <span class="text-sm">
      {@value}
    </span>
    """
  end

  defp status_color(:active), do: "success"
  defp status_color(:pending), do: "warning"
  defp status_color(_), do: "secondary"

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

  defp format_date(date, timezone) do
    date
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!(timezone)
    |> Calendar.strftime("%Y/%m/%d, %H:%M:%S")
  end
end
