defmodule AlgoraWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  The components in this module use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn how to
  customize the generated components in this module.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use AlgoraWeb.Component
  use AlgoraWeb, :verified_routes

  alias Phoenix.LiveView.JS
  import AlgoraWeb.Gettext

  slot :inner_block

  def connection_status(assigns) do
    ~H"""
    <div
      id="connection-status"
      class="hidden rounded-md bg-red-900 p-4 fixed top-1 right-1 w-96 fade-in-scale z-50"
      js-show={show("#connection-status")}
      js-hide={hide("#connection-status")}
    >
      <div class="flex">
        <div class="flex-shrink-0">
          <svg
            class="animate-spin -ml-1 mr-3 h-5 w-5 text-red-100"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            aria-hidden="true"
          >
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
            </circle>
            <path
              class="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            >
            </path>
          </svg>
        </div>
        <div class="ml-3">
          <p class="text-sm font-medium text-red-100" role="alert">
            <%= render_slot(@inner_block) %>
          </p>
        </div>
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil

  def logo(assigns) do
    ~H"""
    <.link
      navigate="/"
      aria-label="Algora TV"
      class="focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500"
    >
      <AlgoraWeb.Components.Logos.algora class={["fill-current", @class || "w-20 h-auto"]} />
    </.link>
    """
  end

  attr :class, :string, default: nil

  def wordmark(assigns) do
    ~H"""
    <.link
      navigate="/"
      aria-label="Algora TV"
      class="focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500"
    >
      <AlgoraWeb.Components.Wordmarks.algora class={["fill-current", @class || "w-20 h-auto"]} />
    </.link>
    """
  end

  @doc """
  Returns a button triggered dropdown with aria keyboard and focus supporrt.

  Accepts the follow slots:

    * `:id` - The id to uniquely identify this dropdown
    * `:img` - The optional img to show beside the button title
    * `:title` - The button title
    * `:subtitle` - The button subtitle

  ## Examples

      <.dropdown id={@id}>
        <:img src={@current_user.avatar_url} alt={@current_user.handle}/>
        <:title><%= @current_user.name %></:title>
        <:subtitle>@<%= @current_user.handle %></:subtitle>

        <:link navigate={~p"/"}>Dashboard</:link>
        <:link navigate={~p"/user/settings"}Settings</:link>
      </.dropdown>
  """
  attr :id, :string, required: true

  slot :img do
    attr :src, :string
    attr :alt, :string
  end

  slot :title
  slot :subtitle

  slot :link do
    attr :navigate, :string
    attr :href, :string
    attr :method, :any
  end

  def dropdown(assigns) do
    ~H"""
    <!-- User account dropdown -->
    <div class="w-full relative inline-block text-left">
      <div>
        <button
          id={@id}
          type="button"
          class="group w-full rounded-md px-3.5 py-2 text-sm text-left font-medium text-foreground hover:bg-accent focus:outline-none focus:ring-2 focus:ring-ring"
          phx-click={show_dropdown("##{@id}-dropdown")}
          phx-hook="Menu"
          data-active-class="bg-accent"
          aria-haspopup="true"
        >
          <span class="flex w-full justify-between items-center">
            <span class="flex min-w-0 items-center justify-between space-x-3">
              <%= for img <- @img do %>
                <img
                  class="w-10 h-10 bg-gray-600 rounded-full flex-shrink-0"
                  {assigns_to_attributes(img)}
                />
              <% end %>
              <span class="flex-1 flex flex-col min-w-0">
                <span class="text-gray-50 text-sm font-medium truncate">
                  <%= render_slot(@title) %>
                </span>
                <span class="text-gray-400 text-sm truncate"><%= render_slot(@subtitle) %></span>
              </span>
            </span>
            <.icon
              name="tabler-selector"
              class="ml-2 flex-shrink-0 h-5 w-5 text-gray-500 group-hover:text-gray-400"
            />
          </span>
        </button>
      </div>
      <div
        id={"#{@id}-dropdown"}
        phx-click-away={hide_dropdown("##{@id}-dropdown")}
        class="hidden z-10 origin-top absolute right-0 left-0 mt-1 rounded-md shadow-lg bg-popover ring-1 ring-border divide-y divide-border"
        role="menu"
        aria-labelledby={@id}
      >
        <div class="py-1" role="none">
          <%= for link <- @link do %>
            <.link
              tabindex="-1"
              role="menuitem"
              class="block px-4 py-2 text-sm text-foreground hover:bg-accent focus:outline-none focus:ring-2 focus:ring-ring"
              {link}
            >
              <%= render_slot(link) %>
            </.link>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Returns a button triggered dropdown with aria keyboard and focus supporrt.

  Accepts the follow slots:

    * `:id` - The id to uniquely identify this dropdown
    * `:img` - The optional img to show beside the button title
    * `:title` - The button title
    * `:subtitle` - The button subtitle

  ## Examples

      <.dropdown id={@id}>
        <:img src={@current_user.avatar_url} alt={@current_user.handle}/>
        <:title><%= @current_user.name %></:title>
        <:subtitle>@<%= @current_user.handle %></:subtitle>

        <:link navigate={~p"/"}>Dashboard</:link>
        <:link navigate={~p"/user/settings"}Settings</:link>
      </.dropdown>
  """
  attr :id, :string, required: true
  attr :class, :string, default: nil

  slot :img do
    attr :src, :string
    attr :alt, :string
  end

  slot :title
  slot :subtitle

  slot :link do
    attr :navigate, :string
    attr :href, :string
    attr :method, :any
  end

  def dropdown2(assigns) do
    ~H"""
    <!-- User account dropdown -->
    <div class={classes(["w-full relative text-left", @class])}>
      <div>
        <button
          id={@id}
          type="button"
          class="group w-full rounded-md px-3.5 py-2 text-sm text-left font-medium text-foreground hover:bg-accent focus:outline-none focus:ring-2 focus:ring-ring"
          phx-click={show_dropdown("##{@id}-dropdown")}
          phx-hook="Menu"
          data-active-class="bg-accent"
          aria-haspopup="true"
        >
          <span class="flex w-full justify-between items-center">
            <span class="flex min-w-0 items-center justify-between space-x-3">
              <%= for img <- @img do %>
                <img
                  class="w-10 h-10 bg-gray-600 rounded-full flex-shrink-0"
                  {assigns_to_attributes(img)}
                />
              <% end %>
              <span class="flex-1 flex flex-col min-w-0">
                <span class="text-gray-50 text-sm font-medium truncate">
                  <%= render_slot(@title) %>
                </span>
                <span class="text-gray-400 text-sm truncate"><%= render_slot(@subtitle) %></span>
              </span>
            </span>
            <.icon
              name="tabler-selector"
              class="ml-2 flex-shrink-0 h-5 w-5 text-gray-500 group-hover:text-gray-400"
            />
          </span>
        </button>
      </div>
      <div
        id={"#{@id}-dropdown"}
        phx-click-away={hide_dropdown("##{@id}-dropdown")}
        class="hidden z-10 origin-top absolute right-0 left-0 mt-1 rounded-md shadow-lg bg-popover ring-1 ring-border divide-y divide-border"
        role="menu"
        aria-labelledby={@id}
      >
        <div class="py-1" role="none">
          <%= for link <- @link do %>
            <.link
              tabindex="-1"
              role="menuitem"
              class="block px-4 py-2 text-sm text-foreground hover:bg-accent focus:outline-none focus:ring-2 focus:ring-ring"
              {link}
            >
              <%= render_slot(link) %>
            </.link>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def context_selector(assigns) do
    ~H"""
    <.dropdown2 id="dashboard-dropdown">
      <:img src={@current_user.avatar_url} alt={@current_user.handle} />
      <:title><%= @current_user.name %></:title>

      <:link
        :for={org <- Algora.Organizations.get_user_orgs(@current_user)}
        href={~p"/set_context/#{org.handle}"}
      >
        <div class="flex items-center">
          <img src={org.avatar_url} alt={org.name} class="w-8 h-8 rounded-full mr-3" />
          <div class="truncate">
            <div class="truncate font-semibold"><%= org.name %></div>
            <div class="truncate text-sm text-gray-500">@<%= org.handle %></div>
          </div>
        </div>
      </:link>
    </.dropdown2>
    """
  end

  @doc """
  Returns a button triggered dropdown with aria keyboard and focus supporrt.

  Accepts the follow slots:

    * `:id` - The id to uniquely identify this dropdown
    * `:img` - The optional img to show beside the button title

  ## Examples

      <.dropdown id={@id}>
        <:img src={@current_user.avatar_url} alt={@current_user.handle}/>

        <:link navigate={~p"/"}>Dashboard</:link>
        <:link navigate={~p"/user/settings"}Settings</:link>
      </.dropdown>
  """
  attr :id, :string, required: true

  slot :img do
    attr :src, :string
    attr :alt, :string
  end

  slot :link do
    attr :navigate, :string
    attr :href, :string
    attr :method, :any
  end

  def simple_dropdown(assigns) do
    ~H"""
    <!-- User account dropdown -->
    <div class="relative inline-block text-left">
      <div>
        <button
          id={@id}
          type="button"
          class="group w-full bg-gray-800 rounded-full text-sm text-left font-medium text-gray-200 hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-800 focus:ring-indigo-400"
          phx-click={show_dropdown("##{@id}-dropdown")}
          phx-hook="Menu"
          data-active-class="bg-gray-800"
          aria-haspopup="true"
        >
          <%= for img <- @img do %>
            <img class="w-8 h-8 bg-gray-600 rounded-full flex-shrink-0" {assigns_to_attributes(img)} />
          <% end %>
        </button>
      </div>
      <div
        id={"#{@id}-dropdown"}
        phx-click-away={hide_dropdown("##{@id}-dropdown")}
        class="hidden z-10 origin-right absolute right-0 mt-1 rounded-md shadow-lg bg-gray-800 ring-1 ring-gray-800 ring-opacity-5 divide-y divide-gray-600 min-w-[8rem]"
        role="menu"
        aria-labelledby={@id}
      >
        <div class="py-1" role="none">
          <%= for link <- @link do %>
            <.link
              tabindex="-1"
              role="menuitem"
              class="block px-4 py-2 text-sm text-gray-200 hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-700 focus:ring-indigo-400"
              {link}
            >
              <%= render_slot(link) %>
            </.link>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def show_mobile_sidebar(js \\ %JS{}) do
    js
    |> JS.show(to: "#mobile-sidebar-container", transition: "fade-in")
    |> JS.show(
      to: "#mobile-sidebar",
      display: "flex",
      time: 300,
      transition:
        {"transition ease-in-out duration-300 transform", "-translate-x-full", "translate-x-0"}
    )
    |> JS.hide(to: "#show-mobile-sidebar", transition: "fade-out")
    |> JS.dispatch("js:exec", to: "#hide-mobile-sidebar", detail: %{call: "focus", args: []})
  end

  def hide_mobile_sidebar(js \\ %JS{}) do
    js
    |> JS.hide(to: "#mobile-sidebar-container", transition: "fade-out")
    |> JS.hide(
      to: "#mobile-sidebar",
      time: 300,
      transition:
        {"transition ease-in-out duration-300 transform", "translate-x-0", "-translate-x-full"}
    )
    |> JS.show(to: "#show-mobile-sidebar", transition: "fade-in")
    |> JS.dispatch("js:exec", to: "#show-mobile-sidebar", detail: %{call: "focus", args: []})
  end

  def show_dropdown(to) do
    JS.show(
      to: to,
      transition:
        {"transition ease-out duration-120", "transform opacity-0 scale-95",
         "transform opacity-100 scale-100"}
    )
    |> JS.set_attribute({"aria-expanded", "true"}, to: to)
  end

  def hide_dropdown(to) do
    JS.hide(
      to: to,
      transition:
        {"transition ease-in duration-120", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
    |> JS.remove_attribute("aria-expanded", to: to)
  end

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        Are you sure?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>

  JS commands may be passed to the `:on_cancel` and `on_confirm` attributes
  for the caller to react to each button press, for example:

      <.modal id="confirm" on_confirm={JS.push("delete")} on_cancel={JS.navigate(~p"/posts")}>
        Are you sure you?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}

  slot :inner_block, required: true
  slot :title
  slot :subtitle
  slot :confirm
  slot :cancel

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      class="relative z-[1001] hidden"
    >
      <div
        id={"#{@id}-bg"}
        class="fixed inset-0 bg-background/80 transition-opacity"
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-mounted={@show && show_modal(@id)}
              phx-window-keydown={hide_modal(@on_cancel, @id)}
              phx-key="escape"
              phx-click-away={hide_modal(@on_cancel, @id)}
              class="hidden relative rounded-2xl bg-background py-6 px-10 shadow-lg shadow-background/10 ring-1 ring-border transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={hide_modal(@on_cancel, @id)}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40 focus:outline-none focus:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="tabler-x" class="w-5 h-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <header :if={@title != []}>
                  <h1 id={"#{@id}-title"} class="text-lg font-semibold leading-8 text-foreground">
                    <%= render_slot(@title) %>
                  </h1>
                  <p
                    :if={@subtitle != []}
                    id={"#{@id}-description"}
                    class="mt-2 text-sm leading-6 text-muted-foreground"
                  >
                    <%= render_slot(@subtitle) %>
                  </p>
                </header>
                <%= render_slot(@inner_block) %>
                <div :if={@confirm != [] or @cancel != []} class="ml-6 mb-4 flex items-center gap-5">
                  <.button
                    :for={confirm <- @confirm}
                    id={"#{@id}-confirm"}
                    phx-click={@on_confirm}
                    phx-disable-with
                    class="py-2 px-3"
                  >
                    <%= render_slot(confirm) %>
                  </.button>
                  <.link
                    :for={cancel <- @cancel}
                    phx-click={hide_modal(@on_cancel, @id)}
                    class="text-sm font-semibold leading-6 text-foreground hover:text-foreground/80"
                  >
                    <%= render_slot(cancel) %>
                  </.link>
                </div>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: "flash", doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :kind, :atom, values: [:info, :note, :error], doc: "used for styling and flash lookup"
  attr :autoshow, :boolean, default: true, doc: "whether to auto show the flash on mount"
  attr :close, :boolean, default: true, doc: "whether the flash can be closed"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-mounted={@autoshow && show("##{@id}")}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed hidden top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 shadow-md ring-1",
        @kind == :info && "bg-success text-success-foreground ring-success fill-success-foreground",
        @kind == :note && "bg-info text-info-foreground ring-info fill-info-foreground",
        @kind == :error &&
          "bg-destructive text-destructive-foreground ring-destructive fill-destructive-foreground"
      ]}
      {@rest}
    >
      <%= case msg do %>
        <% %{body: body, action: %{ href: href, body: action_body }} -> %>
          <div class="flex gap-1.5 text-[0.8125rem] font-semibold leading-6">
            <.icon :if={@kind == :info} name="tabler-circle-check-filled" class="w-6 h-6" />
            <.icon :if={@kind == :note} name="tabler-info-circle-filled" class="w-6 h-6" />
            <.icon :if={@kind == :error} name="tabler-exclamation-circle-filled" class="w-6 h-6" />
            <div>
              <div><%= body %></div>
              <.link navigate={href} class="underline"><%= action_body %></.link>
            </div>
          </div>
        <% body -> %>
          <p class="flex items-center gap-1.5 text-[0.8125rem] font-semibold leading-6">
            <.icon :if={@kind == :info} name="tabler-circle-check-filled" class="w-6 h-6" />
            <.icon :if={@kind == :note} name="tabler-info-circle-filled" class="w-6 h-6" />
            <.icon :if={@kind == :error} name="tabler-exclamation-circle-filled" class="w-6 h-6" />
            <%= body %>
          </p>
      <% end %>
      <button
        :if={@close}
        type="button"
        class="group absolute top-2 right-1 p-2"
        aria-label={gettext("close")}
      >
        <.icon name="tabler-x" class="w-5 h-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} title="Success!" flash={@flash} />
    <.flash kind={:note} title="Note" flash={@flash} />
    <.flash kind={:error} title="Error!" flash={@flash} />
    <.flash
      id="disconnected"
      kind={:error}
      title="We can't find the internet"
      close={false}
      autoshow={false}
      phx-disconnected={show("#disconnected")}
      phx-connected={hide("#disconnected")}
    >
      Attempting to reconnect <.icon name="tabler-refresh" class="ml-1 w-3 h-3 animate-spin" />
    </.flash>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="space-y-8">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any
  attr :class, :string, default: nil

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :rest, :global, include: ~w(autocomplete cols disabled form max maxlength min minlength
                                   pattern placeholder readonly required rows size step)
  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-gray-300">
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id || @name}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-input text-primary focus:ring-ring"
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "radio", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("radio", value) end)

    ~H"""
    <div phx-feedback-for={@name}>
      <label class="flex items-center gap-4 text-sm leading-6 text-gray-300">
        <input
          type="radio"
          id={@id || @name}
          name={@name}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          checked={@checked}
          class="rounded-full border-input text-primary focus:ring-ring sr-only peer"
          {@rest}
        />
        <%= @label %>
        <%= render_slot(@inner_block) %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="mt-1 block w-full py-2 px-3 border border-input bg-background rounded-md shadow-sm focus:outline-none focus:ring-ring focus:border-ring sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id || @name}
        name={@name}
        class={[
          "bg-background mt-2 block min-h-[6rem] w-full rounded-lg border-input py-[7px] px-[11px]",
          "text-foreground focus:border-ring focus:outline-none focus:ring-4 focus:ring-ring/5 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-input phx-no-feedback:focus:border-ring phx-no-feedback:focus:ring-ring/5",
          "border-input focus:border-ring focus:ring-ring/5",
          @errors != [] && "border-destructive focus:border-destructive focus:ring-destructive/10",
          @class
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label :if={@label} for={@id} class="mb-2"><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id || @name}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "bg-background block w-full rounded-lg border-input py-[7px] px-[11px]",
          "text-foreground focus:outline-none focus:ring-4 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-input phx-no-feedback:focus:border-ring phx-no-feedback:focus:ring-ring/5",
          "border-input focus:border-ring focus:ring-ring/5",
          @errors != [] &&
            "border-destructive focus:border-destructive focus:ring-destructive/10 placeholder-destructive-foreground/50",
          @class
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true
  attr :class, :string, default: nil

  def label(assigns) do
    ~H"""
    <label for={@for} class={["block text-sm font-semibold leading-6 text-foreground", @class]}>
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="phx-no-feedback:hidden mt-3 flex gap-3 text-sm leading-6 text-destructive">
      <.icon name="tabler-exclamation-circle" class="mt-0.5 w-5 h-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]} {@rest}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-foreground focus:outline-none">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="text-sm leading-6 text-muted-foreground">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"
  attr :class, :string, default: nil

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
    attr :align, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class={["w-[40rem] sm:w-full", @class]}>
        <thead class="text-left text-[0.8125rem] leading-6 text-foreground">
          <tr>
            <th
              :for={{col, i} <- Enum.with_index(@col)}
              class={[
                "p-0 pb-4 pr-4 font-medium text-sm text-muted-foreground",
                i == 0 && "pl-4",
                col[:align] == "right" && "text-right"
              ]}
            >
              <%= col[:label] %>
            </th>
            <th class="relative p-0 pb-4"><span class="sr-only"><%= gettext("Actions") %></span></th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-border border-t border-border text-sm leading-6 text-foreground"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-muted/50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class={["block py-4 pr-4", i == 0 && "pl-4"]}>
                <span class={["relative", i == 0 && "font-semibold text-gray-50"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative p-0 w-14 pr-4 sm:pr-6 lg:pr-8">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-gray-50 hover:text-gray-200"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-border">
        <div :for={item <- @item} class="flex gap-4 py-4 sm:gap-8">
          <dt class="w-1/4 flex-none text-[0.8125rem] leading-6 text-foreground">
            <%= item.title %>
          </dt>
          <dd class="text-sm leading-6 text-muted-foreground"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-foreground hover:text-foreground/80"
      >
        <.icon name="tabler-arrow-left" class="w-3 h-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(AlgoraWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(AlgoraWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  Renders a [Tabler Icon](https://tabler.io/icons).

  Icons are extracted from the `deps/tabler_icons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="tabler-x-mark-solid" />
      <.icon name="tabler-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "tabler-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  def icon(%{name: "algora-logo"} = assigns) do
    ~H"""
    <AlgoraWeb.Components.Logos.algora class={@class} />
    """
  end

  def pwa_install_prompt(assigns) do
    ~H"""
    <div
      id="pwa-install-prompt"
      phx-hook="PWAInstallPrompt"
      class="hidden fixed bottom-5 left-1/2 transform -translate-x-1/2 w-[90%] md:max-w-[300px] bg-background rounded-lg shadow-lg p-4 text-center z-50"
    >
      <div class="mb-3">
        <img class="w-16 h-16 bg-muted rounded-lg mx-auto mb-2" src="/images/logo-192px.png" />
        <h1 class="text-lg text-foreground font-semibold">Algora Console</h1>
        <p class="text-sm text-muted-foreground font-semibold">Never miss a bounty again!</p>
      </div>
      <button
        id="pwa-install-button"
        class="hidden bg-primary text-primary-foreground py-2 px-4 rounded-md text-sm font-semibold"
      >
        Install
      </button>
      <button
        id="pwa-close-button"
        class="absolute top-2 right-2 text-muted-foreground hover:text-foreground"
      >
        <svg
          class="w-5 h-5"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M6 18L18 6M6 6l12 12"
          >
          </path>
        </svg>
      </button>
      <div
        id="pwa-instructions-mobile"
        class="hidden text-md text-muted-foreground mt-2 text-center bg-muted p-2 rounded-md"
      >
        Tap <.icon name="tabler-upload" class="size-5 mb-1 text-primary inline" /> or
        <.icon name="tabler-dots-vertical" class="size-5 mb-1 text-primary inline" />
        and select "Add to home screen" to install.
      </div>
    </div>
    """
  end

  defdelegate accordion_item(assigns), to: AlgoraWeb.Components.UI.Accordion
  defdelegate accordion_trigger(assigns), to: AlgoraWeb.Components.UI.Accordion
  defdelegate accordion(assigns), to: AlgoraWeb.Components.UI.Accordion
  defdelegate alert(assigns), to: AlgoraWeb.Components.UI.Alert
  defdelegate avatar_fallback(assigns), to: AlgoraWeb.Components.UI.Avatar
  defdelegate avatar_image(assigns), to: AlgoraWeb.Components.UI.Avatar
  defdelegate avatar(assigns), to: AlgoraWeb.Components.UI.Avatar
  defdelegate badge(assigns), to: AlgoraWeb.Components.UI.Badge
  defdelegate button(assigns), to: AlgoraWeb.Components.UI.Button
  defdelegate card_content(assigns), to: AlgoraWeb.Components.UI.Card
  defdelegate card_description(assigns), to: AlgoraWeb.Components.UI.Card
  defdelegate card_footer(assigns), to: AlgoraWeb.Components.UI.Card
  defdelegate card_header(assigns), to: AlgoraWeb.Components.UI.Card
  defdelegate card_title(assigns), to: AlgoraWeb.Components.UI.Card
  defdelegate card(assigns), to: AlgoraWeb.Components.UI.Card
  defdelegate checkbox(assigns), to: AlgoraWeb.Components.UI.Checkbox
  defdelegate data_table(assigns), to: AlgoraWeb.Components.UI.DataTable
  defdelegate dialog(assigns), to: AlgoraWeb.Components.UI.Dialog
  defdelegate dialog_content(assigns), to: AlgoraWeb.Components.UI.Dialog
  defdelegate dialog_description(assigns), to: AlgoraWeb.Components.UI.Dialog
  defdelegate dialog_footer(assigns), to: AlgoraWeb.Components.UI.Dialog
  defdelegate dialog_header(assigns), to: AlgoraWeb.Components.UI.Dialog
  defdelegate dialog_title(assigns), to: AlgoraWeb.Components.UI.Dialog
  defdelegate drawer(assigns), to: AlgoraWeb.Components.UI.Drawer
  defdelegate drawer_content(assigns), to: AlgoraWeb.Components.UI.Drawer
  defdelegate drawer_header(assigns), to: AlgoraWeb.Components.UI.Drawer
  defdelegate drawer_footer(assigns), to: AlgoraWeb.Components.UI.Drawer
  defdelegate dropdown_menu(assigns), to: AlgoraWeb.Components.UI.DropdownMenu
  defdelegate dropdown_menu_content(assigns), to: AlgoraWeb.Components.UI.DropdownMenu
  defdelegate dropdown_menu_trigger(assigns), to: AlgoraWeb.Components.UI.DropdownMenu
  defdelegate form_control(assigns), to: AlgoraWeb.Components.UI.Form
  defdelegate form_description(assigns), to: AlgoraWeb.Components.UI.Form
  defdelegate form_item(assigns), to: AlgoraWeb.Components.UI.Form
  defdelegate form_label(assigns), to: AlgoraWeb.Components.UI.Form
  defdelegate hover_card_content(assigns), to: AlgoraWeb.Components.UI.HoverCard
  defdelegate hover_card_trigger(assigns), to: AlgoraWeb.Components.UI.HoverCard
  defdelegate hover_card(assigns), to: AlgoraWeb.Components.UI.HoverCard
  defdelegate menu_group(assigns), to: AlgoraWeb.Components.UI.Menu
  defdelegate menu_item(assigns), to: AlgoraWeb.Components.UI.Menu
  defdelegate menu_label(assigns), to: AlgoraWeb.Components.UI.Menu
  defdelegate menu_separator(assigns), to: AlgoraWeb.Components.UI.Menu
  defdelegate menu_shortcut(assigns), to: AlgoraWeb.Components.UI.Menu
  defdelegate menu(assigns), to: AlgoraWeb.Components.UI.Menu
  defdelegate popover_content(assigns), to: AlgoraWeb.Components.UI.Popover
  defdelegate popover_trigger(assigns), to: AlgoraWeb.Components.UI.Popover
  defdelegate popover(assigns), to: AlgoraWeb.Components.UI.Popover
  defdelegate radio_group_item(assigns), to: AlgoraWeb.Components.UI.RadioGroup
  defdelegate radio_group(assigns), to: AlgoraWeb.Components.UI.RadioGroup
  defdelegate scroll_area(assigns), to: AlgoraWeb.Components.UI.ScrollArea
  defdelegate select_content(assigns), to: AlgoraWeb.Components.UI.Select
  defdelegate select_group(assigns), to: AlgoraWeb.Components.UI.Select
  defdelegate select_item(assigns), to: AlgoraWeb.Components.UI.Select
  defdelegate select_label(assigns), to: AlgoraWeb.Components.UI.Select
  defdelegate select_separator(assigns), to: AlgoraWeb.Components.UI.Select
  defdelegate select_trigger(assigns), to: AlgoraWeb.Components.UI.Select
  defdelegate select(assigns), to: AlgoraWeb.Components.UI.Select
  defdelegate separator(assigns), to: AlgoraWeb.Components.UI.Separator
  defdelegate sheet_content(assigns), to: AlgoraWeb.Components.UI.Sheet
  defdelegate sheet_description(assigns), to: AlgoraWeb.Components.UI.Sheet
  defdelegate sheet_footer(assigns), to: AlgoraWeb.Components.UI.Sheet
  defdelegate sheet_header(assigns), to: AlgoraWeb.Components.UI.Sheet
  defdelegate sheet_title(assigns), to: AlgoraWeb.Components.UI.Sheet
  defdelegate sheet(assigns), to: AlgoraWeb.Components.UI.Sheet
  defdelegate stat_card(assigns), to: AlgoraWeb.Components.UI.StatCard
  defdelegate switch(assigns), to: AlgoraWeb.Components.UI.Switch
  defdelegate tabs_content(assigns), to: AlgoraWeb.Components.UI.Tabs
  defdelegate tabs_list(assigns), to: AlgoraWeb.Components.UI.Tabs
  defdelegate tabs_trigger(assigns), to: AlgoraWeb.Components.UI.Tabs
  defdelegate tabs(assigns), to: AlgoraWeb.Components.UI.Tabs
  defdelegate toggle_group_item(assigns), to: AlgoraWeb.Components.UI.ToggleGroup
  defdelegate toggle_group(assigns), to: AlgoraWeb.Components.UI.ToggleGroup
  defdelegate toggle(assigns), to: AlgoraWeb.Components.UI.Toggle
  defdelegate tooltip_content(assigns), to: AlgoraWeb.Components.UI.Tooltip
  defdelegate tooltip_trigger(assigns), to: AlgoraWeb.Components.UI.Tooltip
  defdelegate tooltip(assigns), to: AlgoraWeb.Components.UI.Tooltip
end
