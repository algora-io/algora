defmodule AlgoraWeb.Components.UI.Multiline do
  @moduledoc false
  use AlgoraWeb.Component

  attr :value, :string, required: true
  attr :class, :string, default: nil

  def multiline(assigns) do
    ~H"""
    <div class={classes(["whitespace-pre-line", @class])}>{@value}</div>
    """
  end

  attr :value, :string, required: true
  attr :class, :string, default: nil

  def markdown(assigns) do
    ~H"""
    <div class={classes(["whitespace-normal", @class])}>{Phoenix.HTML.raw(@value)}</div>
    """
  end
end
