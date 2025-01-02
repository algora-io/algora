defmodule AlgoraWeb.Components.UI.RadioGroup do
  @moduledoc false
  use AlgoraWeb.Component

  @doc """
  Radio input group component

  ## Examples:

      <.radio_group name="question-1" value="option-2">
      <div class="flex items-center space-x-2">
        <.radio_group_item builder={builder} value="option-one" id="option-one"></.radio_group_item>
        <.label for="option-one">
          Option One
        </.label>
      </div>
      <div class="flex items-center space-x-2">
        <.radio_group_item builder={builder} value="option-two" id="option-two"></.radio_group_item>
        <.label for="option-two">
          Option Two
        </.label>
      </div>
    </.radio_group>

  """
  attr :name, :string, default: nil
  attr :value, :any, default: nil
  attr :"default-value", :any

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def radio_group(assigns) do
    assigns = prepare_assign(assigns)
    assigns = assign(assigns, :builder, %{name: assigns.name, value: assigns.value})

    ~H"""
    <div
      role="radiogroup"
      aria-required="false"
      dir="ltr"
      class={classes(["grid gap-2", @class])}
      tabindex="0"
      style="outline: none;"
    >
      {render_slot(@inner_block, @builder)}
    </div>
    """
  end

  attr :builder, :map, required: true
  attr :class, :string, default: nil
  attr :checked, :any, default: false
  attr :value, :string, default: nil
  attr :rest, :global

  def radio_group_item(assigns) do
    ~H"""
    <label class={
      classes([
        "aspect-square h-4 w-4 rounded-full border border-primary text-primary ring-offset-background focus:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 has-[:disabled]:cursor-not-allowed has-[:disabled]:opacity-50 inline-grid",
        @class
      ])
    }>
      <input
        type="radio"
        class="hidden peer/radio"
        name={@builder.name}
        value={@value}
        checked={normalize_boolean(@checked) || @builder.value == @value}
        {@rest}
      />
      <span class="hidden items-center justify-center peer-checked/radio:flex">
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
          class="lucide lucide-circle h-2.5 w-2.5 fill-current text-current"
        >
          <circle cx="12" cy="12" r="10"></circle>
        </svg>
      </span>
    </label>
    """
  end
end
