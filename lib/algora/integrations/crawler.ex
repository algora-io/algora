defmodule Algora.Crawler do
  @moduledoc false
  alias Algora.Util

  require Logger

  @user_agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
  @headers [{"User-Agent", @user_agent}]
  @max_redirects 5
  @max_retries 3
  @retry_delay to_timeout(second: 1)
  @blacklist_filename "domain_blacklist.txt"

  def blacklisted?(nil), do: true
  def blacklisted?(""), do: true

  def blacklisted?(domain) do
    :algora
    |> :code.priv_dir()
    |> Path.join(@blacklist_filename)
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Enum.member?(domain)
  end

  def fetch_site_metadata(nil), do: {:error, :blacklisted_domain}
  def fetch_site_metadata(domain), do: fetch_site_metadata("https://#{domain}", 0, 0)

  def fetch_site_metadata(url, redirect_count, retry_count) do
    request = Finch.build(:get, url, @headers)

    case Finch.request(request, Algora.Finch) do
      {:ok, response} ->
        case handle_response(response, url, redirect_count) do
          {:ok, body} ->
            case Floki.parse_document(body) do
              {:ok, html_tree} ->
                metadata = %{
                  og_title: find_title(html_tree),
                  og_description: find_description(html_tree),
                  og_image_url: find_og_image(html_tree),
                  favicon_url: find_logo(html_tree, url),
                  socials: find_social_links(html_tree, url)
                }

                # Enhance metadata with GitHub info if available
                metadata =
                  case get_github_info(url, metadata.socials[:github]) do
                    {:ok, github_info} -> Map.merge(metadata, github_info)
                    _ -> update_in(metadata, [:socials, :github], fn _ -> nil end)
                  end

                metadata
                |> update_in([:socials, :twitter], fn twitter_url ->
                  case get_in(metadata, [:twitter_username]) do
                    nil -> twitter_url
                    username -> "https://x.com/#{username}"
                  end
                end)
                |> Map.delete(:twitter_username)
                |> then(&{:ok, &1})

              error ->
                Logger.error("Failed to parse HTML from #{url}: #{inspect(error)}")
                {:error, :parse_failed}
            end

          {:redirect, new_url} ->
            fetch_site_metadata(new_url, redirect_count + 1, retry_count)

          {:error, reason} ->
            Logger.error("Failed to fetch metadata from #{url}: #{inspect(reason)}")
            {:error, reason}
        end

      error ->
        Logger.error("Failed to fetch metadata from #{url}: #{inspect(error)}")

        if retry_count < @max_retries do
          Process.sleep(@retry_delay)
          fetch_site_metadata(url, redirect_count, retry_count + 1)
        else
          {:error, :request_failed}
        end
    end
  end

  def fetch_user_metadata(email, opts \\ []) do
    domain = get_email_domain(email)
    gravatar_url = Util.get_gravatar_url(email, opts)

    case fetch_site_metadata(domain) do
      {:ok, metadata} ->
        %{avatar_url: gravatar_url, org: metadata}

      {:error, _reason} ->
        %{avatar_url: gravatar_url, org: nil}
    end
  end

  defp handle_response(%Finch.Response{status: status, headers: headers, body: _body}, url, redirect_count)
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
          element |> Floki.attribute("sizes") |> List.first() |> get_size_in_pixels()
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
    element
    |> Floki.attribute("content")
    |> List.first()
  end

  defp get_logo_url([]), do: nil

  defp get_logo_url([element | _]) do
    element
    |> Floki.attribute("href")
    |> List.first()
    |> case do
      nil -> element |> Floki.attribute("src") |> List.first()
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

  defp find_social_links(html_tree, url) do
    %{
      twitter: find_social_url(html_tree, :twitter, url),
      discord: find_social_url(html_tree, :discord, url),
      github: find_social_url(html_tree, :github, url),
      instagram: find_social_url(html_tree, :instagram, url),
      youtube: find_social_url(html_tree, :youtube, url),
      producthunt: find_social_url(html_tree, :producthunt, url),
      hackernews: find_social_url(html_tree, :hackernews, url),
      slack: find_social_url(html_tree, :slack, url),
      linkedin: find_social_url(html_tree, :linkedin, url)
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
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

  defp find_social_url(html_tree, platform, base_url) do
    selectors = @social_selectors[platform]

    Enum.find_value(selectors, fn selector ->
      elements = Floki.find(html_tree, selector)

      url =
        case platform do
          :twitter ->
            handle_twitter_url(elements)

          _ ->
            get_href_or_nil(elements)
        end

      if url do
        make_absolute_url(url, base_url)
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
    element
    |> Floki.attribute("href")
    |> List.first()
  end

  defp get_email_domain(email) do
    [_, domain] = String.split(email, "@")
    if not blacklisted?(domain), do: domain
  end

  defp get_github_info(_website_url, nil), do: {:error, :no_github_url}

  defp get_github_info(website_url, github_url) do
    case extract_github_handle(github_url) do
      nil ->
        {:error, :invalid_github_url}

      handle ->
        request = Finch.build(:get, "https://api.github.com/users/#{handle}", @headers)

        case Finch.request(request, Algora.Finch) do
          {:ok, %Finch.Response{status: 200, body: body}} ->
            case Jason.decode(body) do
              {:ok, data} ->
                host = website_url |> URI.parse() |> Map.get(:host) |> String.split(".") |> Enum.at(-2)

                if Util.normalized_strings_match?(data["login"], host) do
                  {:ok,
                   %{
                     email: data["email"],
                     avatar_url: data["avatar_url"],
                     bio: data["bio"],
                     handle: data["login"],
                     website_url: data["blog"],
                     display_name: data["name"],
                     twitter_username: data["twitter_username"]
                   }}
                else
                  {:error, :mismatch}
                end

              _ ->
                {:error, :json_decode_failed}
            end

          _ ->
            {:error, :github_api_failed}
        end
    end
  end

  defp extract_github_handle(url) do
    case URI.parse(url) do
      %URI{host: "github.com", path: path} when is_binary(path) ->
        path
        |> String.trim("/")
        |> String.split("/")
        |> List.first()

      _ ->
        nil
    end
  end
end
