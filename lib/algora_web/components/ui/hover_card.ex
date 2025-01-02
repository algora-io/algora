defmodule AlgoraWeb.Components.UI.HoverCard do
  @moduledoc """
  Implement hover card component

  ## Usage
      <.hover_card>
        <.hover_card_trigger>
          <.button variant="link">
            @salad_ui
          </.button>
        </.hover_card_trigger>
        <.hover_card_content>
           Hover card content
        </.hover_card_content>
      </.hover_card>
  """
  use AlgoraWeb.Component

  @doc """
  Render hover card wrapper
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def hover_card(assigns) do
    ~H"""
    <div class={classes(["group/hover-card relative inline-block", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Render hover card trigger
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def hover_card_trigger(assigns) do
    ~H"""
    <div class={classes(["", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Render hover card content
  """
  attr :class, :string, default: nil
  attr :side, :string, values: ~w(bottom left right top), default: "top"
  attr :align, :string, values: ["start", "center", "end"], default: "center"
  attr :rest, :global
  slot :inner_block, required: true

  def hover_card_content(assigns) do
    assigns =
      assign(assigns, :variant_class, side_variant(assigns.side, assigns.align))

    ~H"""
    <div
      data-side={@side}
      class={
        classes([
          "absolute hidden group-hover/hover-card:block",
          "z-50 w-64 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none animate-in fade-in-0 zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2",
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
end
