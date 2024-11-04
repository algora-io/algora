defmodule AlgoraWeb.Components.UI.Button do
  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  use AlgoraWeb.Component

  attr :type, :string, default: nil
  attr :class, :string, default: nil

  attr :variant, :string,
    values: ~w(default secondary destructive outline ghost link),
    default: "default",
    doc: "the button variant style"

  attr :size, :string, values: ~w(default sm lg icon), default: "default"
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def(button(assigns)) do
    assigns = assign(assigns, :variant_class, variant(assigns))

    ~H"""
    <button
      type={@type}
      class={
        classes([
          "phx-submit-loading:opacity-75 disabled:opacity-75",
          "inline-flex items-center justify-center whitespace-nowrap rounded-lg text-sm font-medium transition-colors focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50",
          @variant_class,
          @class
        ])
      }
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @variants %{
    variant: %{
      "default" =>
        "bg-primary/50 hover:bg-primary/30 text-foreground border-primary/80 hover:border-primary focus-visible:outline-primary-600 data-[state=open]:bg-primary-500/80 data-[state=open]:outline-primary-600 shadow border",
      "destructive" =>
        "bg-destructive/50 hover:bg-destructive/30 text-destructive-foreground border-destructive/80 hover:border-destructive focus-visible:outline-destructive-600 data-[state=open]:bg-destructive-500/80 data-[state=open]:outline-destructive-600 shadow border",
      "hover:destructive" =>
        "bg-background border-input hover:bg-destructive/30 text-accent-foreground hover:border-destructive focus-visible:outline-destructive-600 data-[state=open]:bg-destructive-500/80 data-[state=open]:outline-destructive-600 shadow border",
      "outline" =>
        "border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground",
      "secondary" => "bg-secondary text-secondary-foreground shadow-sm hover:bg-secondary/80",
      "ghost" => "hover:bg-accent hover:text-accent-foreground",
      "link" => "text-primary underline-offset-4 hover:underline"
    },
    size: %{
      "default" => "h-9 px-4 py-2 text-sm",
      "sm" => "h-8 rounded-md px-3 text-xs",
      "lg" => "h-10 rounded-md px-8",
      "icon" => "h-9 w-9"
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
