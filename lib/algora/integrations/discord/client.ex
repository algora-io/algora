defmodule Algora.Discord.Client do
  @moduledoc false

  require Logger

  def webhook_url, do: Algora.config([:discord, :webhook_url])

  def post(data) do
    if url = webhook_url() do
      do_post(url, data)
    else
      {:ok, nil}
    end
  end

  defp do_post(url, data) do
    headers = [{"Content-Type", "application/json"}]

    with {:ok, encoded_body} <- Jason.encode(data),
         request = Finch.build("POST", url, headers, encoded_body),
         {:ok, %Finch.Response{status: status}} when status < 300 <- Finch.request(request, Algora.Finch) do
      {:ok, status}
    else
      {:ok, %Finch.Response{status: status}} ->
        Logger.error("Discord API error: #{inspect(status)}")
        {:error, status}

      error ->
        Logger.error("Discord API error: #{inspect(error)}")
        error
    end
  end
end
