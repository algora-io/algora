defmodule AlgoraWeb.ChangelogLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias AlgoraWeb.Components.Footer
  alias AlgoraWeb.Components.Header

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case Algora.Content.load_content("changelog", slug) do
      {:ok, content} ->
        {:ok,
         assign(socket,
           content: content,
           page_title: content.title
         )}

      {:error, _reason} ->
        {:ok, push_navigate(socket, to: ~p"/changelog")}
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    posts = Algora.Content.list_content("changelog")
    {:ok, assign(socket, posts: posts, page_title: "Changelog")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Header.header />
      <div class="max-w-5xl mx-auto px-4 pt-32 pb-16 sm:pb-24">
        <%= if @live_action == :index do %>
          <h1 class="text-3xl font-bold mb-8">Changelog</h1>
          <div class="space-y-6">
            <%= for post <- @posts do %>
              <div class="border border-border p-6 rounded-lg hover:border-border/80">
                <.link navigate={~p"/changelog/#{post.slug}"} class="block space-y-2">
                  <h2 class="text-3xl font-bold hover:text-success font-display">
                    {post.title}
                  </h2>
                  <div class="flex items-center gap-4 text-sm text-muted-foreground">
                    <time datetime={post.date}>{Algora.Content.format_date(post.date)}</time>
                  </div>
                </.link>
              </div>
            <% end %>
          </div>
        <% else %>
          <article class="prose prose-invert max-w-none">
            <header class="mb-8 not-prose">
              <h1 class="text-5xl font-display font-extrabold tracking-tight mb-4 bg-clip-text text-transparent bg-gradient-to-r from-emerald-400 to-emerald-300">
                {@content.title}
              </h1>

              <div class="flex items-center gap-4 text-muted-foreground mb-4">
                <time datetime={@content.date}>{Algora.Content.format_date(@content.date)}</time>
              </div>
            </header>

            {raw(@content.content)}
          </article>
        <% end %>
      </div>
      <Footer.footer />
    </div>
    """
  end
end
