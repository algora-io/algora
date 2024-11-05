defmodule Algora.Github.Webhook do
  require Logger

  @enforce_keys [
    :hook_id,
    :event,
    :delivery,
    :signature,
    :signature_256,
    :user_agent,
    :installation_type,
    :installation_id
  ]

  defstruct @enforce_keys

  def new(conn) do
    secret = Algora.Github.webhook_secret()

    with {:ok, headers} <- parse_headers(conn),
         {:ok, payload} <- Jason.encode(conn.params),
         {:ok, _} <- verify_signature(headers.signature_256, payload, secret) do
      {:ok, headers}
    end
  end

  defp parse_headers(conn) do
    required_headers = [
      {"x-github-hook-id", :hook_id},
      {"x-github-event", :event},
      {"x-github-delivery", :delivery},
      {"x-hub-signature", :signature},
      {"x-hub-signature-256", :signature_256},
      {"user-agent", :user_agent},
      {"x-github-hook-installation-target-type", :installation_type},
      {"x-github-hook-installation-target-id", :installation_id}
    ]

    headers =
      Enum.map(required_headers, fn {header, key} -> {key, get_header(conn, header)} end)

    case Enum.find(headers, fn {_, value} -> is_nil(value) end) do
      {_key, nil} ->
        {:error, :missing_header}

      nil ->
        {:ok, struct!(__MODULE__, Map.new(headers))}
    end
  end

  def generate_signature(payload, secret) do
    :hmac
    |> :crypto.mac(:sha256, secret, payload)
    |> Base.encode16(case: :lower)
  end

  def verify_signature(signature, payload, secret) do
    sig = generate_signature(payload, secret)

    case Plug.Crypto.secure_compare("sha256=" <> sig, signature) do
      true -> {:ok, nil}
      false -> {:error, :signature_mismatch}
    end
  end

  defp get_header(conn, header) do
    Plug.Conn.get_req_header(conn, header) |> List.first()
  end
end
