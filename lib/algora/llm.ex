defmodule Algora.LLM do
  @moduledoc false
  def chat(prompt, opts \\ []) do
    body = Map.merge(%{input: %{prompt: prompt}}, Map.new(opts))

    case make_request(:post, "/v1/models/anthropic/claude-3.5-sonnet/predictions", body, opts) do
      {:ok, %{"urls" => %{"get" => get_url}}} -> poll_prediction(get_url)
      error -> error
    end
  end

  defp poll_prediction(url) do
    case make_request(:get, url, nil, []) do
      {:ok, %{"status" => "succeeded", "output" => output}} ->
        {:ok, Enum.join(output, "")}

      {:ok, %{"status" => "failed", "error" => error}} ->
        {:error, error}

      {:ok, %{"status" => status}} when status in ["starting", "processing"] ->
        Process.sleep(1000)
        poll_prediction(url)

      error ->
        error
    end
  end

  defp api_key do
    System.get_env("REPLICATE_API_KEY")
  end

  defp make_request(method, url, body, _opts) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{api_key()}"}
    ]

    body_json = if body, do: Jason.encode!(body)

    method
    |> Finch.build(url_for(url), headers, body_json)
    |> Finch.request(Algora.Finch)
    |> handle_response()
  end

  defp url_for(url) do
    if String.starts_with?(url, "http") do
      url
    else
      "https://api.replicate.com#{url}"
    end
  end

  defp handle_response({:ok, response}) do
    case response.status do
      status when status in 200..299 ->
        body = Jason.decode!(response.body)
        {:ok, body}

      _ ->
        {:error, "Request failed with status #{response.status}: #{response.body}"}
    end
  end

  defp handle_response({:error, error}) do
    {:error, "Request failed: #{inspect(error)}"}
  end
end
