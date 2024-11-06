defmodule Algora.Github.Client do
  alias Joken

  @type token :: String.t()

  def http(host, method, path, _query, headers, body \\ "") do
    cache_path = ".local/github/#{path}.json"
    url = "https://#{host}#{path}"
    dbg(url)

    case read_from_cache(cache_path) do
      {:ok, cached_data} ->
        {:ok, cached_data}

      :error ->
        headers = [{"Content-Type", "application/json"} | headers]
        request = Finch.build(method, url, headers, body)

        case Finch.request(request, finch_client()) do
          {:ok, %Finch.Response{status: 200, body: body}} ->
            decoded_body = Jason.decode!(body)
            write_to_cache(cache_path, decoded_body)
            {:ok, decoded_body}

          {:ok, %Finch.Response{body: body}} ->
            {:ok, Jason.decode!(body)}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp read_from_cache(cache_path) do
    if File.exists?(cache_path) do
      case File.read(cache_path) do
        {:ok, content} -> Jason.decode(content)
        {:error, _} -> :error
      end
    else
      :error
    end
  end

  defp write_to_cache(cache_path, data) do
    File.mkdir_p!(Path.dirname(cache_path))
    File.write!(cache_path, Jason.encode!(data))
  end

  def fetch(access_token, url, method \\ "GET")

  def fetch(access_token, "https://api.github.com" <> path, method),
    do: fetch(access_token, path, method)

  def fetch(access_token, path, method) do
    http("api.github.com", method, path, [], [
      {"accept", "application/vnd.github.v3+json"},
      {"Authorization", "Bearer #{access_token}"}
    ])
  end

  defp finch_client do
    Application.get_env(:algora, :finch_adapter, Finch)
  end
end
