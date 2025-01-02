defmodule AlgoraWeb.Components.UI.Alert do
  @moduledoc false
  use AlgoraWeb.Component

  @doc """
  Render alert

  ## Examples

      <.alert variant="destructive">
        <.alert_title>Alert title</.alert_title>
        <.alert_description>Alert description</.alert_description>
      </.alert>
  """

  attr :variant, :string, default: "default", values: ~w(default destructive)
  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global, default: %{}

  def alert(assigns) do
    assigns = assign(assigns, :variant_class, variant(assigns))

    ~H"""
    <div
      class={
        classes([
          "relative w-full rounded-lg border p-4 [&>span~*]:pl-7 [&>span+div]:translate-y-[-3px] [&>span]:absolute [&>span]:left-4 [&>span]:top-4",
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

  @doc """
  Render alert title
  """
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)
  slot :inner_block, required: true

  def alert_title(assigns) do
    ~H"""
    <h5
      class={
        classes([
          "mb-1 font-medium leading-none tracking-tight",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </h5>
    """
  end

  @doc """
  Render alert description
  """
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)
  slot :inner_block, required: true

  def alert_description(assigns) do
    ~H"""
    <div
      class={
        classes([
          "text-sm [&_p]:leading-relaxed",
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
      "default" => "bg-background text-foreground",
      "destructive" => "border-destructive/50 text-destructive dark:border-destructive [&>span]:text-destructive"
    }
  }

  @default_variants %{
    variant: "default"
  }

  defp variant(variants) do
    variants = Map.merge(@default_variants, variants)

    Enum.map_join(variants, " ", fn {key, value} -> @variants[key][value] end)
  end
end
