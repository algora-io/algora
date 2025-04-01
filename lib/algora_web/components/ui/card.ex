defmodule AlgoraWeb.Components.UI.Card do
  @moduledoc """
  Implement of card components from https://ui.shadcn.com/docs/components/card
  """
  use AlgoraWeb.Component

  @doc """
  Card component

  ## Examples:

        <.card>
          <.card_header>
            <.card_title>Card title</.card_title>
            <.card_description>Card subtitle</.card_description>
          </.card_header>
          <.card_content>
            Card text
          </.card_content>
          <.card_footer>
            <.button>Button</.button>
          </.card_footer>
        </.card>
  """

  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def card(assigns) do
    ~H"""
    <div class={classes(["rounded-xl border bg-card text-card-foreground shadow", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def card_header(assigns) do
    ~H"""
    <div class={classes(["flex flex-col space-y-1.5 p-6 pb-0", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def card_title(assigns) do
    ~H"""
    <h3 class={classes(["text-2xl font-semibold leading-none tracking-tight", @class])} {@rest}>
      {render_slot(@inner_block)}
    </h3>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def card_description(assigns) do
    ~H"""
    <p class={classes(["text-sm text-muted-foreground", @class])} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def card_content(assigns) do
    ~H"""
    <div class={classes(["p-6", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def card_footer(assigns) do
    ~H"""
    <div class={classes(["flex items-center justify-between p-6 ", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
