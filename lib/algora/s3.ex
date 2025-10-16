defmodule Algora.S3 do
  @moduledoc false

  def bucket_name, do: Algora.config([:bucket_name])

  def bucket_url, do: "#{AlgoraWeb.Endpoint.url()}/storage"

  def bucket_url(path), do: Path.join(bucket_url(), path)

  def upload(body, object, opts \\ []) do
    bucket_name()
    |> ExAws.S3.put_object(object, body, opts)
    |> ExAws.request([])
  end
end
