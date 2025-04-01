defmodule AlgoraWeb.Components.UI.Avatar do
  @moduledoc false
  use AlgoraWeb.Component
  use AlgoraWeb, :verified_routes

  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

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
      src={@src || ~p"/images/placeholder-avatar.png"}
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

  attr :class, :string, default: nil
  attr :rest, :global
  attr :srcs, :list, default: []
  attr :limit, :integer, default: 4

  def avatar_group(assigns) do
    ~H"""
    <div class="relative flex -space-x-1">
      <%= for src <- @srcs |> Enum.take(@limit) do %>
        <.avatar class={classes(["ring-4 ring-background", @class])}>
          <.avatar_image src={src} />
          <.avatar_fallback>
            {Algora.Util.initials(src)}
          </.avatar_fallback>
        </.avatar>
      <% end %>
      <%= if length(@srcs) > @limit do %>
        <.avatar class={classes(["ring-4 ring-background", @class])}>
          <.avatar_fallback>
            +{length(@srcs) - @limit}
          </.avatar_fallback>
        </.avatar>
      <% end %>
    </div>
    """
  end
end
