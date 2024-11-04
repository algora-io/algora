defmodule AlgoraWeb.Components.UI.Toggle do
  @moduledoc false
  use AlgoraWeb.Component

  @doc """
  Toggle component, A two-state button that can be either on or off.

  ## Example:

      <.toggle value="true" size="sm" variant="outline">Bold</.toggle>
  """
  attr :id, :any, default: nil
  attr :name, :any, default: nil

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :value, :boolean, default: false
  attr :"default-value", :any, values: [true, false, "true", "false"], default: false

  attr :disabled, :boolean, default: false
  attr :variant, :string, values: ~w(default outline), default: "default"
  attr :size, :string, values: ~w(default sm lg), default: "default"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def toggle(assigns) do
    assigns =
      prepare_assign(assigns)

    assigns =
      assigns
      |> assign_new(:checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns.value)
      end)
      |> assign(:variant_class, variant(assigns))

    ~H"""
    <button
      onclick="this.querySelector('.toggle-input').click()"
      disabled={@disabled}
      class={
        classes([
          "inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors hover:bg-muted hover:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 has-[:checked]:bg-accent has-[:checked]:text-accent-foreground",
          @variant_class,
          @class
        ])
      }
    >
      <input type="hidden" name={@name} value="false" />
      <input
        type="checkbox"
        class="toggle-input hidden"
        id={@id}
        name={@name}
        value="true"
        checked={@checked}
        {@rest}
      />
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @variants %{
    variant: %{
      "default" => "bg-transparent",
      "outline" =>
        "border border-input bg-transparent hover:bg-accent hover:text-accent-foreground"
    },
    size: %{
      "default" => "h-10 px-3",
      "sm" => "h-9 px-2.5",
      "lg" => "h-11 px-5"
    }
  }

  @default_variants %{
    variant: "default",
    size: "default"
  }

  defp variant(props) do
    variants = Map.take(props, ~w(variant size)a)
    variants = Map.merge(@default_variants, variants)

    Enum.map_join(variants, " ", fn {key, value} -> @variants[key][value] end)
  end
end
