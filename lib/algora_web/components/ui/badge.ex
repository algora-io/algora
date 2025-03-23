defmodule AlgoraWeb.Components.UI.Badge do
  @moduledoc false
  use AlgoraWeb.Component

  @doc """
  Renders a badge component

  ## Examples

      <.badge>Badge</.badge>
      <.badge variant="destructive">Badge</.badge>
  """
  attr :class, :string, default: nil

  attr :variant, :string,
    values: ~w(default secondary destructive success warning outline),
    default: "default",
    doc: "the badge variant style"

  attr :rest, :global
  slot :inner_block, required: true

  def badge(assigns) do
    assigns = assign(assigns, :variant_class, variant(assigns))

    ~H"""
    <div
      class={
        classes([
          "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-input",
          @variant_class,
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @variants %{
    variant: %{
      "default" => "bg-accent/60 text-accent-foreground ring-accent-foreground/20",
      "secondary" => "bg-secondary/10 text-secondary ring-secondary/20",
      "destructive" => "bg-destructive/10 text-destructive ring-destructive/20",
      "success" => "bg-success/10 text-success ring-success/20",
      "warning" => "bg-warning/10 text-warning ring-warning/20",
      "outline" => "bg-transparent text-foreground ring-foreground/30"
    }
  }

  @default_variants %{
    variant: "default"
  }

  defp variant(props) do
    variants = Map.merge(@default_variants, props)

    Enum.map_join(variants, " ", fn {key, value} -> @variants[key][value] end)
  end
end
