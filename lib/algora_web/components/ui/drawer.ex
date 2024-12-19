defmodule AlgoraWeb.Components.UI.Drawer do
  @moduledoc """
  Implements a drawer component that slides in from the bottom of the screen.

  ## Examples:

      <.drawer show={@show} phx-click="close">
        <.drawer_header>
          <.h3>Drawer Title</.h3>
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
  attr :class, :string, default: nil
  attr :on_cancel, JS, default: %JS{}
  attr :rest, :global
  slot :inner_block, required: true

  def drawer(assigns) do
    ~H"""
    <div
      class={
        classes([
          "fixed inset-0 bg-black/90 z-50 transition-all duration-300",
          "#{if @show, do: "opacity-100", else: "opacity-0 pointer-events-none"}"
        ])
      }
      phx-click={@on_cancel}
    >
    </div>
    <div
      class={
        classes([
          "fixed inset-x-0 bottom-0 z-50 rounded-t-xl bg-background border transform transition-transform duration-300 ease-in-out",
          "#{if @show, do: "translate-y-0", else: "translate-y-full"}",
          @class
        ])
      }
      {@rest}
    >
      <div class="relative h-full">
        <button
          phx-click={@on_cancel}
          type="button"
          class="w-10 h-10 absolute z-50 top-4 right-4 text-muted-foreground hover:text-foreground flex items-center justify-center"
        >
          <AlgoraWeb.CoreComponents.icon name="tabler-x" class="w-5 h-5" />
        </button>
        <div class="flex flex-col relative h-full p-6">
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
    <div
      class={
        classes([
          "text-base text-muted-foreground uppercase font-display font-semibold pb-4",
          @class
        ])
      }
      {@rest}
    >
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
