defmodule AlgoraWeb.Components.Achievement do
  @moduledoc false
  use AlgoraWeb.Component

  import AlgoraWeb.CoreComponents

  def achievement(%{achievement: %{status: :completed}} = assigns) do
    ~H"""
    <div class="group flex items-center gap-3">
      <div class="flex h-5 w-5 items-center justify-center text-success">
        <.icon name="tabler-circle-check-filled" class="h-5 w-5" />
      </div>
      <span class="text-sm font-medium text-success">
        {@achievement.name}
      </span>
    </div>
    """
  end

  def achievement(%{achievement: %{status: :upcoming}} = assigns) do
    ~H"""
    <div class="group flex items-center gap-3">
      <div class="flex h-5 w-5 items-center justify-center">
        <div class="h-2 w-2 rounded-full bg-muted-foreground"></div>
      </div>
      <span class="text-sm font-medium text-muted-foreground">
        {@achievement.name}
      </span>
    </div>
    """
  end

  def achievement(%{achievement: %{status: :current}} = assigns) do
    ~H"""
    <div class="flex items-start" aria-current="step">
      <span class="relative flex h-5 w-5 flex-shrink-0 items-center justify-center" aria-hidden="true">
        <span class="absolute h-5 w-5 animate-pulse rounded-full bg-success/25"></span>
        <span class="relative block h-2 w-2 rounded-full bg-success"></span>
      </span>
      <span class="ml-3 text-sm font-medium text-muted-foreground">
        {@achievement.name}
      </span>
    </div>
    """
  end
end
