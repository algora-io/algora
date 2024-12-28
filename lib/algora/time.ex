defmodule Algora.Time do
  @doc """
  Converts an IANA timezone to a friendly display format with proper offset handling.
  Examples:
    "America/New_York" -> "(GMT-05:00) New York"
    "Europe/Paris" -> "(GMT+01:00) Paris"
  """
  def friendly_timezone(nil), do: nil

  def friendly_timezone(timezone) do
    with datetime <- DateTime.now!(timezone),
         offset_hours = div(datetime.utc_offset, 3600),
         offset_mins = div(rem(datetime.utc_offset, 3600), 60),
         offset_string <- format_offset(offset_hours, offset_mins),
         city <- format_city(timezone) do
      "(#{offset_string}) #{city}"
    end
  end

  defp format_offset(hours, mins) do
    sign = if hours >= 0, do: "+", else: "-"
    "GMT#{sign}#{pad_number(abs(hours))}:#{pad_number(abs(mins))}"
  end

  defp pad_number(num), do: String.pad_leading("#{num}", 2, "0")

  defp format_city(timezone) do
    timezone
    |> String.split("/")
    |> List.last()
    |> String.replace("_", " ")
    |> String.replace(~r/^(?:GMT|UTC|Universal|Zulu|WET|UCT)$/, "UTC")
  end

  @doc """
  Returns a sorted, deduplicated list of all timezones in friendly format.
  Sorts by UTC offset first, then alphabetically by city name.
  """
  def list_friendly_timezones do
    Tzdata.zone_list()
    |> Enum.reject(&String.starts_with?(&1, "Etc/GMT"))
    |> Enum.map(fn zone -> {zone, DateTime.now!(zone)} end)
    |> Enum.sort_by(fn {zone, dt} ->
      {
        dt.utc_offset,
        zone |> String.split("/") |> List.last() |> String.downcase()
      }
    end)
    |> Enum.map(fn {zone, _} -> {friendly_timezone(zone), zone} end)
    |> Enum.uniq_by(fn {zone, _} -> zone end)
  end
end
