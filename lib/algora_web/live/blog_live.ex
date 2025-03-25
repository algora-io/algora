defmodule AlgoraWeb.BlogLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Markdown
  alias AlgoraWeb.Components.Footer
  alias AlgoraWeb.Components.Header

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case load_blog_post(slug) do
      {:ok, {frontmatter, content}} ->
        {:ok,
         assign(socket,
           content: Markdown.render_unsafe(content),
           frontmatter: frontmatter,
           page_title: frontmatter["title"]
         )}

      {:error, _reason} ->
        {:ok, push_navigate(socket, to: ~p"/blog")}
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    posts = list_blog_posts()
    {:ok, assign(socket, posts: posts, page_title: "Blog")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Header.header />
      <div class="max-w-5xl mx-auto px-4 pt-32 pb-16 sm:pb-24">
        <%= if @live_action == :index do %>
          <h1 class="text-3xl font-bold mb-8">Blog Posts</h1>
          <div class="space-y-6">
            <%= for post <- @posts do %>
              <div class="border border-border p-6 rounded-lg hover:border-border/80">
                <.link navigate={~p"/blog/#{post.slug}"} class="block space-y-2">
                  <h2 class="text-3xl font-bold hover:text-success font-display">
                    {post.title}
                  </h2>
                  <div class="flex items-center gap-4 text-sm text-muted-foreground">
                    <time datetime={post.date}>{format_date(post.date)}</time>
                    <div class="flex items-center gap-2">
                      <%= for author <- post.authors do %>
                        <img src={"https://github.com/#{author}.png"} class="w-6 h-6 rounded-full" />
                      <% end %>
                    </div>
                  </div>
                  <div class="flex flex-wrap gap-2 mt-2">
                    <%= for tag <- post.tags do %>
                      <.badge>
                        {tag}
                      </.badge>
                    <% end %>
                  </div>
                </.link>
              </div>
            <% end %>
          </div>
        <% else %>
          <article class="prose dark:prose-invert max-w-none">
            <header class="mb-8 not-prose">
              <h1 class="text-5xl font-display font-extrabold tracking-tight mb-4 bg-clip-text text-transparent bg-gradient-to-r from-emerald-400 to-emerald-300">
                {@frontmatter["title"]}
              </h1>

              <div class="flex items-center gap-4 text-muted-foreground mb-4">
                <time datetime={@frontmatter["date"]}>{format_date(@frontmatter["date"])}</time>
                <div class="flex items-center gap-3">
                  <%= for author <- @frontmatter["authors"] do %>
                    <div class="flex items-center gap-2">
                      <img src={"https://github.com/#{author}.png"} class="w-8 h-8 rounded-full" />
                      <.link
                        href={"https://github.com/#{author}"}
                        target="_blank"
                        class="text-sm hover:text-muted-foreground/80"
                      >
                        @{author}
                      </.link>
                    </div>
                  <% end %>
                </div>
              </div>

              <div class="flex flex-wrap gap-2">
                <%= for tag <- @frontmatter["tags"] do %>
                  <.badge>
                    {tag}
                  </.badge>
                <% end %>
              </div>
            </header>

            {raw(@content)}
          </article>
        <% end %>
      </div>
      <Footer.footer />
    </div>
    """
  end

  defp load_blog_post(slug) do
    with {:ok, content} <- File.read(Path.join(blog_path(), "#{slug}.md")),
         [frontmatter, markdown] <- content |> String.split("---\n", parts: 3) |> Enum.drop(1),
         {:ok, parsed_frontmatter} <- YamlElixir.read_from_string(frontmatter) do
      {:ok, {parsed_frontmatter, markdown}}
    end
  end

  defp list_blog_posts do
    blog_path()
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".md"))
    |> Enum.map(fn filename ->
      {:ok, {frontmatter, _content}} = load_blog_post(String.replace(filename, ".md", ""))

      %{
        slug: String.replace(filename, ".md", ""),
        title: frontmatter["title"],
        date: frontmatter["date"],
        tags: frontmatter["tags"],
        authors: frontmatter["authors"]
      }
    end)
    |> Enum.sort_by(& &1.date, :desc)
  end

  # Add this function to format dates
  def format_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> Calendar.strftime(date, "%B %d, %Y")
      _ -> date_string
    end
  end

  def format_date(_), do: ""

  defp blog_path, do: Path.join([:code.priv_dir(:algora), "blog"])
end
