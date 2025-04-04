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
          "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium border border-input relative",
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
      "default" => "bg-accent/10 text-accent-foreground border-accent-foreground/20",
      "secondary" => "bg-secondary/10 text-secondary border-secondary/20",
      "destructive" => "bg-destructive/10 text-destructive border-destructive/20",
      "success" => "bg-success/10 text-success border-success/20",
      "warning" => "bg-warning/10 text-warning border-warning/20",
      "outline" => "bg-transparent text-foreground border-foreground/30",
      "indigo" => "bg-indigo-400/10 text-indigo-400 border-indigo-400/20",
      "purple" => "bg-purple-400/10 text-purple-400 border-purple-400/20",
      "blue" => "bg-blue-400/10 text-blue-400 border-blue-400/20"
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
