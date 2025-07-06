defmodule AlgoraWeb.OGImageController do
  use AlgoraWeb, :controller

  alias Algora.Organizations
  alias Algora.ScreenshotQueue

  require Logger

  @opts [type: "png", width: 1200, height: 630, scale_factor: 1]

  defp max_age(path) do
    case path do
      ["go" | _] -> 2_147_483_648
      [_, "jobs" | _] -> 2_629_800
      _ -> Algora.config([AlgoraWeb.OGImageController, :max_age])
    end
  end

  def generate(conn, %{"path" => ["go", repo_owner, repo_name] = path} = params) do
    object_path = Path.join(["og"] ++ path ++ ["og.png"])
    url = Path.join(Algora.S3.bucket_url(), object_path)

    res =
      case :get |> Finch.build(url) |> Finch.request(Algora.Finch) do
        {:ok, %Finch.Response{status: status, body: body, headers: headers}} when status in 200..299 ->
          if should_regenerate?(params, headers) do
            :regenerate
          else
            {:ready,
             conn
             |> put_resp_content_type("image/png")
             |> put_resp_header("cache-control", "public, max-age=#{max_age(path)}")
             |> send_resp(200, body)}
          end

        _error ->
          :regenerate
      end

    case res do
      :regenerate ->
        case Organizations.init_preview(repo_owner, repo_name) do
          {:ok, %{user: user, org: org}} ->
            token =
              Phoenix.Token.encrypt(AlgoraWeb.Endpoint, Algora.config([:local_store, :salt]), %{
                user_id: user.id,
                org_id: org.id
              })

            case take_and_upload_screenshot(path, "?token=#{token}") do
              {:ok, body} ->
                conn
                |> put_resp_content_type("image/png")
                |> put_resp_header("cache-control", "public, max-age=#{max_age(path)}")
                |> send_resp(200, body)

              {:error, reason} ->
                handle_error(conn, path, reason)
            end

          {:error, reason} ->
            handle_error(conn, path, reason)
        end

      {:ready, conn} ->
        conn
    end
  end

  def generate(conn, %{"path" => path} = params) do
    object_path = Path.join(["og"] ++ path ++ ["og.png"])
    url = Path.join(Algora.S3.bucket_url(), object_path)

    case :get |> Finch.build(url) |> Finch.request(Algora.Finch) do
      {:ok, %Finch.Response{status: status, body: body, headers: headers}} when status in 200..299 ->
        if should_regenerate?(params, headers) do
          case take_and_upload_screenshot(path) do
            {:ok, body} ->
              conn
              |> put_resp_content_type("image/png")
              |> put_resp_header("cache-control", "public, max-age=#{max_age(path)}")
              |> send_resp(200, body)

            {:error, reason} ->
              handle_error(conn, path, reason)
          end
        else
          conn
          |> put_resp_content_type("image/png")
          |> put_resp_header("cache-control", "public, max-age=#{max_age(path)}")
          |> send_resp(200, body)
        end

      _error ->
        case take_and_upload_screenshot(path) do
          {:ok, body} ->
            conn
            |> put_resp_content_type("image/png")
            |> put_resp_header("cache-control", "public, max-age=#{max_age(path)}")
            |> send_resp(200, body)

          {:error, reason} ->
            handle_error(conn, path, reason)
        end
    end
  end

  defp should_regenerate?(params, _headers) when is_map_key(params, "refresh"), do: true

  defp should_regenerate?(%{"path" => path}, headers) do
    case List.keyfind(headers, "last-modified", 0) do
      {_, last_modified} ->
        case DateTime.from_iso8601(convert_to_iso8601(last_modified)) do
          {:ok, modified_at, _} ->
            DateTime.diff(DateTime.utc_now(), modified_at, :second) > max_age(path)

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

  def take_and_upload_screenshot(path, params \\ "", opts \\ []) do
    clean_path = Enum.map(path, &(&1 |> String.split("?", parts: 2) |> List.first()))
    dir = Path.join([System.tmp_dir!(), "og"] ++ clean_path)
    File.mkdir_p!(dir)
    filepath = Path.join(dir, "og.png")

    params =
      if params == "" do
        "?screenshot"
      else
        params <> "&screenshot"
      end

    url = Path.join([AlgoraWeb.Endpoint.url() | path]) <> params
    object_path = Path.join(["og"] ++ path ++ ["og.png"])
    caller_pid = Keyword.get(opts, :notify_pid)

    case ScreenshotQueue.generate_image(url, @opts |> Keyword.put(:path, filepath) |> Keyword.merge(opts)) do
      {:ok, _log} ->
        case File.read(filepath) do
          {:ok, body} ->
            Task.start(fn ->
              result = Algora.S3.upload(body, object_path,
                content_type: "image/png",
                cache_control: "public, max-age=#{max_age(path)}"
              )

              if caller_pid do
                send(caller_pid, {:screenshot_upload_complete, object_path, result})
              end

              File.rm(filepath)
            end)

            {:ok, body}

          error ->
            if caller_pid do
              send(caller_pid, {:screenshot_upload_complete, object_path, error})
            end
            File.rm(filepath)
            error
        end

      error ->
        if caller_pid do
          send(caller_pid, {:screenshot_upload_complete, object_path, error})
        end
        error
    end
  end
end
