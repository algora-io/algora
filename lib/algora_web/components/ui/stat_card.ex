defmodule AlgoraWeb.Components.UI.StatCard do
  @moduledoc false
  use AlgoraWeb.Component

  import AlgoraWeb.CoreComponents

  attr :href, :string, default: nil
  attr :title, :string
  attr :value, :string
  attr :subtext, :string, default: nil
  attr :icon, :string, default: nil

  def stat_card(assigns) do
    ~H"""
    <%= if @href do %>
      <.link href={@href}>
        <.stat_card_content {assigns} />
      </.link>
    <% else %>
      <.stat_card_content {assigns} />
    <% end %>
    """
  end

  defp stat_card_content(assigns) do
    ~H"""
    <div class="group/card relative rounded-lg border bg-card text-card-foreground transition-colors duration-75 hover:bg-accent">
      <div class="flex flex-row items-center justify-between space-y-0 p-6 pb-2">
        <h3 class="text-sm font-medium tracking-tight">{@title}</h3>
        <.icon :if={@icon} name={@icon} class="h-6 w-6 text-muted-foreground" />
      </div>
      <div class="p-6 pt-0">
        <div class="text-2xl font-bold">{@value}</div>
        <p :if={@subtext} class="text-xs text-muted-foreground">{@subtext}</p>
      </div>
    </div>
    """
  end
end
