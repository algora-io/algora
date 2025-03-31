defmodule Algora.Util do
  @moduledoc false
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

  def random_int(n \\ 1_000_000) do
    :rand.uniform(n)
  end

  def term_to_base64(term) do
    term
    |> :erlang.term_to_binary()
    |> Base.encode64()
  end

  def base64_to_term!(base64) do
    base64
    |> Base.decode64!()
    |> :erlang.binary_to_term()
  end

  def time_ago(datetime) do
    now = NaiveDateTime.utc_now()
    diff = NaiveDateTime.diff(now, datetime, :second)

    cond do
      diff < 60 ->
        "just now"

      diff < 3600 ->
        count = div(diff, 60)
        unit = Gettext.ngettext(AlgoraWeb.Gettext, "minute", "minutes", count)
        "#{count} #{unit} ago"

      diff < 86_400 ->
        count = div(diff, 3600)
        unit = Gettext.ngettext(AlgoraWeb.Gettext, "hour", "hours", count)
        "#{count} #{unit} ago"

      diff < 2_592_000 ->
        count = div(diff, 86_400)
        unit = Gettext.ngettext(AlgoraWeb.Gettext, "day", "days", count)
        "#{count} #{unit} ago"

      true ->
        count = div(diff, 2_592_000)
        unit = Gettext.ngettext(AlgoraWeb.Gettext, "month", "months", count)
        "#{count} #{unit} ago"
    end
  end

  def timestamp(date, nil) do
    Calendar.strftime(date, "%Y-%m-%d %I:%M %p UTC")
  end

  def timestamp(date, timezone) do
    date |> DateTime.shift_zone!(timezone) |> Calendar.strftime("%Y-%m-%d %I:%M %p")
  end

  def to_date!(nil), do: nil

  def to_date!(date) do
    case DateTime.from_iso8601(date) do
      {:ok, datetime, _offset} ->
        %{datetime | microsecond: {elem(datetime.microsecond, 0), 6}}

      {:error, _reason} = error ->
        error
    end
  end

  def format_pct(percentage) do
    percentage
    |> Decimal.mult(100)
    |> Decimal.normalize()
    |> Decimal.to_string(:normal)
    |> Kernel.<>("%")
  end

  def normalize_struct(%Money{} = money) do
    %{
      amount: Decimal.to_string(money.amount),
      currency: money.currency
    }
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

  def normalize_struct(tuple) when is_tuple(tuple) do
    tuple |> Tuple.to_list() |> normalize_struct()
  end

  def normalize_struct(value), do: value

  def format_name_list([x]), do: x
  def format_name_list([x1, x2]), do: "#{x1} and #{x2}"
  def format_name_list([x1, x2, x3]), do: "#{x1}, #{x2} and #{x3}"
  def format_name_list([x1, x2 | xs]), do: "#{x1}, #{x2} and #{length(xs)} others"

  def initials(str, length \\ 2)
  def initials(nil, _length), do: ""
  def initials(str, length), do: str |> String.slice(0, length) |> String.upcase()

  # TODO: Implement this for all countries
  def locale_from_country_code("gr"), do: "el"
  def locale_from_country_code(country_code), do: country_code

  def parse_github_url(url) do
    case Regex.run(~r{(?:github\.com/)?([^/\s]+)/([^/\s]+)}, url) do
      [_, owner, repo] -> {:ok, {owner, repo}}
      _ -> {:error, "Must be a valid GitHub repository URL (e.g. github.com/owner/repo) or owner/repo format"}
    end
  end

  def path_from_url(url) do
    url
    |> URI.parse()
    |> then(& &1.path)
    |> String.replace(~r/^\/[^\/]+\//, "")
    |> String.replace(~r/\/(issues|pull|discussions)\//, "#")
  end
end
