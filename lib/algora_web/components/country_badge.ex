defmodule AlgoraWeb.Components.CountryBadge do
  @moduledoc false
  use AlgoraWeb.Component

  import AlgoraWeb.Components.UI.Badge

  attr :state, :string, required: true
  attr :count, :integer, default: nil
  attr :variant, :string, default: "outline"
  attr :size, :string, values: ~w(sm default), default: "default"
  attr :rest, :global

  def country_badge(assigns) do
    country_code = assigns.state |> String.split("-") |> List.first()
    flag = Algora.Misc.CountryEmojis.get(country_code, nil)
    suffix = assigns.state |> String.split("-") |> List.last()

    assigns =
      assigns
      |> assign(:flag, flag)
      |> assign(:label, if(suffix == "*", do: country_code, else: suffix))
      |> assign(:badge_class, badge_size_class(assigns.size))

    ~H"""
    <.badge :if={@flag} variant={@variant} class={["gap-1", @badge_class]} title={@state} {@rest}>
      <span>{@flag}</span>
      <span class="line-clamp-1">{@label}</span>
      <span :if={@count} class="text-muted-foreground">({@count})</span>
    </.badge>
    """
  end

  defp badge_size_class("sm"), do: "text-[10px] px-1.5 py-0.5"
  defp badge_size_class(_), do: nil
end
