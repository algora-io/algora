defmodule Algora.Util do
  def random_string do
    binary = <<
      System.system_time(:nanosecond)::64,
      :erlang.phash2({node(), self()})::16,
      :erlang.unique_integer()::16
    >>

    binary
    |> Base.url_encode64()
    |> String.replace(["/", "+"], "-")
  end

  def time_ago(datetime) do
    now = NaiveDateTime.utc_now()
    diff = NaiveDateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)} minutes ago"
      diff < 86_400 -> "#{div(diff, 3600)} hours ago"
      diff < 2_592_000 -> "#{div(diff, 86_400)} days ago"
      true -> "#{div(diff, 2_592_000)} months ago"
    end
  end

  def timestamp(date, nil) do
    date |> Calendar.strftime("%Y-%m-%d %I:%M %p UTC")
  end

  def timestamp(date, timezone) do
    date |> DateTime.shift_zone!(timezone) |> Calendar.strftime("%Y-%m-%d %I:%M %p")
  end

  def format_pct(percentage) do
    percentage
    |> Decimal.mult(100)
    |> Decimal.to_string()
    |> String.trim_trailing("0")
    |> String.trim_trailing(".")
    |> Kernel.<>("%")
  end

  def normalize_struct(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> normalize_struct()
  end

  def normalize_struct(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, normalize_struct(v)} end)
  end

  def normalize_struct(list) when is_list(list) do
    Enum.map(list, &normalize_struct/1)
  end

  def normalize_struct(value), do: value

  # TODO: Implement this for all countries
  def locale_from_country_code("gr"), do: "el"
  def locale_from_country_code(country_code), do: country_code
end
