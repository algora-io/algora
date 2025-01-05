defmodule Algora.S3 do
  @moduledoc false

  def endpoint_url do
    config = Application.fetch_env!(:ex_aws, :s3)
    "#{config[:scheme]}#{config[:host]}"
  end

  def bucket_name, do: Algora.config([:bucket_name])

  def bucket_url, do: endpoint_url() <> "/" <> bucket_name()

  def upload(body, object, opts \\ []) do
    bucket_name()
    |> ExAws.S3.put_object(object, body, opts)
    |> ExAws.request([])
  end
end
