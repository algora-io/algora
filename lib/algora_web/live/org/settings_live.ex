defmodule AlgoraWeb.Org.SettingsLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Github
  alias Algora.Payments
  alias AlgoraWeb.Components.Logos

  require Logger

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
            <.button phx-click="setup_payment" class="ml-auto">
              <.icon name="tabler-brand-stripe" class="w-5 h-5 mr-2 -ml-1" /> Save card with Stripe
            </.button>
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
                  <img src={installation.avatar_url} class="w-9 h-9 rounded-lg" />
                  <div>
                    <p class="font-medium">{installation.provider_meta["account"]["login"]}</p>
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
                  Changing your handle can have unintended side effects.
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
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Algora.PubSub, "auth:#{socket.id}")
    end

    %{current_org: current_org} = socket.assigns

    changeset = User.settings_changeset(current_org, %{})
    installations = Algora.Workspace.list_installations_by(connected_user_id: current_org.id, provider: "github")

    {:ok,
     socket
     |> assign(:installations, installations)
     |> assign(:oauth_url, Github.authorize_url(%{socket_id: socket.id}))
     |> assign_form(changeset)}
  end

  def handle_info({:authenticated, user}, socket) do
    {:noreply, socket |> assign(:current_user, user) |> redirect(external: Github.install_url_select_target())}
  end

  def handle_event("install_app", _params, socket) do
    # TODO: immediately redirect to install_url if user has valid token
    {:noreply, push_event(socket, "open_popup", %{url: socket.assigns.oauth_url})}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      socket.assigns.current_org
      |> User.settings_changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

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

  def handle_event("setup_payment", _params, socket) do
    %{current_org: org, current_user: user} = socket.assigns
    success_url = ~p"/org/#{org.handle}/settings"
    cancel_url = ~p"/org/#{org.handle}/settings"

    with {:ok, customer} <- Payments.fetch_or_create_customer(org, user),
         {:ok, session} <- Payments.create_stripe_setup_session(customer, success_url, cancel_url) do
      {:noreply, redirect(socket, external: session.url)}
    else
      {:error, reason} ->
        Logger.error("Failed to create setup session: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Something went wrong")}
    end
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, _params) do
    assign(socket, :page_title, "Settings")
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
