defmodule AlgoraWeb.Admin.CampaignLive do
  @moduledoc false

  use AlgoraWeb, :live_view

  import Ecto.Changeset

  alias Algora.Mailer
  alias AlgoraWeb.LocalStore
  alias Swoosh.Email

  # Add embedded schema
  defmodule Campaign do
    @moduledoc false
    use Ecto.Schema

    embedded_schema do
      field :subject, :string
      field :template, :string
      field :csv, :string
    end

    def changeset(campaign, attrs \\ %{}) do
      campaign
      |> cast(attrs, [:subject, :template, :csv])
      |> validate_required([:subject, :template, :csv])
      |> validate_length(:subject, min: 1)
      |> validate_length(:template, min: 1)
      |> validate_length(:csv, min: 1)
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Campaign")
     |> assign(:form, to_form(Campaign.changeset(%Campaign{})))
     |> assign_preview()}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> LocalStore.init(key: __MODULE__, ok?: &match?(%{form: _}, &1), checkpoint_url: ~p"/admin/campaign")
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
    recipient = Enum.find(socket.assigns.csv_data, fn row -> row["email"] == email end)
    subject = get_change(socket.assigns.form.source, :subject)

    case deliver_email(
           %{
             name: recipient["name"],
             email: recipient["email"],
             repo_owner: recipient["repo_owner"],
             repo_name: recipient["repo_name"]
           },
           subject,
           markdown: socket.assigns.preview,
           img: "#{recipient["repo_owner"]}.png"
         ) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, "Email sent successfully")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to send email")}
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
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="space-y-6">
              <.input type="text" field={@form[:subject]} label="Subject" />

              <.input
                type="textarea"
                field={@form[:template]}
                label="Email Template"
                helptext="Use %{variable_name} for template variables"
                rows={20}
              />
            </div>

            <div class="space-y-2">
              <.label>Preview</.label>
              <div class="prose max-w-none">
                <dl class="text-foreground text-sm gap-2">
                  <div class="flex gap-1">
                    <dt class="font-bold">Subject:</dt>
                    <dd>{get_change(@form.source, :subject)}</dd>
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
              <.table id="csv-data" rows={@csv_data}>
                <:col :let={row} :for={key <- Map.keys(List.first(@csv_data) || %{})} label={key}>
                  {row[key]}
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

  defp parse_csv(csv) do
    csv
    |> String.split("\n")
    |> Enum.map(&String.split(&1, ","))
    |> Enum.reject(&Enum.empty?/1)
  end

  defp render_preview(template, data) when is_map(data) do
    Enum.reduce(data, template, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", value)
    end)
  end

  defp render_preview(_template, _data), do: nil

  defp assign_preview(socket) do
    case apply_action(socket.assigns.form.source, :save) do
      {:ok, data} ->
        csv_data =
          case data.csv |> String.trim() |> parse_csv() do
            [header | rows] ->
              keys = Enum.map(header, &String.trim/1)

              Enum.map(rows, fn row ->
                keys
                |> Enum.zip(Enum.map(row, &String.trim/1))
                |> Map.new()
              end)

            _ ->
              []
          end

        preview =
          if length(csv_data) > 0 do
            render_preview(data.template, List.first(csv_data))
          end

        socket |> assign(:preview, preview) |> assign(:csv_data, csv_data)

      {:error, _changeset} ->
        socket |> assign(:preview, nil) |> assign(:csv_data, [])
    end
  end

  @type recipient :: %{
          name: String.t(),
          email: String.t(),
          repo_owner: String.t(),
          repo_name: String.t()
        }

  @spec deliver_email(recipient(), subject :: String.t(), template_params :: Keyword.t()) :: :ok
  def deliver_email(recipient, subject, template_params) do
    case :get
         |> Finch.build("https://algora.io/og/go/#{recipient.repo_owner}/#{recipient.repo_name}")
         |> Finch.request(Algora.Finch) do
      {:ok, %Finch.Response{status: status, body: body}} when status in 200..299 ->
        deliver(recipient.email, subject, template_params, [
          Swoosh.Attachment.new({:data, body},
            filename: "#{recipient.repo_owner}.png",
            content_type: "image/png",
            type: :inline
          )
        ])

      {:error, reason} ->
        raise reason
    end
  end

  defp deliver(to, subject, template_params, attachments) do
    email =
      Email.new()
      |> Email.to(to)
      |> Email.from({"Ioannis R. Florokapis", "ioannis@algora.io"})
      |> Email.subject(subject)
      |> Email.text_body(Mailer.text_template(template_params))
      |> Email.html_body(Mailer.html_template(template_params))

    email = Enum.reduce(attachments, email, fn attachment, acc -> Email.attachment(acc, attachment) end)

    Mailer.deliver_with_logging(email)
  end
end
