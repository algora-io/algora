defmodule AlgoraWeb.Components.Avatar do
  @moduledoc false
  use AlgoraWeb.Component

  attr :class, :string, default: nil
  attr :rest, :global

  def avatar(assigns) do
    ~H"""
    <span
      class={classes(["relative h-10 w-10 shrink-0 overflow-hidden rounded-full", @class])}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global

  def avatar_image(assigns) do
    ~H"""
    <img
      class={classes(["aspect-square h-full w-full", @class])}
      {@rest}
      phx-update="ignore"
      style="display:none"
      onload="this.style.display=''"
    />
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: false

  def avatar_fallback(assigns) do
    ~H"""
    <span
      class={
        classes(["flex h-full w-full items-center justify-center rounded-full bg-muted", @class])
      }
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </span>
    """
  end
end
