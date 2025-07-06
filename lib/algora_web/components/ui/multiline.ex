defmodule AlgoraWeb.Components.UI.Multiline do
  @moduledoc false
  use AlgoraWeb.Component

  attr :value, :string
  attr :class, :string, default: nil

  def multiline(assigns) do
    ~H"""
    <div class={classes(["whitespace-pre-line", @class])}>{@value}</div>
    """
  end
end
