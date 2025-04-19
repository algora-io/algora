defmodule AlgoraWeb.Components.UI.RadioGroup do
  @moduledoc false
  use AlgoraWeb.Component

  import AlgoraWeb.CoreComponents

  @doc """
  Radio input group component styled with a modern card-like appearance.

  ## Examples:

      <.radio_group
        name="hiring"
        options={[{"Yes", "true"}, {"No", "false"}]}
        field={@form[:hiring]}
      />

  """
  attr :name, :string, default: nil
  attr :options, :list, default: [], doc: "List of {label, value} tuples"
  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form"
  attr :class, :string, default: nil

  def radio_group(assigns) do
    ~H"""
    <div class={classes([@class])}>
      <%= for {label, value} <- @options do %>
        <label class={[
          "group relative flex cursor-pointer rounded-lg px-3 py-2 shadow-sm focus:outline-none",
          "border-2 bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10",
          "border-border has-[:checked]:border-primary has-[:checked]:bg-primary/10"
        ]}>
          <div class="sr-only">
            <.input
              field={@field}
              type="radio"
              value={value}
              checked={to_string(@field.value) == to_string(value)}
            />
          </div>
          <span class="flex flex-1 gap-1 items-center justify-between">
            <span class="text-sm font-medium">{label}</span>
            <.icon
              name="tabler-check"
              class="invisible size-5 text-primary group-has-[:checked]:visible"
            />
          </span>
        </label>
      <% end %>
    </div>
    <.error :for={msg <- @field.errors}>{translate_error(msg)}</.error>
    """
  end
end
