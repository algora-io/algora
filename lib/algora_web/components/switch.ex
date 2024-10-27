defmodule AlgoraWeb.Component.Switch do
  @moduledoc false
  use AlgoraWeb.Component

  @doc """
  Implement checkbox input component

  ## Examples:

  """
  attr :id, :string, required: true
  attr :name, :string, default: nil
  attr :value, :boolean, default: nil
  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :"default-value", :any, values: [true, false, "true", "false"], default: false
  attr :class, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :rest, :global

  def switch(assigns) do
    assigns =
      prepare_assign(assigns)

    assigns =
      assign(assigns, :checked, Phoenix.HTML.Form.normalize_value("checkbox", assigns.value))

    ~H"""
    <button
      type="button"
      role="switch"
      data-state={(@checked && "checked") || "unchecked"}
      phx-click={toggle(@id)}
      class={
        classes([
          "group/switch inline-flex h-6 w-11 shrink-0 cursor-pointer items-center rounded-full border-2 border-transparent transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background disabled:cursor-not-allowed disabled:opacity-50 data-[state=checked]:bg-primary data-[state=unchecked]:bg-input"
        ])
      }
      id={@id}
      {%{disabled: @disabled}}
    >
      <span class="pointer-events-none block h-5 w-5 rounded-full bg-background shadow-lg ring-0 transition-transform group-data-[state=checked]/switch:translate-x-5 group-data-[state=unchecked]/switch:translate-x-0">
      </span>
      <input type="hidden" name={@name} value="false" />
      <input type="checkbox" class="hidden" name={@name} value="true" {%{checked: @checked}} {@rest} />
    </button>
    """
  end

  defp toggle(id) do
    %JS{}
    |> JS.toggle_attribute({"data-state", "checked", "unchecked"})
    |> JS.toggle_attribute({"checked", true}, to: "##{id} input[type=checkbox]")
  end
end
