defmodule AlgoraWeb.Components.Activity do
  @moduledoc false
  use AlgoraWeb.Component

  import AlgoraWeb.CoreComponents

  attr :activities, :list, required: true

  def activities_timeline(assigns) do
    ~H"""
    <div class="space-y-2 h-[400px] overflow-y-auto">
      <%= for {_id, activity} <- assigns[:activities] do %>
        <div class="flex-grow hover:bg-accent">
          <.activity_card activity={activity} />
        </div>
      <% end %>
    </div>
    """
  end

  attr :activity, :map, required: true

  def activity_card(assigns) do
    ~H"""
    <.link
      href={url_for_activity(assigns[:activity])}
      class="flex flex-grow items-center gap-4 mt-4 mb-4 p-4 pb-4 border-b w-full last:border-none first:border-t first:mt-0 first:pt-4"
      tabindex="-1"
    >
      <div class={[
        "flex h-9 w-9 items-center justify-center rounded-full",
        activity_background_class(@activity.type)
      ]}>
        <.icon name={activity_icon(to_string(@activity.type))} class="h-5 w-5" />
      </div>
      <div class="flex-1">
        <div class="font-medium">
          <.activity_name type={assigns.activity.type} />
        </div>
        <div class="text-sm text-muted-foreground">
          {Calendar.strftime(assigns.activity.inserted_at, "%b %d, %Y, %H:%M:%S")}
        </div>
      </div>
    </.link>
    """
  end

  attr :type, :atom, required: true

  def activity_name(%{type: type} = assigns) do
    assigns = assign(assigns, :name, activity_type_to_name(type))

    ~H"""
    <div class="">{@name}</div>
    """
  end

  attr :id, :string, required: true
  attr :class, :string, default: nil
  attr :activities, :list, required: true

  def dropdown_activities(assigns) do
    ~H"""
    <div class={classes(["relative w-full text-left", @class])}>
      <div>
        <button
          id={@id}
          type="button"
          class="group w-full rounded-md px-3.5 py-2 text-left text-sm font-medium text-foreground hover:bg-accent focus:outline-none focus:ring-2 focus:ring-ring"
          phx-click={show_dropdown("##{@id}-dropdown")}
          phx-hook="Menu"
          data-active-class="bg-accent"
          aria-haspopup="true"
        >
          <span class="flex w-full items-center justify-between">
            <span class="flex min-w-0 items-center justify-between space-x-3">
              <.icon name="tabler-activity" class="h-15 w-15 shrink-0" />
            </span>
            <.icon
              name="tabler-selector"
              class="ml-2 h-5 w-5 flex-shrink-0 text-gray-500 group-hover:text-gray-400"
            />
          </span>
        </button>
      </div>
      <div
        id={"#{@id}-dropdown"}
        phx-click-away={hide_dropdown("##{@id}-dropdown")}
        class="absolute mt-4 p-0 right-[200px] left-[-160px] z-10 mt-1 hidden origin-top w-[400px] divide-border rounded-md bg-popover shadow-lg ring-1 ring-border shadow-[0_0_1px_rgba(255,255,255,0.5)]"
        role="menu"
        aria-labelledby={@id}
      >
        <div class="py-1 w-full overflow-y-auto" role="none">
          <.activities_timeline activities={@activities} />
        </div>
      </div>
    </div>
    """
  end

  defp url_for_activity(%{type: :identity_created, assoc: assoc}), do: "/@/#{assoc.provider_login}"

  defp url_for_activity(activity) do
    slug = activity.assoc_name |> to_string() |> String.replace("_activities", "")
    "/a/#{slug}/#{activity.id}"
  end

  defp activity_type_to_name(type) do
    type
    |> to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize(&1))
  end

  defp activity_icon(type) do
    "tabler-file-check"
  end

  defp activity_background_class(type) do
    "bg-primary/20"
  end
end
