defmodule AlgoraWeb.Org.SettingsLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Github
  alias AlgoraWeb.Components.Logos

  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-6 p-6">
      <div class="space-y-1">
        <h1 class="text-2xl font-bold">Settings</h1>
        <p class="text-muted-foreground">Update your settings and preferences</p>
      </div>

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
              <.button phx-click="install_app" class="ml-auto gap-2">
                <Logos.github class="w-4 h-4 mr-2 -ml-1" />
                Manage {ngettext("installation", "installations", length(@installations))}
              </.button>
            <% else %>
              <div class="flex flex-col gap-2">
                <.button phx-click="install_app" class="ml-auto gap-2">
                  <Logos.github class="w-4 h-4 mr-2 -ml-1" /> Install GitHub App
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
    # TODO: skip auth step in installation flow
    {:noreply, socket |> assign(:current_user, user) |> redirect(external: Github.install_url())}
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
