defmodule AlgoraWeb.Components.UI.Pagination do
  @moduledoc false
  use AlgoraWeb.Component

  @doc """
  Renders a pagination.

  ## Examples

        <.pagination>
          <.pagination_content>
            <.pagination_item>
              <.pagination_previous href="#" />
            </.pagination_item>
            <.pagination_item>
              <.pagination_link href="">1</.pagination_link>
            </.pagination_item>
            <.pagination_item>
              <.pagination_link href="" is-active="true">2</.pagination_link>
            </.pagination_item>
            <.pagination_item>
              <.pagination_link href="">3</.pagination_link>
            </.pagination_item>
            <.pagination_item>
              <.pagination_ellipsis />
            </.pagination_item>
            <.pagination_item>
              <.pagination_next href="#" />
            </.pagination_item>
          </.pagination_content>
        </.pagination>

  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def pagination(assigns) do
    ~H"""
    <nav
      arial-label="pagination"
      role="pagination"
      class={
        classes([
          "mx-auto flex w-full justify-center",
          @class
        ])
      }
      {@rest}
      }
    >
      <%= render_slot(@inner_block) %>
    </nav>
    """
  end

  @doc """
  Render pagination content
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def pagination_content(assigns) do
    ~H"""
    <ul
      class={
        classes([
          "flex flex-row items-center gap-1",
          @class
        ])
      }
      {@rest}
      }
    >
      <%= render_slot(@inner_block) %>
    </ul>
    """
  end

  @doc """
  Render pagination item
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def pagination_item(assigns) do
    ~H"""
    <li
      class={
        classes([
          "",
          @class
        ])
      }
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </li>
    """
  end

  @doc """
  Render pagination link
  """
  attr :"is-active", :boolean, default: false
  attr :size, :string, default: "icon"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def pagination_link(assigns) do
    is_active = assigns[:"is-active"] in [true, "true"]

    assigns =
      assigns
      |> assign(
        :variation_class,
        variant(%{size: assigns[:size], variant: (is_active && "outline") || "ghost"})
      )
      |> assign(:"is-active", is_active)

    ~H"""
    <.link
      aria-current={(assigns[:"is-active"] && "page") || ""}
      class={
        classes([
          "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:ring-ring focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50",
          @variation_class,
          @class
        ])
      }
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  @doc """
  Render next button
  """
  attr :class, :string, default: nil
  attr :rest, :global

  def pagination_next(assigns) do
    ~H"""
    <.pagination_link
      aria-label="Go to next page"
      size="default"
      class={classes(["gap-1 pr-2.5", @class])}
      {@rest}
    >
      <span>Next</span>
      <svg
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke-width="2"
        stroke="currentColor"
        class="size-6 w-3.5"
      >
        <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" />
      </svg>
    </.pagination_link>
    """
  end

  @doc """
  Render previous button
  """
  attr :class, :string, default: nil
  attr :rest, :global

  def pagination_previous(assigns) do
    ~H"""
    <.pagination_link
      aria-label="Go to previous page"
      size="default"
      class={classes(["gap-1 pr-2.5", @class])}
      {@rest}
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke-width="2"
        stroke="currentColor"
        class="size-6 w-3.5"
      >
        <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" />
      </svg>
      <span>Previous</span>
    </.pagination_link>
    """
  end

  @doc """
  Render ellipsis
  """
  attr :class, :string, default: nil
  attr :rest, :global

  def pagination_ellipsis(assigns) do
    ~H"""
    <span
      class={
        classes([
          "flex h-9 w-9 items-center justify-center",
          @class
        ])
      }
      {@rest}
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke-width="2"
        stroke="currentColor"
        class="size-6 w--4 h-4"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M6.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0ZM12.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0ZM18.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Z"
        />
      </svg>

      <span class="sr-only">More pages</span>
    </span>
    """
  end

  @variants %{
    variant: %{
      "outline" =>
        "border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground",
      "ghost" => "hover:bg-accent hover:text-accent-foreground"
    },
    size: %{
      "default" => "h-9 px-4 py-2",
      "sm" => "h-8 rounded-md px-3 text-xs",
      "lg" => "h-10 rounded-md px-8",
      "icon" => "h-9 w-9"
    }
  }

  defp variant(props) do
    variants =
      Map.take(props, ~w(variant size)a)

    Enum.map_join(variants, " ", fn {key, value} -> @variants[key][value] end)
  end
end
