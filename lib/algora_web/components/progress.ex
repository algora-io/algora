defmodule AlgoraWeb.Components.Progress do
  @moduledoc false
  use AlgoraWeb.Component

  @doc """
  Render progress bar

  ## Example


      <.progress class="w-[60%]" value={20}/>

  """
  attr :class, :string, default: nil
  attr :value, :integer, default: 0, doc: ""
  attr :rest, :global

  def progress(assigns) do
    assigns = assign(assigns, :value, normalize_integer(assigns[:value]))

    ~H"""
    <div
      class={classes(["relative h-4 w-full overflow-hidden rounded-full bg-secondary", @class])}
      {@rest}
    >
      <div
        class="h-full w-full flex-1 bg-primary transition-all"
        style={"transform: translateX(-#{100 - (@value || 0)}%)"}
      >
      </div>
    </div>
    """
  end
end
