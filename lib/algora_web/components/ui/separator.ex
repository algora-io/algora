defmodule AlgoraWeb.Components.UI.Separator do
  @moduledoc false
  use AlgoraWeb.Component

  @doc """
  Renders a separator

  ## Examples

     <.separator orientation="horizontal" />

  """
  attr :orientation, :string, values: ~w(vertical horizontal), default: "horizontal"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  def separator(assigns) do
    ~H"""
    <div
      class={
        classes([
          "shrink-0 bg-border",
          (@orientation == "horizontal" && "h-[1px] w-full") || "w-[1px] h-full",
          @class
        ])
      }
      {@rest}
    >
    </div>
    """
  end
end
