defmodule Algora.Crawler do
  require Logger

  @user_agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
  @max_redirects 5

  def fetch_metadata(url, redirect_count \\ 0) do
    request = Finch.build(:get, url, [{"User-Agent", @user_agent}])

    with {:ok, response} <- Finch.request(request, Algora.Finch) do
      case handle_response(response, url, redirect_count) do
        {:ok, body} ->
          case Floki.parse_document(body) do
            {:ok, html_tree} ->
              {:ok,
               %{
                 og_image: find_og_image(html_tree),
                 logo: find_logo(html_tree, url),
                 title: find_title(html_tree),
                 description: find_description(html_tree)
               }}

            error ->
              Logger.error("Failed to parse HTML from #{url}: #{inspect(error)}")
              {:error, :parse_failed}
          end

        {:redirect, new_url} ->
          fetch_metadata(new_url, redirect_count + 1)

        {:error, reason} ->
          Logger.error("Failed to fetch metadata from #{url}: #{inspect(reason)}")
          {:error, reason}
      end
    else
      error ->
        Logger.error("Failed to fetch metadata from #{url}: #{inspect(error)}")
        {:error, :request_failed}
    end
  end

  defp handle_response(
         %Finch.Response{status: status, headers: headers, body: body},
         url,
         redirect_count
       )
       when status in [301, 302, 303, 307, 308] do
    if redirect_count >= @max_redirects do
      {:error, :too_many_redirects}
    else
      case List.keyfind(headers, "location", 0) do
        {_, location} -> {:redirect, make_absolute_url(location, url)}
        nil -> {:error, :missing_redirect_location}
      end
    end
  end

  defp handle_response(%Finch.Response{status: 200, body: body}, _url, _redirect_count) do
    {:ok, body}
  end

  defp handle_response(%Finch.Response{status: status}, _url, _redirect_count) do
    {:error, "Unexpected status code: #{status}"}
  end

  defp find_og_image(html_tree) do
    # Try multiple OG image meta tags
    og_tags = [
      ~s|meta[property="og:image"]|,
      ~s|meta[property="og:image:url"]|,
      ~s|meta[property="og:image:secure_url"]|,
      ~s|meta[name="twitter:image"]|
    ]

    Enum.find_value(og_tags, fn selector ->
      html_tree
      |> Floki.find(selector)
      |> get_content_or_nil()
    end)
  end

  defp find_title(html_tree) do
    # Try meta title first, then fallback to HTML title tag
    meta_title =
      html_tree
      |> Floki.find(~s|meta[property="og:title"]|)
      |> get_content_or_nil()

    html_title =
      html_tree
      |> Floki.find("title")
      |> Floki.text()
      |> case do
        "" -> nil
        text -> text
      end

    meta_title || html_title
  end

  defp find_description(html_tree) do
    # Try multiple description meta tags
    description_tags = [
      ~s|meta[property="og:description"]|,
      ~s|meta[name="description"]|,
      ~s|meta[name="twitter:description"]|
    ]

    Enum.find_value(description_tags, fn selector ->
      html_tree
      |> Floki.find(selector)
      |> get_content_or_nil()
    end)
  end

  defp find_logo(html_tree, base_url) do
    # First find all icon links and parse their sizes
    icons_with_sizes =
      html_tree
      |> Floki.find("link[rel~=icon], link[rel~=apple-touch-icon]")
      |> Enum.map(fn element ->
        {
          element,
          get_size_in_pixels(Floki.attribute(element, "sizes") |> List.first())
        }
      end)
      |> Enum.sort_by(fn {_, size} -> size end, :desc)

    # Then try logo images
    logo_selectors = [
      ~s|link[rel="logo"]|,
      ~s|img[alt*="logo" i]|,
      ~s|img[src*="logo" i]|
    ]

    logo_url =
      case icons_with_sizes do
        # If we found icons with sizes, use the largest one
        [{element, _} | _] -> get_logo_url([element])
        # Otherwise try the logo selectors
        [] ->
          Enum.find_value(logo_selectors, fn selector ->
            html_tree
            |> Floki.find(selector)
            |> get_logo_url()
          end)
      end

    case logo_url do
      nil -> nil
      url -> make_absolute_url(url, base_url)
    end
  end

  defp get_size_in_pixels(nil), do: 0
  defp get_size_in_pixels(sizes) do
    sizes
    |> String.split(" ")
    |> Enum.map(fn size ->
      case String.split(size, "x") do
        [width, _height] -> String.to_integer(width)
        _ -> 0
      end
    end)
    |> Enum.max(fn -> 0 end)
  end

  defp get_content_or_nil([]), do: nil

  defp get_content_or_nil([element | _]) do
    Floki.attribute(element, "content")
    |> List.first()
  end

  defp get_logo_url([]), do: nil

  defp get_logo_url([element | _]) do
    Floki.attribute(element, "href")
    |> List.first()
    |> case do
      nil -> Floki.attribute(element, "src") |> List.first()
      href -> href
    end
  end

  defp make_absolute_url(nil, _base_url), do: nil

  defp make_absolute_url(url, base_url) do
    uri = URI.parse(url)
    base_uri = URI.parse(base_url)

    case uri do
      %URI{host: nil, scheme: nil} ->
        # Relative URL
        if String.starts_with?(url, "/") do
          "#{base_uri.scheme}://#{base_uri.host}#{url}"
        else
          Path.join([base_uri.scheme <> "://" <> base_uri.host, url])
        end

      _ ->
        url
    end
  end
end
