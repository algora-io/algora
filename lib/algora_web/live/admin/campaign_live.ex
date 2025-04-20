defmodule AlgoraWeb.Admin.CampaignLive do
  @moduledoc false

  use AlgoraWeb, :live_view

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Activities.Jobs.SendCampaignEmail
  alias Algora.Admin
  alias Algora.Mailer
  alias Algora.Repo
  alias Algora.Workspace.Repository
  alias AlgoraWeb.LocalStore
  alias Swoosh.Email

  defmodule Campaign do
    @moduledoc false
    use Ecto.Schema

    embedded_schema do
      field :subject, :string
      field :template, :string
      field :csv, :string
      field :from_name, :string
      field :from_email, :string
      field :preheader, :string
    end

    def changeset(campaign, attrs \\ %{}) do
      campaign
      |> cast(attrs, [:subject, :template, :csv, :from_name, :from_email, :preheader])
      |> validate_required([:subject, :template, :csv, :from_name, :from_email])
      |> validate_length(:subject, min: 1)
      |> validate_length(:template, min: 1)
      |> validate_length(:csv, min: 1)
      |> validate_length(:from_name, min: 1)
      |> validate_format(:from_email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email address")
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Campaign")
     |> assign(:form, to_form(Campaign.changeset(%Campaign{})))
     |> assign(:repo_cache, %{})
     |> assign_preview()}
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
    {:noreply,
     socket
     |> LocalStore.restore(params)
     |> assign_preview()}
  end

  @impl true
  def handle_event("preview", %{"campaign" => params}, socket) do
    {:noreply,
     socket
     |> LocalStore.assign_cached(:form, to_form(Campaign.changeset(%Campaign{}, params)))
     |> assign_preview()}
  end

  @impl true
  def handle_event("send_email", %{"email" => email}, socket) do
    socket.assigns.csv_data |> Enum.filter(fn row -> row["email"] == email end) |> handle_send(socket)
  end

  @impl true
  def handle_event("send_all", _params, socket) do
    handle_send(socket.assigns.csv_data, socket)
  end

  defp handle_send(recipients, socket) do
    subject = get_change(socket.assigns.form.source, :subject)
    template = get_change(socket.assigns.form.source, :template)
    from_name = get_change(socket.assigns.form.source, :from_name)
    from_email = get_change(socket.assigns.form.source, :from_email)
    preheader = get_change(socket.assigns.form.source, :preheader)

    case enqueue_emails(recipients, subject, template, from_name, from_email, preheader) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, "Enqueued #{length(recipients)} emails for sending")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to enqueue emails")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="bg-background"
      phx-hook="LocalStateStore"
      id="campaign-page"
      data-storage="localStorage"
    >
      <div class="max-w-7xl mx-auto py-8 space-y-8">
        <.header>
          Campaign Manager
          <:subtitle>Send personalized emails to multiple recipients</:subtitle>
        </.header>

        <.form for={@form} phx-change="preview" class="space-y-4">
          <div class="space-y-6">
            <div class="grid grid-cols-2 gap-4">
              <.input type="text" field={@form[:from_name]} label="From Name" />
              <.input type="email" field={@form[:from_email]} label="From Email" />
            </div>
            <div class="grid grid-cols-2 gap-4">
              <.input type="text" field={@form[:subject]} label="Subject" />
              <.input type="text" field={@form[:preheader]} label="Preheader" />
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <.input
              type="textarea"
              field={@form[:template]}
              label="Email Template"
              helptext="Use %{variable_name} for template variables"
              rows={20}
            />
            <div class="space-y-2">
              <.label>Preview</.label>
              <div class="prose max-w-none">
                <dl class="text-foreground text-sm gap-2">
                  <div class="flex gap-1">
                    <dt class="font-bold">Subject:</dt>
                    <dd>{get_change(@form.source, :subject)}</dd>
                  </div>
                  <div class="flex gap-1">
                    <dt class="font-bold">Preheader:</dt>
                    <dd class="line-clamp-1">
                      {render_preview(get_change(@form.source, :preheader), List.first(@csv_data))}
                    </dd>
                  </div>
                  <div class="flex gap-1">
                    <dt class="font-bold">From:</dt>
                    <dd>
                      {get_change(@form.source, :from_name)} &lt;{get_change(
                        @form.source,
                        :from_email
                      )}&gt;
                    </dd>
                  </div>
                </dl>
                <div class="-mt-4">
                  <%= if @preview do %>
                    {raw(Mailer.html_template(markdown: @preview))}
                  <% end %>
                </div>
              </div>
            </div>
          </div>

          <.input
            type="textarea"
            field={@form[:csv]}
            label="CSV Data"
            helptext="Enter your CSV data with headers matching the template variables"
          />

          <div>
            <div class="-mx-4 overflow-x-auto">
              <div class="flex justify-end mb-4">
                <.button type="button" phx-click="send_all">
                  Send to {length(@csv_data)} Recipients
                </.button>
              </div>
              <.table id="csv-data" rows={@csv_data}>
                <:col :let={row} :for={key <- @csv_columns} label={key}>
                  <.cell value={row[key]} />
                </:col>
                <:action :let={row}>
                  <.button type="button" phx-click="send_email" phx-value-email={row["email"]}>
                    Send
                  </.button>
                </:action>
              </.table>
            </div>
          </div>
        </.form>
      </div>
    </div>
    """
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

  defp cell(assigns) do
    ~H"""
    <span class="text-sm">
      {@value}
    </span>
    """
  end

  defp render_preview(template, data) when is_map(data) do
    Enum.reduce(data, template, fn {key, value}, acc ->
      case value do
        value when is_list(value) -> acc
        _ -> String.replace(acc, "%{#{key}}", value)
      end
    end)
  end

  defp render_preview(_template, _data), do: nil

  defp assign_repo_names(socket) do
    new_handles =
      socket.assigns.csv_data
      |> Enum.map(& &1["org_handle"])
      |> Enum.reject(&is_nil/1)
      |> Enum.reject(&Map.has_key?(socket.assigns.repo_cache, &1))
      |> Enum.uniq()

    new_cache =
      Map.new(new_handles, fn org_handle ->
        repo =
          Repo.one(
            from r in Repository,
              join: u in assoc(r, :user),
              where: u.handle == ^org_handle,
              order_by: [desc: fragment("(?->>'stargazers_count')::integer", r.provider_meta)],
              select: %{
                repo_owner: u.provider_login,
                repo_name: r.name,
                tech_stack: r.tech_stack
              },
              limit: 1
          )

        {org_handle, repo}
      end)

    updated_cache = Map.merge(socket.assigns.repo_cache, new_cache)

    csv_data =
      Enum.map(socket.assigns.csv_data, fn row ->
        case row["org_handle"] do
          nil ->
            row

          org_handle ->
            case Map.get(updated_cache, org_handle) do
              nil ->
                row

              repo ->
                Map.merge(row, %{
                  "repo_owner" => repo.repo_owner,
                  "repo_name" => repo.repo_name,
                  "tech_stack" => repo.tech_stack
                })
            end
        end
      end)

    csv_columns =
      csv_data
      |> Enum.flat_map(&Map.keys/1)
      |> Enum.uniq()

    socket
    |> assign(:repo_cache, updated_cache)
    |> assign(:csv_data, csv_data)
    |> assign(:csv_columns, csv_columns)
  end

  defp assign_csv_data(socket, data) do
    csv_data =
      case String.trim(data) do
        "" ->
          []

        csv_string ->
          [csv_string]
          |> CSV.decode!(headers: true)
          |> Enum.to_list()
      end

    socket
    |> assign(:csv_data, csv_data)
    |> assign_repo_names()
  end

  defp assign_preview(socket) do
    {socket, template} =
      case apply_action(socket.assigns.form.source, :save) do
        {:ok, data} ->
          {assign_csv_data(socket, data.csv), data.template}

        {:error, _changeset} ->
          {assign_csv_data(socket, ""), nil}
      end

    assign(socket, :preview, render_preview(template, List.first(socket.assigns.csv_data)))
  end

  @spec enqueue_emails(
          recipients :: list(),
          subject :: String.t(),
          template :: String.t(),
          from_name :: String.t(),
          from_email :: String.t(),
          preheader :: String.t()
        ) ::
          {:ok, term} | {:error, term}
  def enqueue_emails(recipients, subject, template, from_name, from_email, preheader) do
    Repo.transact(fn _ ->
      recipients
      |> Enum.map(fn recipient ->
        %{
          id: "2025-04-oss",
          subject: subject,
          recipient_email: recipient["email"],
          recipient: Algora.Util.term_to_base64(recipient),
          template: template,
          from_name: from_name,
          from_email: from_email,
          preheader: render_preview(preheader, recipient)
        }
      end)
      |> Enum.with_index()
      |> Enum.reduce_while(:ok, fn {args, index}, acc ->
        case args |> SendCampaignEmail.new(schedule_in: 5 * index) |> Oban.insert() do
          {:ok, _} -> {:cont, acc}
          {:error, _} -> {:halt, :error}
        end
      end)
    end)
  end

  def deliver_email(opts) do
    case opts[:template] |> render_preview(opts[:recipient]) |> extract_attachments() do
      {:ok, {preview, attachments}} ->
        Email.new()
        |> Email.to(opts[:recipient]["email"])
        |> Email.from(opts[:from])
        |> Email.subject(opts[:subject])
        |> Email.text_body(Mailer.text_template(markdown: preview))
        |> Email.html_body(Mailer.html_template([markdown: preview], preheader: opts[:preheader]))
        |> then(&Enum.reduce(attachments, &1, fn attachment, acc -> Email.attachment(acc, attachment) end))
        |> Mailer.deliver_with_logging()

      {:error, reason} ->
        Admin.alert("Failed to deliver email: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp extract_attachments(preview) do
    image_regex = ~r/!\[(.*?)\]\((.*?)\)/

    image_regex
    |> Regex.scan(preview)
    |> Enum.reduce_while({:ok, {preview, []}}, fn [full_match, alt, src], {:ok, {current_preview, current_attachments}} ->
      case :get |> Finch.build(src) |> Finch.request(Algora.Finch) do
        {:ok, %Finch.Response{status: status, body: body}} when status in 200..299 ->
          attachment =
            Swoosh.Attachment.new({:data, body}, filename: "#{alt}.png", content_type: "image/png", type: :inline)

          new_preview = String.replace(current_preview, full_match, "![#{alt}](cid:#{alt}.png)")
          {:cont, {:ok, {new_preview, [attachment | current_attachments]}}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, {preview, attachments}} -> {:ok, {preview, Enum.reverse(attachments)}}
      {:error, reason} -> {:error, reason}
    end
  end
end
