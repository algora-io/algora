defmodule AlgoraWeb.Components.UI.Avatar do
  @moduledoc false
  use AlgoraWeb.Component

  attr :class, :string, default: nil
  attr :rest, :global

  def avatar(assigns) do
    ~H"""
    <div class={classes(["relative h-10 w-10 shrink-0 overflow-hidden rounded-full", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :src, :string, default: nil
  attr :rest, :global

  def avatar_image(assigns) do
    assigns = assign(assigns, id: "avatar-image-#{Algora.Util.random_string()}")

    ~H"""
    <img
      id={@id}
      src={@src || "http://console.algora.io/placeholder-avatar.png"}
      class={classes(["aspect-square h-full w-full bg-muted", @class])}
      phx-hook="AvatarImage"
      {@rest}
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
      {render_slot(@inner_block)}
    </span>
    """
  end
end
