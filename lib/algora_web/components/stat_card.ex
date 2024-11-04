defmodule AlgoraWeb.Components.StatCard do
  use AlgoraWeb.Component
  import AlgoraWeb.CoreComponents

  attr :href, :string
  attr :title, :string
  attr :value, :string
  attr :subtext, :string
  attr :icon, :string

  def stat_card(assigns) do
    ~H"""
    <.link href={@href}>
      <div class="group/card relative rounded-lg border bg-card text-card-foreground hover:bg-accent transition-colors duration-75">
        <div class="p-6 flex flex-row items-center justify-between space-y-0 pb-2">
          <h3 class="text-sm font-medium tracking-tight"><%= @title %></h3>
          <.icon name={@icon} class="h-6 w-6 text-muted-foreground" />
        </div>
        <div class="p-6 pt-0">
          <div class="text-2xl font-bold"><%= @value %></div>
          <p class="text-xs text-muted-foreground"><%= @subtext %></p>
        </div>
      </div>
    </.link>
    """
  end
end
