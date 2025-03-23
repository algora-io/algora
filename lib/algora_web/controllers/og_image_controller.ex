defmodule AlgoraWeb.OGImageController do
  use AlgoraWeb, :controller

  require Logger

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

    opts = [
      type: "png",
      path: filepath,
      width: 1200,
      height: 630,
      scale_factor: 2,
      timeout: 10_000
    ]

    case generate_image(url, opts) do
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

  @doc """
    Wrapper for puppeteer-img.  Generates screenshots of a website from given URL.
    Adapted from https://github.com/RobotsAndPencils/ex-puppeteer-img
  """
  def generate_image(url, options \\ []) do
    opts =
      options
      |> Keyword.take([:type, :path, :width, :height, :scale_factor, :timeout])
      |> Enum.reduce([url], fn {key, value}, result ->
        result ++ [String.replace("--#{key}=#{value}", "_", "-")]
      end)

    try do
      task =
        Task.async(fn ->
          try do
            case System.cmd("puppeteer-img", opts) do
              {_, 127} ->
                {:error, :invalid_exec_path}

              {cmd_response, _} ->
                {:ok, cmd_response}
            end
          rescue
            e in ErlangError ->
              %ErlangError{original: error} = e

              case error do
                :enoent ->
                  # This will happen when the file in exec_path doesn't exists
                  {:error, :invalid_exec_path}
              end
          end
        end)

      Task.await(task, options[:timeout] || 2000)
    catch
      :exit, {:timeout, _} -> {:error, :timeout}
    end
  end
end
