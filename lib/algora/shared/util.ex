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
    |> Plug.Crypto.non_executable_binary_to_term([:safe])
  end

  def format_number_compact(number) when is_struct(number, Decimal) do
    number
    |> Decimal.to_float()
    |> format_number_compact()
  end

  def format_number_compact(number) do
    n = trunc(number)

    case n do
      n when n >= 1_000_000 ->
        "#{(n / 1_000_000) |> Float.round(1) |> trim_trailing_zero()}M"

      n when n >= 1_000 ->
        "#{(n / 1_000) |> Float.round(1) |> trim_trailing_zero()}K"

      n ->
        to_string(n)
    end
  end

  defp trim_trailing_zero(number) do
    number
    |> Float.to_string()
    |> String.replace(~r/\.0+$/, "")
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

  def format_pct(percentage, opts \\ []) do
    pct = percentage |> Decimal.mult(100) |> Decimal.normalize()

    pct =
      if opts[:precision] do
        Decimal.round(pct, opts[:precision])
      else
        pct
      end

    pct |> Decimal.to_string(:normal) |> Kernel.<>("%")
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

  def normalize_url(nil), do: nil

  def normalize_url(url) when is_binary(url) do
    url = String.trim(url)

    # Add https:// if no scheme present
    url = if String.contains?(url, "://"), do: url, else: "https://" <> url

    case URI.parse(url) do
      %URI{scheme: scheme, host: host} when not is_nil(scheme) and scheme != "" and not is_nil(host) and host != "" -> url
      _ -> nil
    end
  end

  def to_domain(nil), do: nil

  def to_domain(url) do
    url
    |> String.trim_leading("https://")
    |> String.trim_leading("http://")
    |> String.trim_leading("www.")
  end

  def get_gravatar_url(email, opts \\ []) do
    default = Keyword.get(opts, :default, "")
    size = Keyword.get(opts, :size, 460)

    email
    |> String.trim()
    |> String.downcase()
    |> remove_plus_suffix()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
    |> build_gravatar_url(default, size)
  end

  defp remove_plus_suffix(email) do
    [local_part, domain] = String.split(email, "@")
    base_local_part = local_part |> String.split("+") |> List.first()
    base_local_part <> "@" <> domain
  end

  defp build_gravatar_url(hash, default, size) do
    query =
      URI.encode_query(%{
        "d" => default,
        "s" => Integer.to_string(size)
      })

    "https://www.gravatar.com/avatar/#{hash}?#{query}&d=identicon"
  end

  def normalized_strings_match?(s1, s2) do
    s1 = s1 |> String.downcase() |> String.trim() |> String.replace(~r/[^a-zA-Z0-9]+/, "")
    s2 = s2 |> String.downcase() |> String.trim() |> String.replace(~r/[^a-zA-Z0-9]+/, "")

    String.contains?(s1, s2) or String.contains?(s2, s1)
  end

  def next_occurrence_of_time(datetime) do
    now = DateTime.utc_now()

    if DateTime.after?(datetime, now) do
      datetime
    else
      %{hour: hour, minute: minute, second: second, microsecond: microsecond} = datetime

      now
      |> DateTime.truncate(:second)
      |> Map.put(:hour, hour)
      |> Map.put(:minute, minute)
      |> Map.put(:second, second)
      |> Map.put(:microsecond, microsecond)
      |> then(fn target_time ->
        if DateTime.after?(target_time, now) do
          target_time
        else
          DateTime.add(target_time, 24 * 60 * 60, :second)
        end
      end)
    end
  end

  def random_datetime(opts \\ []) do
    now = DateTime.utc_now()
    from = Keyword.get(opts, :from, DateTime.add(now, -365, :day))
    to = Keyword.get(opts, :to, now)

    from_unix = DateTime.to_unix(from)
    to_unix = DateTime.to_unix(to)

    from_unix..to_unix
    |> Enum.random()
    |> DateTime.from_unix!()
  end

  def compact_org_name(org_name) do
    org_name
    # Remove YC batch strings like "YC S24", "YC W23", etc.
    |> String.replace(~r/\s*\(?YC\s+[a-z]\d{2}\)?\s*/i, "")
    # Remove common company suffixes
    |> String.replace(
      ~r/,?\s+(PBC\.?|Public Benefit Corporation|Corporation|Corp\.?|,?\s*Inc\.?|Labs|Technologies|Industries|Research)\s*$/i,
      ""
    )
    |> String.trim()
  end
end
