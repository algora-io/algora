defmodule AlgoraWeb.Component.Select do
  @moduledoc """
  Implement of select components from https://ui.shadcn.com/docs/components/select

  ## Examples:

      <form>
         <.select default="banana" id="fruit-select">
            <.select_trigger class="w-[180px]">
              <.select_value placeholder=".select a fruit"/>
            </.select_trigger>
            <.select_content>
              <.select_group>
                <.select_label>Fruits</.select_label>
                <.select_item name="fruit" value="apple">Apple</.select_item>
                <.select_item name="fruit" value="banana">Banana</.select_item>
                <.select_item name="fruit" value="blueberry">Blueberry</.select_item>
                <.select_separator />
                <.select_item  name="fruit" disabled value="grapes">Grapes</.select_item>
                <.select_item  name="fruit" value="pineapple">Pineapple</.select_item>
              </.select_group>
        </.select_content>
          </.select>

        <.button type="submit">Submit</.button>
      </form>
  """
  use AlgoraWeb.Component

  @doc """
  Ready to use select component with all required parts.
  """

  attr :id, :string, default: nil
  attr :name, :any, default: nil
  attr :value, :any, default: nil, doc: "The value of the select"
  attr :"default-value", :any, default: nil, doc: "The default value of the select"

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :label, :string,
    default: nil,
    doc: "The display label of the select value. If not provided, the value will be used."

  attr :placeholder, :string, default: nil, doc: "The placeholder text when no value is selected."

  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def select(assigns) do
    assigns = prepare_assign(assigns)

    assigns =
      assign(assigns, :builder, %{
        id: assigns.id,
        name: assigns.name,
        value: assigns.value,
        label: assigns.label,
        placeholder: assigns.placeholder
      })

    ~H"""
    <div
      id={@id}
      class={classes(["relative group", @class])}
      data-state="closed"
      {@rest}
      x-hide-select={hide_select(@id)}
      x-show-select={show_select(@id)}
      x-toggle-select={toggle_select(@id)}
      phx-click-away={JS.exec("x-hide-select")}
    >
      <%= render_slot(@inner_block, @builder) %>
    </div>
    """
  end

  attr :builder, :map, required: true, doc: "The builder of the select component"
  attr :class, :string, default: nil
  attr :rest, :global

  def select_trigger(assigns) do
    ~H"""
    <button
      type="button"
      class={
        classes([
          "flex h-10 w-full items-center justify-between rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 [&>span]:line-clamp-1",
          @class
        ])
      }
      phx-click={toggle_select(@builder.id)}
      {@rest}
    >
      <span
        class="select-value pointer-events-none before:content-[attr(data-content)]"
        data-content={@builder.label || @builder.value || @builder.placeholder}
      >
      </span>
      <span class="h-4 w-4 opacity-50" />
    </button>
    """
  end

  attr :builder, :map, required: true, doc: "The builder of the select component"

  attr :class, :string, default: nil
  attr :side, :string, values: ~w(top bottom), default: "bottom"
  slot :inner_block, required: true

  attr :rest, :global

  def select_content(assigns) do
    position_class =
      case assigns.side do
        "top" -> "bottom-full mb-1"
        "bottom" -> "top-full mt-1"
      end

    assigns =
      assigns
      |> assign(:position_class, position_class)
      |> assign(:id, assigns.builder.id <> "-content")

    ~H"""
    <.focus_wrap
      id={@id}
      data-side={@side}
      class={
        classes([
          "select-content absolute hidden",
          "z-50 max-h-96 min-w-[8rem] overflow-hidden rounded-md border bg-popover text-popover-foreground shadow-md group-data-[state=open]:animate-in group-data-[state=closed]:animate-out group-data-[state=closed]:fade-out-0 group-data-[state=open]:fade-in-0 group-data-[state=closed]:zoom-out-95 group-data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2",
          @position_class,
          @class
        ])
      }
      {@rest}
    >
      <div class="relative w-full p-1">
        <%= render_slot(@inner_block) %>
      </div>
    </.focus_wrap>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def select_group(assigns) do
    ~H"""
    <div role="group" class={classes([@class])} {@rest}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def select_label(assigns) do
    ~H"""
    <div class={classes(["py-1.5 pl-8 pr-2 text-sm font-semibold", @class])} {@rest}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :builder, :map, required: true, doc: "The builder of the select component"

  attr :value, :string, required: true
  attr :label, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  slot :inner_block, required: true

  attr :rest, :global

  def select_item(assigns) do
    assigns = assign(assigns, :label, assigns.label || assigns.value)

    ~H"""
    <label
      role="option"
      class={
        classes([
          "group/item",
          "relative flex w-full cursor-default select-none items-center rounded-sm py-1.5 pl-8 pr-2 text-sm outline-none data-[disabled]:pointer-events-none data-[disabled]:opacity-50",
          @class
        ])
      }
      {%{"data-disabled": @disabled}}
      phx-click={select_value(@builder.id, @label)}
      {@rest}
    >
      <input
        type="radio"
        class="peer w-0 opacity-0"
        name={@builder.name}
        value={@value}
        checked={@builder.value == @value}
        disabled={@disabled}
        phx-key="Escape"
        phx-keydown={JS.exec("x-hide-select", to: "##{@builder.id}")}
      />
      <div class="absolute top-0 left-0 w-full h-full group-hover/item:bg-accent rounded"></div>
      <span class="hidden peer-checked:block absolute left-2 flex h-3.5 w-3.5 items-center justify-center">
        <span aria-hidden="true">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="lucide lucide-check h-4 w-4"
          >
            <path d="M20 6 9 17l-5-5"></path>
          </svg>
        </span>
      </span>
      <span class="z-0 peer-focus:text-accent-foreground"><%= @label %></span>
    </label>
    """
  end

  def select_separator(assigns) do
    ~H"""
    <div class={classes(["-mx-1 my-1 h-px bg-muted"])}></div>
    """
  end

  defp hide_select(id) do
    %JS{}
    |> JS.pop_focus()
    |> JS.add_class("hidden",
      transition: "ease-out",
      to: "##{id}[data-state=open] .select-content",
      time: 150
    )
    |> JS.set_attribute({"data-state", "closed"}, to: "##{id}")
  end

  # show select and focus first selected item or first item if no selected item
  defp show_select(id) do
    %JS{}
    # show if closed
    |> JS.focus_first(to: "##{id}[data-state=closed] .select-content")
    |> JS.set_attribute({"data-state", "open"}, to: "##{id}")
    |> JS.focus_first(to: "##{id}[data-state=open] .select-content")
    |> JS.focus_first(to: "##{id}[data-state=open] .select-content label:has(input:checked)")
  end

  # show or hide select
  defp toggle_select(id) do
    %JS{}
    |> JS.add_class("hidden",
      transition: "ease-out",
      to: "##{id}[data-state=open] .select-content",
      time: 150
    )
    # show if closed
    |> JS.remove_class("hidden", to: "##{id}[data-state=closed] .select-content")
    |> JS.toggle_attribute({"data-state", "open", "closed"}, to: "##{id}")
    |> JS.focus_first(to: "##{id}[data-state=open] .select-content")
    |> JS.focus_first(to: "##{id}[data-state=open] .select-content label:has(input:checked)")
  end

  # set value to select and hide select
  defp select_value(root_id, value) do
    %JS{}
    |> JS.set_attribute({"data-content", value}, to: "##{root_id} .select-value")
    |> JS.exec("x-hide-select", to: "##{root_id}")
  end
end
