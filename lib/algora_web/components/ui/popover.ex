defmodule AlgoraWeb.Components.UI.Popover do
  @moduledoc """
  Implement Popover component

  ## Usage
      <.popover>
        <.popover_trigger target="my-id">
          <.button variant="link">
            @salad_ui
          </.button>
        </.popover_trigger>
        <.popover_content id="my-id" side="left">
           Hover card content
        </.popover_content>
      </.popover>
  """
  use AlgoraWeb.Component

  @doc """
  Render popover wrapper
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def popover(assigns) do
    ~H"""
    <div
      class={
        classes([
          "inline-block relative",
          @class
        ])
      }
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Render popover trigger
  """
  attr :class, :string, default: nil

  attr :target, :string,
    required: true,
    doc: "The id of target element to show popover"

  attr :rest, :global
  slot :inner_block, required: true

  def popover_trigger(assigns) do
    ~H"""
    <div
      class={
        classes([
          "",
          @class
        ])
      }
      phx-click={toggle_target(@target)}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Render popover content
  """
  attr :class, :string, default: nil
  attr :side, :string, values: ~w(bottom left right top), default: "top"
  attr :align, :string, values: ["start", "center", "end"], default: "center"
  attr :open, :boolean, default: false
  attr :rest, :global
  slot :inner_block, required: true

  def popover_content(assigns) do
    assigns =
      assign(assigns, :variant_class, side_variant(assigns.side, assigns.align))
      |> assign_new(:state, fn ->
        if assigns[:open] in ["true", true] do
          "open"
        else
          "closed"
        end
      end)

    ~H"""
    <div
      data-side={@side}
      data-state={@state}
      phx-click-away={hide()}
      class={
        classes([
          "absolute block",
          "z-50 w-72 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none animate-in fade-in-0 zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 data-[state=closed]:hidden",
          @variant_class,
          @class
        ])
      }
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp toggle_target(id) do
    JS.toggle_attribute({"data-state", "open", "closed"}, to: "##{id}")
  end

  defp hide() do
    JS.set_attribute({"data-state", "closed"})
  end
end
