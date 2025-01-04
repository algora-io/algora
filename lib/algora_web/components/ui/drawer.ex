defmodule AlgoraWeb.Components.UI.Drawer do
  @moduledoc """
  Implements a drawer component that slides in from the bottom of the screen.

  ## Examples:

      <.drawer show={@show} phx-click="close">
        <.drawer_header>
          <.drawer_title>Drawer Title</.drawer_title>
          <.drawer_description>Drawer Description</.drawer_description>
        </.drawer_header>
        <.drawer_content>
          Content goes here
        </.drawer_content>
        <.drawer_footer>
          <.button phx-click="close">Close</.button>
        </.drawer_footer>
      </.drawer>
  """
  use AlgoraWeb.Component

  # Main drawer wrapper
  attr :show, :boolean, default: false, doc: "Controls drawer visibility"
  attr :direction, :string, default: "bottom", values: ["bottom", "right"], doc: "Drawer slide direction"
  attr :class, :string, default: nil
  attr :on_cancel, JS, default: %JS{}
  attr :rest, :global
  slot :inner_block, required: true

  def drawer(assigns) do
    ~H"""
    <div
      class={
        classes([
          "fixed inset-0 z-50 bg-black/90 transition-all duration-300",
          "#{if @show, do: "opacity-100", else: "pointer-events-none opacity-0"}"
        ])
      }
      phx-click={@on_cancel}
    >
    </div>
    <div
      class={
        classes([
          "fixed z-50 transform border bg-background transition-transform duration-300 ease-in-out",
          case @direction do
            "bottom" -> "inset-x-0 bottom-0 rounded-t-xl"
            "right" -> "inset-y-0 right-0 h-full max-w-lg w-full"
          end,
          case @direction do
            "bottom" -> if(@show, do: "translate-y-0", else: "translate-y-full")
            "right" -> if(@show, do: "translate-x-0", else: "translate-x-full")
          end,
          @class
        ])
      }
      {@rest}
    >
      <div class="relative h-full">
        <button
          phx-click={@on_cancel}
          type="button"
          class="absolute top-4 right-4 z-50 flex h-10 w-10 items-center justify-center text-muted-foreground hover:text-foreground"
        >
          <AlgoraWeb.CoreComponents.icon name="tabler-x" class="h-5 w-5" />
        </button>
        <div class="relative flex h-full flex-col p-6">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def drawer_header(assigns) do
    ~H"""
    <div class={classes(["flex flex-col space-y-1.5 pb-4", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def drawer_title(assigns) do
    ~H"""
    <div class={classes(["text-2xl font-semibold text-white", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def drawer_description(assigns) do
    ~H"""
    <div class={classes(["text-sm text-muted-foreground", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def drawer_content(assigns) do
    ~H"""
    <div class={classes(["overflow-y-auto", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def drawer_footer(assigns) do
    ~H"""
    <div class={classes(["mt-auto", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
