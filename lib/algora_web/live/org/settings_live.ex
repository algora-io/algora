defmodule AlgoraWeb.Org.SettingsLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.BotTemplates
  alias Algora.BotTemplates.BotTemplate
  alias Algora.Github
  alias Algora.Markdown
  alias Algora.Payments
  alias AlgoraWeb.Components.Logos

  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-6 p-6">
      <div class="space-y-1">
        <h1 class="text-2xl font-bold">Settings</h1>
        <p class="text-muted-foreground">Update your settings and preferences</p>
      </div>

      <.card>
        <.card_header>
          <.card_title>
            <div class="flex items-center gap-2">
              Auto-pay on merge
            </div>
          </.card_title>
          <.card_description>
            Once enabled, we will charge your saved payment method automatically when
          </.card_description>
          <ul class="mt-1 pl-4 list-disc text-sm text-muted-foreground">
            <li>a pull request that claims a bounty is merged</li>
            <li>
              <.badge><code>/tip</code></.badge>
              command is used by you or any other
              <.link navigate={~p"/org/#{@current_org.handle}/team"} class="font-semibold">
                {@current_org.name} admins
              </.link>
            </li>
          </ul>
        </.card_header>
        <.card_content>
          <div class="flex">
            <%= if @has_default_payment_method do %>
              <.badge class="ml-auto text-sm px-3 py-2" variant="success">
                <.icon name="tabler-check" class="w-5 h-5 mr-1 -ml-1" /> Enabled
              </.badge>
            <% else %>
              <.button phx-click="setup_payment" class="ml-auto">
                <.icon name="tabler-brand-stripe" class="w-5 h-5 mr-2 -ml-1" /> Save card with Stripe
              </.button>
            <% end %>
          </div>
        </.card_content>
      </.card>

      <.card>
        <.card_header>
          <.card_title>GitHub Integration</.card_title>
          <.card_description :if={@installations == []}>
            Install the Algora app to enable slash commands in your GitHub repositories
          </.card_description>
        </.card_header>
        <.card_content>
          <div class="flex flex-col gap-3">
            <%= if @installations != [] do %>
              <%= for installation <- @installations do %>
                <div class="flex items-center gap-2">
                  <img src={installation.provider_user.avatar_url} class="w-9 h-9 rounded-lg" />
                  <div>
                    <p class="font-medium">{installation.provider_user.provider_login}</p>
                    <p class="text-sm text-muted-foreground">
                      Algora app is installed in <strong>{installation.repository_selection}</strong>
                      repositories
                    </p>
                  </div>
                </div>
              <% end %>
              <.button phx-click="install_app" class="ml-auto">
                <Logos.github class="w-5 h-5 mr-2 -ml-1" />
                Manage {ngettext("installation", "installations", length(@installations))}
              </.button>
            <% else %>
              <div class="flex flex-col">
                <.button phx-click="install_app" class="ml-auto">
                  <Logos.github class="w-5 h-5 mr-2 -ml-1" /> Install GitHub App
                </.button>
              </div>
            <% end %>
          </div>
        </.card_content>
      </.card>

      <.card>
        <.card_header>
          <.card_title>Account</.card_title>
        </.card_header>
        <.card_content>
          <.simple_form for={@form} phx-change="validate" phx-submit="save">
            <div class="flex flex-col gap-6">
              <div class="flex flex-col gap-2">
                <.input field={@form[:handle]} label="Handle" />
                <p class="text-sm text-muted-foreground flex items-center gap-1.5">
                  <.icon name="tabler-alert-triangle" class="w-4 h-4" />
                  Changing your handle will break existing URLs and references to your organization pages. This includes links shared on social media, documentation, and other websites.
                </p>
              </div>
              <.button class="ml-auto">Save</.button>
            </div>
          </.simple_form>
        </.card_content>
      </.card>

      <.card>
        <.card_header>
          <.card_title>Public Profile</.card_title>
        </.card_header>
        <.card_content>
          <.simple_form for={@form} phx-change="validate" phx-submit="save">
            <div class="flex flex-col gap-6">
              <.input field={@form[:display_name]} label="Name" />
              <.input field={@form[:bio]} type="textarea" label="Bio" />
              <.input field={@form[:website_url]} label="Website" />
              <.input field={@form[:location]} label="Location" />
              <.input
                field={@form[:timezone]}
                label="Timezone"
                type="select"
                options={Algora.Time.list_friendly_timezones()}
              />
              <.button class="ml-auto">Save</.button>
            </div>
          </.simple_form>
        </.card_content>
      </.card>

      <.card>
        <.card_header>
          <.card_title>Bot Templates</.card_title>
          <.card_description>
            Customize the messages that Algora bot sends on your repositories
          </.card_description>
        </.card_header>
        <.card_content>
          <.simple_form for={@template_form} phx-change="validate_template" phx-submit="save_template">
            <div class="grid grid-cols-2 gap-4">
              <div class="flex flex-col gap-2">
                <h3 class="font-medium text-sm">Template</h3>
                <div class="flex-1 [&>div]:h-full">
                  <.input
                    field={@template_form[:template]}
                    type="textarea"
                    class="h-full"
                    phx-debounce="300"
                  />
                </div>
              </div>
              <div class="flex flex-col gap-2">
                <h3 class="font-medium text-sm">Preview</h3>
                <div class="flex-1 rounded-lg border bg-muted/40 p-4">
                  <div class="prose prose-sm max-w-none dark:prose-invert">
                    {raw(@template_preview)}
                  </div>
                </div>
              </div>
            </div>
            <div class="flex items-center justify-between gap-4">
              <div class="flex flex-col gap-2">
                <h3 class="font-medium text-xs">Available variables</h3>
                <div class="flex flex-wrap gap-2">
                  <%= for variable <- @available_variables do %>
                    <.badge variant="outline" class="font-mono">
                      {"#{"${#{variable}}"}"}
                    </.badge>
                  <% end %>
                </div>
              </div>
              <.button class="ml-auto">Save template</.button>
            </div>
          </.simple_form>
        </.card_content>
      </.card>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Algora.PubSub, "auth:#{socket.id}")
      Payments.subscribe()
    end

    %{current_org: current_org} = socket.assigns

    changeset = User.settings_changeset(current_org, %{})
    installations = Algora.Workspace.list_installations_by(connected_user_id: current_org.id, provider: "github")

    template =
      case BotTemplates.get_template(current_org.id, :bounty_created) do
        nil -> BotTemplates.get_default_template(:bounty_created)
        bot_template -> bot_template.template
      end

    template_changeset = BotTemplate.changeset(%BotTemplate{}, %{template: template, type: :bounty_created})
    available_variables = BotTemplates.available_variables(:bounty_created)

    {:ok,
     socket
     |> assign(:has_fresh_token?, Accounts.has_fresh_token?(socket.assigns.current_user))
     |> assign(:installations, installations)
     |> assign(:oauth_url, Github.authorize_url(%{socket_id: socket.id}))
     |> assign_has_default_payment_method()
     |> assign(:template_form, to_form(template_changeset))
     |> assign(:template_preview, preview_template(socket, template))
     |> assign(:available_variables, available_variables)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_info({:authenticated, user}, socket) do
    socket =
      socket
      |> assign(:current_user, user)
      |> assign(:has_fresh_token?, true)

    case socket.assigns.pending_action do
      {event, params} ->
        socket = assign(socket, :pending_action, nil)
        handle_event(event, params, socket)

      nil ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:payments_updated, socket) do
    {:noreply, assign_has_default_payment_method(socket)}
  end

  @impl true
  def handle_event("install_app" = event, unsigned_params, socket) do
    {:noreply,
     if socket.assigns.has_fresh_token? do
       redirect(socket, external: Github.install_url_select_target())
     else
       socket
       |> assign(:pending_action, {event, unsigned_params})
       |> push_event("open_popup", %{url: socket.assigns.oauth_url})
     end}
  end

  @impl true
  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      socket.assigns.current_org
      |> User.settings_changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"user" => params}, socket) do
    case Accounts.update_settings(socket.assigns.current_org, params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(current_org: user)
         |> put_flash(:info, "Settings updated!")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("setup_payment", _params, socket) do
    %{current_org: org} = socket.assigns
    success_url = url(~p"/org/#{org.handle}/settings")
    cancel_url = url(~p"/org/#{org.handle}/settings")

    with {:ok, customer} <- Payments.fetch_or_create_customer(org),
         {:ok, session} <- Payments.create_stripe_setup_session(customer, success_url, cancel_url) do
      {:noreply, redirect(socket, external: session.url)}
    else
      {:error, reason} ->
        Logger.error("Failed to create setup session: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Something went wrong")}
    end
  end

  @impl true
  def handle_event("validate_template", %{"bot_template" => params}, socket) do
    template = params["template"]

    changeset =
      %BotTemplate{}
      |> BotTemplate.changeset(%{template: template, type: :bounty_created})
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:template_form, to_form(changeset))
     |> assign(:template_preview, preview_template(socket, template))}
  end

  @impl true
  def handle_event("save_template", %{"bot_template" => params}, socket) do
    case BotTemplates.save_template(
           socket.assigns.current_org.id,
           :bounty_created,
           params["template"]
         ) do
      {:ok, _template} ->
        {:noreply, put_flash(socket, :info, "Template updated!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update template")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, _params) do
    assign(socket, :page_title, "Settings")
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_has_default_payment_method(socket) do
    assign(socket, :has_default_payment_method, Payments.has_default_payment_method?(socket.assigns.current_org.id))
  end

  defp preview_template(socket, template) when is_binary(template) do
    placeholders = BotTemplates.placeholders(:bounty_created, socket.assigns.current_org)

    preview =
      Enum.reduce(placeholders, template, fn {key, value}, acc ->
        String.replace(acc, "${#{key}}", value)
      end)

    Markdown.render(preview)
  end

  defp preview_template(_socket, _template), do: ""
end
