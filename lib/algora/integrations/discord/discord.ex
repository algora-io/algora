defmodule Algora.Discord do
  @moduledoc """
  Discord integration for Algora.

  Provides functionality to send messages to Discord channels.
  """

  alias Algora.Discord.Client

  require Logger

  defdelegate webhook_url, to: Client

  @doc """
  Sends a message to a Discord channel.

  ## Parameters

  * `content` - The message content (optional)
  * `embeds` - List of embeds to include in the message (optional)

  ## Examples

      iex> Discord.send_message(%{content: "Hello, world!"})
      {:ok, response}

      iex> Discord.send_message(%{
      ...>   embeds: [
      ...>     %{
      ...>       color: 0x6366f1,
      ...>       title: "New Bounty Created",
      ...>       author: %{
      ...>         name: "Organization Name",
      ...>         icon_url: "https://example.com/avatar.png",
      ...>         url: "https://example.com/org"
      ...>       },
      ...>       url: "https://github.com/repo/issues/1",
      ...>       timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      ...>     }
      ...>   ]
      ...> })
      {:ok, response}
  """
  @spec send_message(map()) :: {:ok, map() | nil} | {:error, any()}
  def send_message(input) do
    input =
      Map.merge(
        %{username: "Algora.io", avatar_url: "https://algora.io/asset/storage/v1/object/public/images/logo-256px.png"},
        input
      )

    case Client.post(input) do
      {:ok, response} ->
        {:ok, response}

      {:error, reason} = error ->
        Logger.error("Could not send Discord message: #{inspect(reason)}, input: #{inspect(input)}")
        error
    end
  end
end
