defmodule AlgoraWeb.OGImageController do
  use AlgoraWeb, :controller

  alias Algora.ScreenshotQueue

  require Logger

  @opts [type: "png", width: 1200, height: 630, scale_factor: 1]

  @max_age 600

  def generate(conn, %{"path" => path}) do
    object_path = Path.join(["og"] ++ path ++ ["og.png"])
    url = Path.join(Algora.S3.bucket_url(), object_path)

    case :get |> Finch.build(url) |> Finch.request(Algora.Finch) do
      {:ok, %Finch.Response{status: status, body: body, headers: headers}} when status in 200..299 ->
        if should_regenerate?(headers) do
          case take_and_upload_screenshot(path) do
            {:ok, body} ->
              conn
              |> put_resp_content_type("image/png")
              |> send_resp(200, body)

            {:error, reason} ->
              handle_error(conn, path, reason)
          end
        else
          conn
          |> put_resp_content_type("image/png")
          |> send_resp(200, body)
        end

      _error ->
        case take_and_upload_screenshot(path) do
          {:ok, body} ->
            conn
            |> put_resp_content_type("image/png")
            |> send_resp(200, body)

          {:error, reason} ->
            handle_error(conn, path, reason)
        end
    end
  end

  defp should_regenerate?(headers) do
    case List.keyfind(headers, "last-modified", 0) do
      {_, last_modified} ->
        case DateTime.from_iso8601(convert_to_iso8601(last_modified)) do
          {:ok, modified_at, _} ->
            DateTime.diff(DateTime.utc_now(), modified_at, :second) > @max_age

          _error ->
            true
        end

      nil ->
        true
    end
  end

  defp convert_to_iso8601(http_date) do
    # Convert HTTP date format to ISO8601
    {:ok, datetime} = Timex.parse(http_date, "{RFC1123}")
    DateTime.to_iso8601(datetime)
  end

  defp handle_error(conn, path, reason) do
    Logger.error("Failed to generate OG image for #{inspect(path)}: #{inspect(reason)}")
    conn |> put_status(:not_found) |> text("Not found")
  end

  def take_and_upload_screenshot(path) do
    dir = Path.join([System.tmp_dir!(), "og"] ++ path)
    File.mkdir_p!(dir)
    filepath = Path.join(dir, "og.png")
    url = url(~p"/#{path}?screenshot")

    case ScreenshotQueue.generate_image(url, Keyword.put(@opts, :path, filepath)) do
      {:ok, _path} ->
        object_path = Path.join(["og"] ++ path ++ ["og.png"])

        case File.read(filepath) do
          {:ok, body} ->
            Task.start(fn ->
              Algora.S3.upload(body, object_path,
                content_type: "image/png",
                cache_control: "public, max-age=#{@max_age}"
              )

              File.rm(filepath)
            end)

            {:ok, body}

          error ->
            File.rm(filepath)
            error
        end

      error ->
        error
    end
  end
end
