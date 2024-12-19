defmodule AlgoraWeb.Components.UI.Label do
  @moduledoc false
  use AlgoraWeb.Component

  @doc """
  Renders a label.

  ## Examples

      <.label>Send!</.label>
  """
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value for)
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label
      class={
        classes([
          "text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </label>
    """
  end
end
