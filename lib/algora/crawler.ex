defmodule Algora.Crawler do
  require Logger

  @user_agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
  @max_redirects 5

  def fetch_site_metadata(url, redirect_count \\ 0) do
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
                 description: find_description(html_tree),
                 socials: find_social_links(html_tree)
               }}

            error ->
              Logger.error("Failed to parse HTML from #{url}: #{inspect(error)}")
              {:error, :parse_failed}
          end

        {:redirect, new_url} ->
          fetch_site_metadata(new_url, redirect_count + 1)

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

  def fetch_user_metadata(email, opts \\ []) do
    domain = get_email_domain(email)
    gravatar_url = get_gravatar_url(email, opts)

    case fetch_site_metadata("https://#{domain}") do
      {:ok, metadata} ->
        {:ok, Map.put(metadata, :gravatar_url, gravatar_url)}

      {:error, reason} ->
        # Still return gravatar even if site metadata fails
        {:ok, %{gravatar_url: gravatar_url}}
    end
  end

  defp handle_response(
         %Finch.Response{status: status, headers: headers, body: _body},
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
      |> maybe_trim()

    html_title =
      html_tree
      |> Floki.find("title")
      |> Floki.text()
      |> maybe_trim()

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
      |> maybe_trim()
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
        [{element, _} | _] ->
          get_logo_url([element])

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

  defp maybe_trim(nil), do: nil

  defp maybe_trim(string) do
    string
    |> String.trim()
    |> String.split()
    |> Enum.join(" ")
  end

  defp find_social_links(html_tree) do
    %{
      twitter: find_social_url(html_tree, :twitter),
      discord: find_social_url(html_tree, :discord),
      github: find_social_url(html_tree, :github),
      instagram: find_social_url(html_tree, :instagram),
      youtube: find_social_url(html_tree, :youtube),
      producthunt: find_social_url(html_tree, :producthunt),
      hackernews: find_social_url(html_tree, :hackernews),
      slack: find_social_url(html_tree, :slack),
      linkedin: find_social_url(html_tree, :linkedin)
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  @social_selectors %{
    twitter: [
      ~s|meta[name="twitter:url"]|,
      ~s|meta[name="twitter:site"]|,
      ~s|a[href*="twitter.com"]|,
      ~s|a[href*="x.com"]|,
      ~s|a[aria-label*="Twitter" i], a:has([aria-label*="Twitter" i])|
    ],
    discord: [
      ~s|a[href*="discord.gg"]|,
      ~s|a[href*="discord.com/invite"]|,
      ~s|a[aria-label*="Discord" i], a:has([aria-label*="Discord" i])|,
      ~s|a[href*="discord"]|
    ],
    github: [
      ~s|a[href*="github.com"]|,
      ~s|a[aria-label*="GitHub" i], a:has([aria-label*="GitHub" i])|,
      ~s|a[href*="github"]|
    ],
    instagram: [
      ~s|a[href*="instagram.com"]|,
      ~s|a[aria-label*="Instagram" i], a:has([aria-label*="Instagram" i])|
    ],
    youtube: [
      ~s|a[href*="youtube.com"]|,
      ~s|a[href*="youtu.be"]|,
      ~s|a[aria-label*="YouTube" i], a:has([aria-label*="YouTube" i])|
    ],
    producthunt: [
      ~s|a[href*="producthunt.com"]|,
      ~s|a[aria-label*="Product Hunt" i], a:has([aria-label*="Product Hunt" i])|,
      ~s|a[aria-label*="ProductHunt" i], a:has([aria-label*="ProductHunt" i])|
    ],
    hackernews: [
      ~s|a[href*="news.ycombinator.com"]|,
      ~s|a[href*="ycombinator.com"]|,
      ~s|a[aria-label*="Hacker News" i], a:has([aria-label*="Hacker News" i])|,
      ~s|a[aria-label*="HackerNews" i], a:has([aria-label*="HackerNews" i])|
    ],
    slack: [
      ~s|a[href*="slack.com/join"]|,
      ~s|a[href*="slack.com/shared_invite"]|,
      ~s|a[aria-label*="Slack" i], a:has([aria-label*="Slack" i])|
    ],
    linkedin: [
      ~s|a[href*="linkedin.com"]|,
      ~s|a[aria-label*="LinkedIn" i], a:has([aria-label*="LinkedIn" i])|
    ]
  }

  defp find_social_url(html_tree, platform) do
    selectors = @social_selectors[platform]

    Enum.find_value(selectors, fn selector ->
      elements = Floki.find(html_tree, selector)

      case platform do
        :twitter ->
          handle_twitter_url(elements)

        _ ->
          get_href_or_nil(elements)
      end
    end)
  end

  defp handle_twitter_url([]), do: nil

  defp handle_twitter_url([element | _]) do
    content = get_content_or_nil([element])
    href = get_href_or_nil([element])

    cond do
      content && String.starts_with?(content, "@") ->
        "https://twitter.com/#{String.trim_leading(content, "@")}"

      href ->
        href

      true ->
        nil
    end
  end

  defp get_href_or_nil([]), do: nil

  defp get_href_or_nil([element | _]) do
    Floki.attribute(element, "href")
    |> List.first()
  end

  defp get_email_domain(email) do
    [_, domain] = String.split(email, "@")
    domain
  end

  defp get_gravatar_url(email, opts) do
    default = Keyword.get(opts, :default, "")
    size = Keyword.get(opts, :size, 460)

    email
    |> String.trim()
    |> String.downcase()
    |> (&:crypto.hash(:sha256, &1)).()
    |> Base.encode16(case: :lower)
    |> build_gravatar_url(default, size)
  end

  defp build_gravatar_url(hash, default, size) do
    query =
      URI.encode_query(%{
        "d" => default,
        "s" => Integer.to_string(size)
      })

    "https://www.gravatar.com/avatar/#{hash}?#{query}"
  end
end
