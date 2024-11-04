defmodule AlgoraWeb.Components.UI.Checkbox do
  @moduledoc false
  use AlgoraWeb.Component

  @doc """
  Implement checkbox input component

  ## Examples:
      <.checkbox class="!border-destructive" name="agree" value={true} />
  """
  attr :name, :any, default: nil
  attr :value, :any, default: nil
  attr :"default-value", :any, values: [true, false, "true", "false"], default: false
  attr :field, Phoenix.HTML.FormField
  attr :class, :string, default: nil
  attr :rest, :global

  def checkbox(assigns) do
    assigns =
      prepare_assign(assigns)

    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns.value)
      end)

    ~H"""
    <input type="hidden" name={@name} value="false" />
    <input
      type="checkbox"
      class={
        classes([
          "peer h-4 w-4 shrink-0 rounded-sm border border-primary shadow focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50 checked:bg-primary checked:text-primary-foreground",
          @class
        ])
      }
      name={@name}
      value="true"
      checked={@checked}
      {@rest}
    />
    """
  end
end
