defmodule AlgoraWeb.OGImageController do
  use AlgoraWeb, :controller

  alias Algora.ScreenshotQueue

  require Logger

  @opts [type: "png", width: 1200, height: 630, scale_factor: 1]

  def generate(conn, %{"path" => path}) do
    case take_and_upload_screenshot(path) do
      {:ok, s3_url} ->
        redirect(conn, external: s3_url)

      {:error, reason} ->
        Logger.error("Failed to generate OG image for #{inspect(path)}: #{inspect(reason)}")
        conn |> put_status(:not_found) |> text("Not found")
    end
  end

  defp take_and_upload_screenshot(path) do
    dir = Path.join([System.tmp_dir!(), "og"] ++ path)
    File.mkdir_p!(dir)

    filepath = Path.join(dir, "og.png")
    url = url(~p"/#{path}?screenshot")

    case ScreenshotQueue.generate_image(url, Keyword.put(@opts, :path, filepath)) do
      {:ok, _path} ->
        object_path = Path.join(["og"] ++ path ++ ["og.png"])

        with {:ok, file_contents} <- File.read(filepath),
             {:ok, _} <- Algora.S3.upload(file_contents, object_path, content_type: "image/png") do
          File.rm(filepath)
          {:ok, Path.join(Algora.S3.bucket_url(), object_path)}
        else
          error ->
            File.rm(filepath)
            error
        end

      error ->
        error
    end
  end
end
