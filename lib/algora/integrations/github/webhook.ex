defmodule Algora.Github.Webhook do
  @moduledoc false
  require Logger

  @enforce_keys [
    # Webhook headers
    :hook_id,
    :event,
    :delivery,
    :signature,
    :signature_256,
    :user_agent,
    :installation_target_type,
    :installation_target_id,
    # Webhook payload
    :payload,
    # Convenience fields
    :event_action,
    :body,
    :author
  ]

  defstruct @enforce_keys

  def new(conn) do
    secret = Algora.Github.webhook_secret()

    with {:ok, headers} <- parse_headers(conn),
         {:ok, payload, conn} = Plug.Conn.read_body(conn),
         {:ok, _} <- verify_signature(headers.signature_256, payload, secret),
         {:ok, webhook} <- build_webhook(headers, payload) do
      {:ok, webhook, conn}
    end
  end

  defp build_webhook(headers, payload) do
    params =
      headers
      |> Map.put(:payload, payload)
      |> Map.put(:event_action, headers[:event] <> "." <> payload["action"])
      |> Map.put(:body, get_body(headers[:event], payload))
      |> Map.put(:author, get_author(headers[:event], payload))

    {:ok, struct!(__MODULE__, params)}
  rescue
    error ->
      {:error, error}
  end

  defp parse_headers(conn) do
    required_headers = [
      {"x-github-hook-id", :hook_id},
      {"x-github-event", :event},
      {"x-github-delivery", :delivery},
      {"x-hub-signature", :signature},
      {"x-hub-signature-256", :signature_256},
      {"user-agent", :user_agent},
      {"x-github-hook-installation-target-type", :installation_target_type},
      {"x-github-hook-installation-target-id", :installation_target_id}
    ]

    headers = Enum.map(required_headers, fn {header, key} -> {key, get_header(conn, header)} end)

    case Enum.find(headers, fn {_, value} -> is_nil(value) end) do
      {_key, nil} -> {:error, :missing_header}
      nil -> {:ok, Map.new(headers)}
    end
  end

  def verify_signature(signature, payload, secret) do
    sig = generate_signature(payload, secret)

    if Plug.Crypto.secure_compare("sha256=" <> sig, signature) do
      {:ok, nil}
    else
      {:error, :signature_mismatch}
    end
  end

  defp generate_signature(payload, secret) do
    :hmac |> :crypto.mac(:sha256, secret, payload) |> Base.encode16(case: :lower)
  end

  defp get_header(conn, header) do
    conn |> Plug.Conn.get_req_header(header) |> List.first()
  end

  def entity_key("issues"), do: "issue"
  def entity_key("issue_comment"), do: "comment"
  def entity_key("pull_request"), do: "pull_request"
  def entity_key("pull_request_review"), do: "review"
  def entity_key("pull_request_review_comment"), do: "comment"
  def entity_key(_event), do: nil

  defp get_author(event, payload), do: get_in(payload, ["#{entity_key(event)}", "user"])
  defp get_body(event, payload), do: get_in(payload, ["#{entity_key(event)}", "body"])
end
