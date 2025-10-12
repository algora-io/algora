defmodule Algora.Markdown do
  @moduledoc false

  require Logger

  @default_opts [
    extension: [
      strikethrough: true,
      tagfilter: true,
      table: true,
      autolink: true,
      tasklist: true,
      footnotes: true,
      shortcodes: true
    ],
    parse: [
      smart: true,
      relaxed_tasklist_matching: true,
      relaxed_autolinks: true
    ],
    render: [
      github_pre_lang: true,
      unsafe_: true
    ],
    features: [
      sanitize: MDEx.default_sanitize_options(),
      # TODO: sanitize and syntax_highlight_theme are currently incompatible
      # since sanitization strips out the syntax highlighting classes
      syntax_highlight_theme: "neovim_dark"
    ]
  ]

  def render(_md_or_doc, _opts \\ [])

  def render(nil, _opts), do: nil

  def render(md_or_doc, opts) do
    case MDEx.to_html(md_or_doc, Keyword.merge(@default_opts, opts)) do
      {:ok, html} ->
        html

      {:error, error} ->
        Logger.error("Error converting markdown to html: #{inspect(error)}")
        md_or_doc
    end
  end

  def render_unsafe(md_or_doc, opts \\ []) do
    default_opts = update_in(@default_opts, [:features, :sanitize], fn _ -> false end)

    case MDEx.to_html(md_or_doc, Keyword.merge(default_opts, opts)) do
      {:ok, html} ->
        html

      {:error, error} ->
        Logger.error("Error converting markdown to html: #{inspect(error)}")
        md_or_doc
    end
  end
end
