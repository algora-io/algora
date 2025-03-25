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
  use Gettext, backend: AlgoraWeb.Gettext

  alias AlgoraWeb.Components.UI.Accordion
  alias AlgoraWeb.Components.UI.Alert
  alias AlgoraWeb.Components.UI.Avatar
  alias AlgoraWeb.Components.UI.Card
  alias AlgoraWeb.Components.UI.Dialog
  alias AlgoraWeb.Components.UI.Drawer
  alias AlgoraWeb.Components.UI.DropdownMenu
  alias AlgoraWeb.Components.UI.HoverCard
  alias AlgoraWeb.Components.UI.Menu
  alias AlgoraWeb.Components.UI.Popover
  alias AlgoraWeb.Components.UI.RadioGroup
  alias AlgoraWeb.Components.UI.Select
  alias AlgoraWeb.Components.UI.Sheet
  alias AlgoraWeb.Components.UI.Tabs
  alias AlgoraWeb.Components.UI.ToggleGroup
  alias AlgoraWeb.Components.UI.Tooltip
  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.JS

  slot :inner_block

  def connection_status(assigns) do
    ~H"""
    <div
      id="connection-status"
      class="fade-in-scale fixed top-1 right-1 z-50 hidden w-96 rounded-md bg-red-900 p-4"
      js-show={show("#connection-status")}
      js-hide={hide("#connection-status")}
    >
      <div class="flex">
        <div class="flex-shrink-0">
          <svg
            class="mr-3 -ml-1 h-5 w-5 animate-spin text-red-100"
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
            {render_slot(@inner_block)}
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
      aria-label="Algora"
      class="focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500"
    >
      <AlgoraWeb.Components.Logos.algora class={["fill-current", @class || "h-auto w-20"]} />
    </.link>
    """
  end

  attr :class, :string, default: nil

  def wordmark(assigns) do
    ~H"""
    <.link
      navigate="/"
      aria-label="Algora"
      class="focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500"
    >
      <AlgoraWeb.Components.Wordmarks.algora class={
        classes(["fill-current", @class || "h-auto w-20"])
      } />
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
  attr :class, :string, default: nil
  attr :border, :boolean, default: false

  slot :img do
    attr :src, :string
    attr :alt, :string
  end

  slot :title
  slot :subtitle

  slot :link do
    attr :navigate, :string
    attr :href, :string
    attr :patch, :string
    attr :method, :any
  end

  def dropdown(assigns) do
    ~H"""
    <!-- User account dropdown -->
    <div class={classes(["relative w-full text-left", @class])}>
      <div>
        <button
          id={@id}
          type="button"
          class={
            classes([
              "group w-full rounded-md px-3 py-2 text-left text-sm font-medium text-foreground hover:bg-accent/75 focus:outline-none focus:ring-2 focus:ring-ring",
              @border && "border border-input"
            ])
          }
          phx-click={show_dropdown("##{@id}-dropdown")}
          phx-hook="Menu"
          data-active-class="bg-accent"
          aria-haspopup="true"
        >
          <span class="flex w-full items-center justify-between">
            <span class="flex min-w-0 items-center justify-between space-x-3">
              <%= for img <- @img do %>
                <.avatar class="h-10 w-10">
                  <.avatar_image src={img[:src]} />
                  <.avatar_fallback>
                    {Algora.Util.initials(img[:alt])}
                  </.avatar_fallback>
                </.avatar>
              <% end %>
              <span class="flex min-w-0 flex-1 flex-col">
                <span class="truncate text-sm font-medium text-gray-50">
                  {render_slot(@title)}
                </span>
                <span class="truncate text-sm text-gray-400">{render_slot(@subtitle)}</span>
              </span>
            </span>
            <.icon
              name="tabler-selector"
              class="ml-2 h-6 w-6 flex-shrink-0 text-muted-foreground group-hover:text-gray-400"
            />
          </span>
        </button>
      </div>
      <div
        id={"#{@id}-dropdown"}
        phx-click-away={hide_dropdown("##{@id}-dropdown")}
        class="absolute right-0 left-0 z-10 mt-1 hidden origin-top divide-y divide-border rounded-md bg-popover shadow-lg ring-1 ring-border"
        role="menu"
        aria-labelledby={@id}
      >
        <div class="py-1" role="none">
          <%= for link <- @link do %>
            <.link
              tabindex="-1"
              role="menuitem"
              class="block p-3 text-sm text-foreground hover:bg-accent focus:outline-none focus:ring-2 focus:ring-ring"
              phx-click={hide_dropdown("##{@id}-dropdown")}
              {link}
            >
              {render_slot(link)}
            </.link>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def context_selector(assigns) do
    ~H"""
    <.dropdown id="dashboard-dropdown" class="min-w-[12rem]">
      <:img src={@current_context.avatar_url} alt={@current_context.handle} />
      <:title>{@current_context.name}</:title>
      <:subtitle :if={@current_context.handle && @current_context.id != @current_user.id}>
        @{@current_context.handle}
      </:subtitle>
      <:subtitle :if={
        @current_context.handle && @current_context.id == @current_user.id &&
          @current_user.last_context == "personal"
      }>
        Solver dashboard
      </:subtitle>
      <:subtitle :if={
        @current_context.handle && @current_context.id == @current_user.id &&
          @current_user.last_context != "personal"
      }>
        Bounty board
      </:subtitle>

      <:link href={~p"/set_context/personal"}>
        <div class="flex items-center whitespace-nowrap">
          <div class="mr-3 relative size-10 shrink-0">
            <.avatar class="mr-3 size-10">
              <.avatar_image src={@current_user.avatar_url} />
              <.avatar_fallback>
                {Algora.Util.initials(@current_user.name)}
              </.avatar_fallback>
            </.avatar>
            <div class="absolute -right-2 -bottom-1 bg-popover rounded-full size-5 flex items-center justify-center">
              <.icon name="tabler-code" class="size-5 text-foreground" />
            </div>
          </div>
          <div class="truncate">
            <div class="font-semibold truncate">{@current_user.name}</div>
            <div class="text-sm text-muted-foreground truncate">
              Solver dashboard
            </div>
          </div>
        </div>
      </:link>
      <:link :if={@current_user.handle} href={~p"/set_context/#{@current_user.handle}"}>
        <div class="flex items-center whitespace-nowrap">
          <div class="mr-3 relative size-10 shrink-0">
            <.avatar class="mr-3 size-10">
              <.avatar_image src={@current_user.avatar_url} />
              <.avatar_fallback>
                {Algora.Util.initials(@current_user.name)}
              </.avatar_fallback>
            </.avatar>
            <div class="absolute -right-2 -bottom-1 bg-popover rounded-full size-5 flex items-center justify-center">
              <.icon name="tabler-currency-dollar" class="size-5 text-foreground" />
            </div>
          </div>
          <div class="truncate">
            <div class="font-semibold truncate">{@current_user.name}</div>
            <div class="text-sm text-muted-foreground truncate">
              Bounty board
            </div>
          </div>
        </div>
      </:link>
      <:link
        :for={ctx <- @all_contexts |> Enum.filter(&(&1.id != @current_user.id))}
        :if={@current_context.id != ctx.id}
        href={
          if ctx.id == @current_user.id,
            do: ~p"/set_context/personal",
            else: ~p"/set_context/#{ctx.handle}"
        }
      >
        <div class="flex items-center whitespace-nowrap">
          <.avatar class="mr-3 size-10">
            <.avatar_image src={ctx.avatar_url} />
            <.avatar_fallback>
              {Algora.Util.initials(ctx.name)}
            </.avatar_fallback>
          </.avatar>
          <div class="truncate">
            <div class="font-semibold truncate">{ctx.name}</div>
            <div :if={ctx.handle} class="text-sm text-muted-foreground truncate">@{ctx.handle}</div>
          </div>
        </div>
      </:link>
      <:link :if={@current_user.is_admin} href={~p"/admin"}>
        <div class="flex items-center whitespace-nowrap">
          <div class="mr-3 flex size-10 items-center justify-center bg-accent rounded-full">
            <.icon name="tabler-adjustments-alt" class="size-6" />
          </div>
          <div class="font-semibold">Admin</div>
        </div>
      </:link>
      <:link href={~p"/auth/logout"}>
        <div class="flex items-center whitespace-nowrap">
          <div class="mr-3 flex size-10 items-center justify-center bg-accent rounded-full">
            <.icon name="tabler-logout" class="size-6" />
          </div>
          <div class="font-semibold">Logout</div>
        </div>
      </:link>
    </.dropdown>
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
          class="group w-full rounded-full bg-gray-800 text-left text-sm font-medium text-gray-200 hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:ring-offset-2 focus:ring-offset-gray-800"
          phx-click={show_dropdown("##{@id}-dropdown")}
          phx-hook="Menu"
          data-active-class="bg-gray-800"
          aria-haspopup="true"
        >
          <%= for img <- @img do %>
            <img class="h-8 w-8 flex-shrink-0 rounded-full bg-gray-600" {assigns_to_attributes(img)} />
          <% end %>
        </button>
      </div>
      <div
        id={"#{@id}-dropdown"}
        phx-click-away={hide_dropdown("##{@id}-dropdown")}
        class="min-w-[8rem] absolute right-0 z-10 mt-1 hidden origin-right divide-y divide-gray-600 rounded-md bg-gray-800 shadow-lg ring-1 ring-gray-800 ring-opacity-5"
        role="menu"
        aria-labelledby={@id}
      >
        <div class="py-1" role="none">
          <%= for link <- @link do %>
            <.link
              tabindex="-1"
              role="menuitem"
              class="block px-4 py-2 text-sm text-gray-200 hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:ring-offset-2 focus:ring-offset-gray-700"
              {link}
            >
              {render_slot(link)}
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
      transition: {"transition ease-in-out duration-300 transform", "-translate-x-full", "translate-x-0"}
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
      transition: {"transition ease-in-out duration-300 transform", "translate-x-0", "-translate-x-full"}
    )
    |> JS.show(to: "#show-mobile-sidebar", transition: "fade-in")
    |> JS.dispatch("js:exec", to: "#show-mobile-sidebar", detail: %{call: "focus", args: []})
  end

  def show_dropdown(to) do
    [
      to: to,
      transition: {"transition ease-out duration-120", "transform opacity-0 scale-95", "transform opacity-100 scale-100"}
    ]
    |> JS.show()
    |> JS.set_attribute({"aria-expanded", "true"}, to: to)
  end

  def hide_dropdown(to) do
    [
      to: to,
      transition: {"transition ease-in duration-120", "transform opacity-100 scale-100", "transform opacity-0 scale-95"}
    ]
    |> JS.hide()
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
      class="z-[1001] relative hidden"
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
              class="relative hidden rounded-2xl bg-background px-10 py-6 shadow-lg shadow-background/10 ring-1 ring-border transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={hide_modal(@on_cancel, @id)}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40 focus:opacity-40 focus:outline-none"
                  aria-label={gettext("close")}
                >
                  <.icon name="tabler-x" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <header :if={@title != []}>
                  <h1 id={"#{@id}-title"} class="text-lg font-semibold leading-8 text-foreground">
                    {render_slot(@title)}
                  </h1>
                  <p
                    :if={@subtitle != []}
                    id={"#{@id}-description"}
                    class="mt-2 text-sm leading-6 text-muted-foreground"
                  >
                    {render_slot(@subtitle)}
                  </p>
                </header>
                {render_slot(@inner_block)}
                <div :if={@confirm != [] or @cancel != []} class="mb-4 ml-6 flex items-center gap-5">
                  <.button
                    :for={confirm <- @confirm}
                    id={"#{@id}-confirm"}
                    phx-click={@on_confirm}
                    phx-disable-with
                    class="px-3 py-2"
                  >
                    {render_slot(confirm)}
                  </.button>
                  <.link
                    :for={cancel <- @cancel}
                    phx-click={hide_modal(@on_cancel, @id)}
                    class="text-sm font-semibold leading-6 text-foreground hover:text-foreground/80"
                  >
                    {render_slot(cancel)}
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
  attr :kind, :atom, values: [:info, :warning, :error], doc: "used for styling and flash lookup"
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
        "fixed bottom-4 left-1/2 -translate-x-1/2 z-[1000] hidden w-80 rounded-lg p-3 shadow-md ring-1 sm:w-96",
        @kind == :info &&
          "bg-emerald-950 fill-success-foreground text-success-foreground ring ring-success/70",
        @kind == :warning &&
          "bg-amber-950 fill-warning-foreground text-warning-foreground ring ring-warning/70",
        @kind == :error &&
          "bg-red-950 fill-destructive-foreground text-destructive-foreground ring ring-destructive/70"
      ]}
      {@rest}
    >
      <%= case msg do %>
        <% %{body: body, action: %{ href: href, body: action_body }} -> %>
          <div class="text-[0.8125rem] flex gap-3 font-semibold">
            <.icon :if={@kind == :info} name="tabler-circle-check" class="h-6 w-6 text-success" />
            <.icon
              :if={@kind == :warning}
              name="tabler-alert-square-rounded"
              class="h-6 w-6 text-warning"
            />
            <.icon
              :if={@kind == :error}
              name="tabler-alert-triangle"
              class="h-6 w-6 text-destructive"
            />
            <div>
              <div>{body}</div>
              <.link navigate={href} class="underline">{action_body}</.link>
            </div>
          </div>
        <% body -> %>
          <p class="text-[0.8125rem] flex items-center gap-3 font-semibold">
            <.icon :if={@kind == :info} name="tabler-circle-check" class="h-6 w-6 text-success" />
            <.icon
              :if={@kind == :warning}
              name="tabler-alert-square-rounded"
              class="h-6 w-6 text-warning"
            />
            <.icon
              :if={@kind == :error}
              name="tabler-alert-triangle"
              class="h-6 w-6 text-destructive"
            />
            {body}
          </p>
      <% end %>
      <button
        :if={@close}
        type="button"
        class="group absolute top-0 right-0 bottom-0 flex h-8 w-8 items-center justify-center"
        aria-label={gettext("close")}
      >
        <.icon name="tabler-x" class="h-4 w-4 opacity-70 group-hover:opacity-100" />
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
    <.flash kind={:warning} title="Warning!" flash={@flash} />
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
      Attempting to reconnect <.icon name="tabler-refresh" class="ml-auto h-4 w-4 animate-spin" />
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
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
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
  attr :helptext, :string, default: nil
  attr :icon, :string, default: nil
  attr :value, :any
  attr :class, :string, default: nil

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :hide_errors, :boolean, default: false
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :rest, :global, include: ~w(autocomplete cols disabled form max maxlength min minlength
                                   pattern placeholder readonly required rows size step)
  slot :inner_block

  def input(%{field: %FormField{} = field} = assigns) do
    errors = if assigns.hide_errors, do: [], else: field.errors

    value =
      with %Money{} <- field.value,
           {:ok, value} <- Money.to_string(field.value) do
        String.trim(value, "$")
      else
        _ -> field.value
      end

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> value end)
    |> input()
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)

    ~H"""
    <div>
      <label class="flex items-center gap-4 text-sm leading-6 text-gray-300">
        <%!-- <input type="hidden" name={@name} value="false" /> --%>
        <input
          type="checkbox"
          id={@id || @name}
          name={@name}
          value={@value}
          checked={@checked}
          class={classes(["rounded border-input text-primary focus:ring-ring", @class])}
          {@rest}
        />
        {@label}
      </label>
    </div>
    """
  end

  def input(%{type: "radio", value: value} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("radio", value) end)

    ~H"""
    <div>
      <label class="flex items-center gap-4 text-sm leading-6 text-gray-300">
        <input
          type="radio"
          id={@id || @name}
          name={@name}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          checked={@checked}
          class="peer sr-only rounded-full border-input text-primary focus:ring-ring"
          {@rest}
        />
        {@label}
        {render_slot(@inner_block)}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <p :if={@helptext} class="mb-2 text-sm text-muted-foreground">{@helptext}</p>
      <select
        id={@id}
        name={@name}
        class="mt-1 block w-full rounded-md border border-input bg-background px-3 py-2 shadow-sm focus:border-ring focus:outline-none focus:ring-ring sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="" class="hidden">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <p :if={@helptext} class="mb-2 text-sm text-muted-foreground">{@helptext}</p>
      <textarea
        id={@id || @name}
        name={@name}
        class={[
          "min-h-[6rem] py-[7px] px-[11px] block w-full rounded-lg border-input bg-background",
          "text-foreground focus:border-ring focus:outline-none focus:ring-4 focus:ring-ring/5 sm:text-sm sm:leading-6",
          "border-input focus:border-ring focus:ring-ring/5",
          @errors != [] && "border-destructive focus:border-destructive focus:ring-destructive/10",
          @class
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div>
      <.label :if={@label} for={@id} class="mb-2">{@label}</.label>
      <p :if={@helptext} class="-mt-2 mb-2 text-sm text-muted-foreground">{@helptext}</p>
      <div class="relative">
        <div :if={@icon} class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
          <.icon name={@icon} class="h-5 w-5 text-muted-foreground" />
        </div>
        <input
          type={@type}
          name={@name}
          id={@id || @name}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={
            classes([
              "py-[7px] px-[11px] block w-full rounded-lg border-input bg-background",
              "text-foreground focus:outline-none focus:ring-1 sm:text-sm sm:leading-6",
              "border-input focus:border-ring focus:ring-ring",
              @errors != [] &&
                "border-destructive placeholder-destructive-foreground/50 focus:border-destructive focus:ring-destructive/10",
              @icon && "pl-10",
              @class
            ])
          }
          autocomplete="off"
          {@rest}
        />
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
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
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-destructive">
      <.icon name="tabler-exclamation-circle" class="mt-0.5 h-5 w-5 flex-none" />
      {render_slot(@inner_block)}
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
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm leading-6 text-muted-foreground">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
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
        <thead class="text-[0.8125rem] text-left leading-6 text-foreground">
          <tr>
            <th
              :for={{col, i} <- Enum.with_index(@col)}
              class={[
                "p-0 pr-4 pb-4 text-sm font-medium text-muted-foreground",
                i == 0 && "pl-4",
                col[:align] == "right" && "text-right"
              ]}
            >
              {col[:label]}
            </th>
            <th class="relative p-0 pb-4"><span class="sr-only">{gettext("Actions")}</span></th>
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
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0 pr-4 sm:pr-6 lg:pr-8">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-gray-50 hover:text-gray-200"
                >
                  {render_slot(action, @row_item.(row))}
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
          <dt class="text-[0.8125rem] w-1/4 flex-none leading-6 text-foreground">
            {item.title}
          </dt>
          <dd class="text-sm leading-6 text-muted-foreground">{render_slot(item)}</dd>
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
        <.icon name="tabler-arrow-left" class="h-3 w-3" />
        {render_slot(@inner_block)}
      </.link>
    </div>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
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
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the icon"

  def icon(%{name: "tabler-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} {@rest} />
    """
  end

  def icon(%{name: "algora"} = assigns) do
    ~H"""
    <AlgoraWeb.Components.Logos.algora class={@class} />
    """
  end

  def icon(%{name: "github"} = assigns) do
    ~H"""
    <AlgoraWeb.Components.Logos.github class={@class} />
    """
  end

  def icon(%{name: "youtube"} = assigns) do
    ~H"""
    <AlgoraWeb.Components.Logos.youtube class={@class} />
    """
  end

  def icon(%{name: "discord"} = assigns) do
    ~H"""
    <AlgoraWeb.Components.Logos.discord class={@class} />
    """
  end

  def pwa_install_prompt(assigns) do
    ~H"""
    <div
      id="pwa-install-prompt"
      phx-hook="PWAInstallPrompt"
      class="w-[90%] fixed bottom-5 left-1/2 z-50 hidden -translate-x-1/2 transform rounded-lg bg-background p-4 text-center shadow-lg md:max-w-[300px]"
    >
      <div class="mb-3">
        <img class="mx-auto mb-2 h-16 w-16 rounded-lg bg-muted" src="/images/logo-192px.png" />
        <h1 class="text-lg font-semibold text-foreground">Algora Console</h1>
        <p class="text-sm font-semibold text-muted-foreground">Never miss a bounty again!</p>
      </div>
      <button
        id="pwa-install-button"
        class="hidden rounded-md bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground"
      >
        Install
      </button>
      <button
        id="pwa-close-button"
        class="absolute top-2 right-2 text-muted-foreground hover:text-foreground"
      >
        <svg
          class="h-5 w-5"
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
        class="text-md mt-2 hidden rounded-md bg-muted p-2 text-center text-muted-foreground"
      >
        Tap <.icon name="tabler-upload" class="mb-1 inline size-5 text-primary" /> or
        <.icon name="tabler-dots-vertical" class="mb-1 inline size-5 text-primary" />
        and select "Add to home screen" to install.
      </div>
    </div>
    """
  end

  attr :title, :string, default: nil
  attr :subtitle, :string, default: nil
  attr :link, :string, default: nil
  slot :inner_block

  def section(assigns) do
    ~H"""
    <div class="relative h-full">
      <div :if={@title} class="flex items-end justify-between pb-2">
        <div class="flex flex-col space-y-1.5">
          <h2 class="text-2xl font-semibold leading-none tracking-tight">{@title}</h2>
          <p :if={@subtitle} class="text-sm text-muted-foreground">{@subtitle}</p>
        </div>
        <.button :if={@link} navigate={@link} variant="outline">
          View all
        </.button>
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :data, :any, required: true

  def debug(assigns) do
    ~H"""
    <pre class={classes(["overflow-auto rounded-lg bg-muted/50 p-4 font-mono text-sm", @class])}><%= Jason.encode!(@data, pretty: true) %></pre>
    """
  end

  defp link?(assigns) do
    Enum.any?([assigns[:href], assigns[:navigate], assigns[:patch]])
  end

  attr :href, :string, default: nil
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :replace, :boolean, default: false
  slot :inner_block

  def maybe_link(assigns) do
    ~H"""
    <%= if link?(assigns) do %>
      <.link href={@href} navigate={@navigate} patch={@patch} replace={@replace}>
        {render_slot(@inner_block)}
      </.link>
    <% else %>
      <span>{render_slot(@inner_block)}</span>
    <% end %>
    """
  end

  defdelegate accordion_item(assigns), to: Accordion
  defdelegate accordion_trigger(assigns), to: Accordion
  defdelegate accordion(assigns), to: Accordion
  defdelegate alert_description(assigns), to: Alert
  defdelegate alert_title(assigns), to: Alert
  defdelegate alert(assigns), to: Alert
  defdelegate avatar_fallback(assigns), to: Avatar
  defdelegate avatar_image(assigns), to: Avatar
  defdelegate avatar(assigns), to: Avatar
  defdelegate badge(assigns), to: AlgoraWeb.Components.UI.Badge
  defdelegate button(assigns), to: AlgoraWeb.Components.UI.Button
  defdelegate card_content(assigns), to: Card
  defdelegate card_description(assigns), to: Card
  defdelegate card_footer(assigns), to: Card
  defdelegate card_header(assigns), to: Card
  defdelegate card_title(assigns), to: Card
  defdelegate card(assigns), to: Card
  defdelegate checkbox(assigns), to: AlgoraWeb.Components.UI.Checkbox
  defdelegate data_table(assigns), to: AlgoraWeb.Components.UI.DataTable
  defdelegate dialog(assigns), to: Dialog
  defdelegate dialog_content(assigns), to: Dialog
  defdelegate dialog_description(assigns), to: Dialog
  defdelegate dialog_footer(assigns), to: Dialog
  defdelegate dialog_header(assigns), to: Dialog
  defdelegate dialog_title(assigns), to: Dialog
  defdelegate drawer_content(assigns), to: Drawer
  defdelegate drawer_description(assigns), to: Drawer
  defdelegate drawer_footer(assigns), to: Drawer
  defdelegate drawer_header(assigns), to: Drawer
  defdelegate drawer_title(assigns), to: Drawer
  defdelegate drawer(assigns), to: Drawer
  defdelegate dropdown_menu_content(assigns), to: DropdownMenu
  defdelegate dropdown_menu_item(assigns), to: DropdownMenu
  defdelegate dropdown_menu_label(assigns), to: DropdownMenu
  defdelegate dropdown_menu_separator(assigns), to: DropdownMenu
  defdelegate dropdown_menu_trigger(assigns), to: DropdownMenu
  defdelegate dropdown_menu(assigns), to: DropdownMenu
  defdelegate form_control(assigns), to: AlgoraWeb.Components.UI.Form
  defdelegate form_description(assigns), to: AlgoraWeb.Components.UI.Form
  defdelegate form_item(assigns), to: AlgoraWeb.Components.UI.Form
  defdelegate form_label(assigns), to: AlgoraWeb.Components.UI.Form
  defdelegate hover_card_content(assigns), to: HoverCard
  defdelegate hover_card_trigger(assigns), to: HoverCard
  defdelegate hover_card(assigns), to: HoverCard
  defdelegate menu_group(assigns), to: Menu
  defdelegate menu_item(assigns), to: Menu
  defdelegate menu_label(assigns), to: Menu
  defdelegate menu_separator(assigns), to: Menu
  defdelegate menu_shortcut(assigns), to: Menu
  defdelegate menu(assigns), to: Menu
  defdelegate popover_content(assigns), to: Popover
  defdelegate popover_trigger(assigns), to: Popover
  defdelegate popover(assigns), to: Popover
  defdelegate radio_group(assigns), to: RadioGroup
  defdelegate scroll_area(assigns), to: AlgoraWeb.Components.UI.ScrollArea
  defdelegate select_content(assigns), to: Select
  defdelegate select_group(assigns), to: Select
  defdelegate select_item(assigns), to: Select
  defdelegate select_label(assigns), to: Select
  defdelegate select_separator(assigns), to: Select
  defdelegate select_trigger(assigns), to: Select
  defdelegate select(assigns), to: Select
  defdelegate separator(assigns), to: AlgoraWeb.Components.UI.Separator
  defdelegate sheet_content(assigns), to: Sheet
  defdelegate sheet_description(assigns), to: Sheet
  defdelegate sheet_footer(assigns), to: Sheet
  defdelegate sheet_header(assigns), to: Sheet
  defdelegate sheet_title(assigns), to: Sheet
  defdelegate sheet(assigns), to: Sheet
  defdelegate stat_card(assigns), to: AlgoraWeb.Components.UI.StatCard
  defdelegate switch(assigns), to: AlgoraWeb.Components.UI.Switch
  defdelegate tabs_content(assigns), to: Tabs
  defdelegate tabs_list(assigns), to: Tabs
  defdelegate tabs_trigger(assigns), to: Tabs
  defdelegate tabs(assigns), to: Tabs
  defdelegate toggle_group_item(assigns), to: ToggleGroup
  defdelegate toggle_group(assigns), to: ToggleGroup
  defdelegate toggle(assigns), to: AlgoraWeb.Components.UI.Toggle
  defdelegate tooltip_content(assigns), to: Tooltip
  defdelegate tooltip_trigger(assigns), to: Tooltip
  defdelegate tooltip(assigns), to: Tooltip
end
