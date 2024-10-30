defmodule AlgoraWeb.Components.Accordion do
  @moduledoc """
  Accordion component for displaying collapsible content.

  ## Example

  <.accordion>
    <.accordion_item>
      <.accordion_trigger group="exclusive">
        Is it accessible?
      </.accordion_trigger>
      <.accordion_content>
        Yes. It adheres to the WAI-ARIA design pattern.
      </.accordion_content>
    </.accordion_item>
    <.accordion_item>
      <.accordion_trigger group="exclusive">
        Is it styled?
      </.accordion_trigger>
      <.accordion_content>
        Yes. It comes with default styles that matches the other components' aesthetic.
      </.accordion_content>
    </.accordion_item>
    <.accordion_item>
      <.accordion_trigger group="exclusive">
        Is it animated?
      </.accordion_trigger>
      <.accordion_content>
        Yes. It's animated by default, but you can disable it if you prefer.
      </.accordion_content>
    </.accordion_item>
  </.accordion>
  """
  use AlgoraWeb.Component

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def accordion(assigns) do
    ~H"""
    <div class={classes(["", @class])}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def accordion_item(assigns) do
    ~H"""
    <div class={classes(["border-b", @class])}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :group, :string, default: nil
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def accordion_trigger(assigns) do
    ~H"""
    <details name={@group} class="group/accordion peer/accordion">
      <summary class={
        classes([
          "flex flex-1 items-center justify-between py-4 font-medium transition-all hover:underline",
          @class
        ])
      }>
        <p class="font-medium">
          <%= render_slot(@inner_block) %>
        </p>

        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="h-4 w-4 shrink-0 transition-transform duration-200 group-open/accordion:rotate-180"
        >
          <path d="m6 9 6 6 6-6"></path>
        </svg>
      </summary>
    </details>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def accordion_content(assigns) do
    ~H"""
    <div class="text-sm overflow-hidden grid grid-rows-[0fr] transition-[grid-template-rows] duration-300 peer-open/accordion:grid-rows-[1fr]">
      <div class="overflow-hidden">
        <div class={classes(["pb-4 pt-0", @class])}>
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end
end
