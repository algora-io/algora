defmodule AlgoraWeb.Components.TimezoneSelect do
  @moduledoc false
  use AlgoraWeb.Component

  import AlgoraWeb.CoreComponents, only: [input: 1]

  alias Phoenix.HTML.FormField

  attr(:field, FormField, required: true)
  attr(:label, :string, default: "Timezone")
  attr(:query, :string, default: "")
  attr(:query_name, :string, default: "timezone_query")

  def timezone_select(assigns) do
    assigns =
      assign(
        assigns,
        :options,
        filter_timezone_options(assigns.query, assigns.field.value)
      )

    ~H"""
    <div class="space-y-2">
      <.input
        type="search"
        name={@query_name}
        label={"Search #{@label}"}
        value={@query}
        placeholder="Search by city, region, or UTC offset"
        autocomplete="off"
        phx-debounce="300"
      />
      <.input field={@field} label={@label} type="select" options={@options} />
    </div>
    """
  end

  defp filter_timezone_options(query, selected_timezone) do
    query = query |> to_string() |> String.trim() |> String.downcase()

    Algora.Time.list_friendly_timezones()
    |> Enum.filter(fn {label, timezone} ->
      query == "" or
        String.contains?(String.downcase(label), query) or
        String.contains?(String.downcase(timezone), query)
    end)
    |> include_selected_timezone(selected_timezone)
  end

  defp include_selected_timezone(options, selected_timezone)
       when is_binary(selected_timezone) and selected_timezone != "" do
    if Enum.any?(options, fn {_label, timezone} -> timezone == selected_timezone end) do
      options
    else
      [{timezone_label(selected_timezone), selected_timezone} | options]
    end
  end

  defp include_selected_timezone(options, _selected_timezone), do: options

  defp timezone_label(timezone) do
    Algora.Time.friendly_timezone(timezone)
  rescue
    _ -> timezone
  end
end
