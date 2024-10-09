defmodule AlgoraWeb.Components.Avatar do
  @moduledoc false
  use Phoenix.Component

  attr(:src, :string)
  attr(:alt, :string)
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  def user_avatar(assigns) do
    ~H"""
    <.avatar class={@class} {@rest}>
      <.avatar_fallback class="fallback">
        <%= @alt
        |> String.first()
        |> String.upcase() %>
      </.avatar_fallback>
      <.avatar_image src={@src} alt={@alt} />
    </.avatar>
    """
  end

  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def avatar(assigns) do
    ~H"""
    <span class={cn(["flex relative overflow-hidden", @class])} {@rest}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  attr(:src, :string)
  attr(:alt, :string)
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  def avatar_image(assigns) do
    ~H"""
    <img
      class={cn(["aspect-square h-full w-full absolute", @class])}
      src={@src}
      alt={@alt}
      {@rest}
      phx-update="ignore"
      style="display:none"
      onload="this.style.display=''"
    />
    """
  end

  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: false)

  def avatar_fallback(assigns) do
    ~H"""
    <span
      class={cn(["absolute flex h-full w-full items-center justify-center rounded-full", @class])}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  # TODO
  defp cn(x), do: x
end
