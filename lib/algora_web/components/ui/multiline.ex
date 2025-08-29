defmodule AlgoraWeb.Components.UI.Multiline do
  @moduledoc false
  use AlgoraWeb.Component

  attr :value, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def multiline(assigns) do
    ~H"""
    <div class={classes(["whitespace-pre-line", @class])} {@rest}>{@value}</div>
    """
  end

  attr :value, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def markdown(assigns) do
    ~H"""
    <div class={classes(["whitespace-normal", @class])} {@rest}>{Phoenix.HTML.raw(@value)}</div>
    """
  end
end
