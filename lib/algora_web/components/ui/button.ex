defmodule AlgoraWeb.Components.UI.Button do
  @moduledoc false
  use AlgoraWeb.Component

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :href, :string, default: nil
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :replace, :boolean, default: false

  attr :variant, :string,
    values: ~w(default secondary destructive outline ghost link),
    default: "default",
    doc: "the button variant style"

  attr :size, :string, values: ~w(default sm lg icon), default: "default"
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    assigns =
      assigns
      |> assign(:is_link, link?(assigns))
      |> assign(:common_classes, [
        "disabled:opacity-75 phx-submit-loading:opacity-75",
        "inline-flex items-center justify-center whitespace-nowrap rounded-lg text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50",
        variant(assigns),
        assigns.class
      ])

    ~H"""
    <%= if @is_link do %>
      <.link
        href={@href}
        navigate={@navigate}
        patch={@patch}
        replace={@replace}
        class={classes(@common_classes)}
        {@rest}
      >
        {render_slot(@inner_block)}
      </.link>
    <% else %>
      <button type={@type} class={classes(@common_classes)} {@rest}>
        {render_slot(@inner_block)}
      </button>
    <% end %>
    """
  end

  @variants %{
    variant: %{
      "default" =>
        "bg-primary/50 hover:bg-primary/30 text-foreground border-primary/80 hover:border-primary focus-visible:outline-primary-600 data-[state=open]:bg-primary-500/80 data-[state=open]:outline-primary-600 shadow border",
      "blue" =>
        "bg-blue-500/50 hover:bg-blue-500/30 text-foreground border-blue-500/80 hover:border-blue-500 focus-visible:outline-blue-600 data-[state=open]:bg-blue-500/80 data-[state=open]:outline-blue-600 shadow border",
      "purple" =>
        "bg-purple-500/50 hover:bg-purple-500/30 text-foreground border-purple-500/80 hover:border-purple-500 focus-visible:outline-purple-600 data-[state=open]:bg-purple-500/80 data-[state=open]:outline-purple-600 shadow border",
      "indigo" =>
        "bg-indigo-500/50 hover:bg-indigo-500/30 text-foreground border-indigo-500/80 hover:border-indigo-500 focus-visible:outline-indigo-600 data-[state=open]:bg-indigo-500/80 data-[state=open]:outline-indigo-600 shadow border",
      "destructive" =>
        "bg-destructive/50 hover:bg-destructive/30 text-destructive-foreground border-destructive/80 hover:border-destructive focus-visible:outline-destructive-600 data-[state=open]:bg-destructive-500/80 data-[state=open]:outline-destructive-600 shadow border",
      "hover:destructive" =>
        "bg-background border-input hover:bg-destructive/30 text-accent-foreground hover:border-destructive focus-visible:outline-destructive-600 data-[state=open]:bg-destructive-500/80 data-[state=open]:outline-destructive-600 shadow border",
      "outline" => "border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground",
      "subtle" =>
        "bg-foreground hover:bg-foreground/90 text-background border-background/20 hover:border-background/40 focus-visible:outline-background shadow border",
      "secondary" =>
        "bg-secondary hover:bg-secondary/80 text-foreground border-secondary-foreground/20 hover:border-secondary-foreground/40 focus-visible:outline-secondary-foreground shadow border",
      "ghost" => "hover:bg-accent hover:text-accent-foreground",
      "link" => "text-primary underline-offset-4 hover:underline",
      "none" => ""
    },
    size: %{
      "default" => "h-9 px-4 py-2 text-sm",
      "sm" => "h-8 rounded-md px-3 text-xs",
      "lg" => "h-10 rounded-md px-8 text-base",
      "xl" => "h-12 rounded-md px-10 text-lg",
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

  defp link?(assigns) do
    Enum.any?([assigns[:href], assigns[:navigate], assigns[:patch]])
  end
end
