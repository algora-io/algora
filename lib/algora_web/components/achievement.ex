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

  def achievement(%{achievement: %{status: :upcoming, path: path}} = assigns) do
    ~H"""
    <.maybe_link navigate={path}>
      <div class={
        classes([
          "group flex items-center gap-3",
          path && "hover:text-foreground"
        ])
      }>
        <div class="flex h-5 w-5 items-center justify-center">
          <div class={
            classes([
              "h-2 w-2 rounded-full bg-muted-foreground",
              path && "group-hover:bg-foreground"
            ])
          }>
          </div>
        </div>
        <span class={
          classes([
            "text-sm font-medium text-muted-foreground",
            path && "group-hover:text-foreground"
          ])
        }>
          {@achievement.name}
        </span>
      </div>
    </.maybe_link>
    """
  end

  def achievement(%{achievement: %{status: :current, path: path}} = assigns) do
    ~H"""
    <.maybe_link navigate={path}>
      <div
        class={[
          "group flex items-start",
          path && "hover:text-foreground"
        ]}
        aria-current="step"
      >
        <span
          class="relative flex h-5 w-5 flex-shrink-0 items-center justify-center"
          aria-hidden="true"
        >
          <span class={
            classes([
              "absolute h-5 w-5 animate-pulse rounded-full bg-success/25",
              path && "group-hover:bg-foreground/25"
            ])
          }>
          </span>
          <span class={
            classes([
              "relative block h-2 w-2 rounded-full bg-success",
              path && "group-hover:bg-foreground"
            ])
          }>
          </span>
        </span>
        <span class={
          classes([
            "ml-3 text-sm font-medium text-muted-foreground",
            path && "group-hover:text-foreground"
          ])
        }>
          {@achievement.name}
        </span>
      </div>
    </.maybe_link>
    """
  end
end
