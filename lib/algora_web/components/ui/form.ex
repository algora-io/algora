defmodule AlgoraWeb.Components.UI.Form do
  @moduledoc false
  use AlgoraWeb.Component

  @doc """
  Implement of form component. SaladUI doesn't define its own form, but it provides a set of form-related components to help you build your own form.

  Reuse `.form` from live view Component, so we don't have to duplicate it

  # Examples:

      <div>
        <.form
          class="space-y-6"
          for={@form}
          id="project-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <.form_item>
          <.form_label>What is your project's name?</.form_label>
          <.form_control>
              <Input.input field={@form[:name]} type="text" phx-debounce="500" />
            </.form_control>
            <.form_description>
                This is your public display name.
          </.form_description>
          <.form_message field={@form[:name]} />
          </.form_item>
          <div class="w-full flex flex-row-reverse">
            <.button
              class="btn btn-secondary btn-md"
              icon="inbox_arrow_down"
              phx-disable-with="Saving..."
            >
              Save project
              </.button>
          </div>
            </.form>
      </div>
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def form_item(assigns) do
    ~H"""
    <div class={classes(["space-y-2", @class])} {@rest}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :error, :boolean, default: false

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  slot :inner_block, required: true
  attr :rest, :global

  def form_label(%{field: field} = assigns) do
    assigns =
      if field && not Enum.empty?(field.errors) do
        assign(assigns, error: true)
      else
        assigns
      end

    ~H"""
    <SaladUI.Label.label
      class={
        classes([
          @error && "text-destructive",
          @class
        ])
      }
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </SaladUI.Label.label>
    """
  end

  # attr :class, :string, default: nil
  slot :inner_block, required: true
  # attr :rest, :global

  def form_control(assigns) do
    ~H"""
    <%= render_slot(@inner_block) %>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def form_description(assigns) do
    ~H"""
    <p class={classes(["text-muted-foreground text-sm", @class])} {@rest}>
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  attr :field, Phoenix.HTML.FormField,
    default: nil,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :class, :string, default: nil
  attr :errors, :list, default: []
  slot :inner_block, required: false
  attr :rest, :global

  def form_message(assigns) do
    assigns = prepare_assign(assigns)

    ~H"""
    <p
      :if={msg = render_slot(@inner_block) || not Enum.empty?(@errors)}
      class={classes(["text-destructive text-sm font-medium", @class])}
      {@rest}
    >
      <span :for={msg <- @errors} class="block"><%= msg %></span>
      <%= if @errors == [] do %>
        <%= msg %>
      <% end %>
    </p>
    """
  end
end
