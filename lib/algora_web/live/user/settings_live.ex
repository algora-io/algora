defmodule AlgoraWeb.User.SettingsLive do
  use AlgoraWeb, :live_view

  alias Algora.Users
  alias Algora.Users.User

  def render(assigns) do
    ~H"""
    <div class="container max-w-7xl mx-auto p-6 space-y-6">
      <div class="space-y-1">
        <h1 class="text-2xl font-bold">Settings</h1>
        <p class="text-muted-foreground">Update your settings and preferences</p>
      </div>

      <.card>
        <.card_header>
          <.card_title>Account</.card_title>
        </.card_header>
        <.card_content>
          <.simple_form for={@form} phx-change="validate" phx-submit="save">
            <div class="flex flex-col gap-6">
              <.input field={@form[:handle]} label="Handle" />
              <.input
                label="Email"
                name="email"
                value={@current_user.email}
                disabled
                class="cursor-not-allowed"
              />
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
    %{current_user: current_user} = socket.assigns

    changeset = User.settings_changeset(current_user, %{})

    {:ok,
     socket
     |> assign(current_user: current_user)
     |> assign_form(changeset)}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      socket.assigns.current_user
      |> User.settings_changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"user" => params}, socket) do
    case Users.update_settings(socket.assigns.current_user, params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(current_user: user)
         |> put_flash(:info, "Settings updated!")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, _params) do
    socket |> assign(:page_title, "Settings")
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
