defmodule AlgoraWeb.User.SettingsLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts
  alias Algora.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-6 p-6">
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
              <div class="flex flex-col gap-2">
                <.input field={@form[:handle]} label="Handle" />
                <p class="text-sm text-muted-foreground">
                  <.icon name="tabler-alert-triangle" class="size-4 mr-1" />
                  Changing your handle will break existing URLs and references to your profile and other pages. This includes links shared on social media, documentation, and other websites.
                </p>
              </div>
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
              <div class="flex flex-col gap-2">
                <.input
                  label="Search timezone"
                  name="timezone_search"
                  type="text"
                  value={@timezone_search}
                  phx-change="search_timezone"
                  phx-debounce="200"
                  placeholder="Search by city, region, or UTC offset..."
                />
                <.input
                  field={@form[:timezone]}
                  label="Timezone"
                  type="select"
                  options={@filtered_timezones}
                />
              </div>
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

    all_timezones = Algora.Time.list_friendly_timezones()
    current_timezone = current_user.timezone || "UTC"

    {:ok,
     socket
     |> assign(current_user: current_user)
     |> assign_form(changeset)
     |> assign(timezone_search: "")
     |> assign(filtered_timezones: all_timezones)
     |> assign(current_timezone: current_timezone)
     |> assign(all_timezones: all_timezones)}
  end

  def handle_event("search_timezone", %{"_target" => "timezone_search", "timezone_search" => query}, socket) do
    filtered =
      cond do
        query == "" -> socket.assigns.all_timezones
        String.downcase(query) == "utc" ->
          socket.assigns.all_timezones |> Enum.filter(fn {friendly, _} -> String.contains?(String.downcase(friendly), "utc") end)
        true ->
          socket.assigns.all_timezones
          |> Enum.filter(fn {friendly, _} ->
            String.contains?(String.downcase(friendly), String.downcase(query)) ||
            String.contains?(String.downcase(friendly), String.replace(String.downcase(query), " ", "_"))
          end)
      end

    {:noreply,
     socket
     |> assign(timezone_search: query)
     |> assign(filtered_timezones: filtered)}
  end

  def handle_event("search_timezone", _, socket), do: {:noreply, socket}

  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      socket.assigns.current_user
      |> User.settings_changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"user" => params}, socket) do
    case Accounts.update_settings(socket.assigns.current_user, params) do
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
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, _params) do
    assign(socket, :page_title, "Settings")
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
