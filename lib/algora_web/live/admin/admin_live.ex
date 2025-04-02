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
    notes_changeset = Mainthing.changeset(%Mainthing{content: (mainthing && mainthing.content) || ""}, %{})

    {:ok,
     socket
     |> assign(:analytics, analytics)
     |> assign(:funnel_data, funnel_data)
     |> assign(:selected_period, "30d")
     |> assign(:notes_form, to_form(notes_changeset))
     |> assign(:notes_preview, (mainthing && Markdown.render_unsafe(mainthing.content)) || "")
     |> assign(:mainthing, mainthing)
     |> assign(:notes_edit_mode, false)
     |> assign(:notes_full_screen, false)
     |> assign(:plausible_url, Application.get_env(:algora, :plausible_url))
     |> stream(:activities, [])
     |> start_async(:get_activities, fn -> Activities.all() end)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-8 p-8">
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
              <div class="prose prose-sm max-w-none dark:prose-invert">
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
          :if={@plausible_url}
          src={@plausible_url}
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
        {:noreply, socket |> assign(:notes_form, to_form(changeset)) |> put_flash(:error, "Error saving notes")}
    end
  end

  def handle_event("notes-toggle", _, socket) do
    {:noreply, assign(socket, :notes_edit_mode, !socket.assigns.notes_edit_mode)}
  end

  def handle_event("notes-fullscreen-toggle", _, socket) do
    {:noreply, assign(socket, :notes_full_screen, !socket.assigns.notes_full_screen)}
  end

  def handle_info(%Activities.Activity{} = activity, socket) do
    {:noreply, stream_insert(socket, :activities, activity, at: 0)}
  end

  def handle_async(:get_activities, {:ok, fetched}, socket) do
    {:noreply, stream(socket, :activities, fetched)}
  end
end
