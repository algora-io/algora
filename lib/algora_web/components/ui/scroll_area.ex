defmodule AlgoraWeb.Components.UI.ScrollArea do
  @moduledoc false
  use AlgoraWeb.Component

  @doc """
  Render Scroll area component

  ## Example

  ```elixir
    <.scroll_area>
      <div class="p-4">
        <h4 class="mb-4 text-sm font-medium leading-none">Tags</h4>
        <%= for tag <- 1..50 do %>
          <div class="text-sm">
            v1.2.0-beta.<%= tag %>
          </div>
          <.separator class="my-2" />
        <% end %>
      </div>
    </.scroll_area>
  ```
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block

  def scroll_area(assigns) do
    ~H"""
    <div
      class={
        classes([
          "relative overflow-hidden",
          "salad-scroll-area rounded-[inherit] h-full w-full overflow-y-auto overflow-x-hidden scrollbar-thin",
          @class
        ])
      }
      {@rest}
    >
      <div class="-mr-3" style="min-width: 100%;">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
