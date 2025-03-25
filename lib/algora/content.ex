defmodule Algora.Content do
  @moduledoc """
  Handles markdown content with frontmatter for blog posts, changelogs, docs, etc.
  """

  alias Algora.Markdown

  defstruct [:slug, :title, :date, :tags, :authors, :content]

  def load_content(directory, slug) do
    with {:ok, content} <- File.read(Path.join(directory, "#{slug}.md")),
         [frontmatter, markdown] <- content |> String.split("---\n", parts: 3) |> Enum.drop(1),
         {:ok, parsed_frontmatter} <- YamlElixir.read_from_string(frontmatter) do
      {:ok,
       %__MODULE__{
         slug: slug,
         title: parsed_frontmatter["title"],
         date: parsed_frontmatter["date"],
         tags: parsed_frontmatter["tags"],
         authors: parsed_frontmatter["authors"],
         content: Markdown.render_unsafe(markdown)
       }}
    end
  end

  def list_content(directory) do
    directory
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".md"))
    |> Enum.map(fn filename ->
      slug = String.replace(filename, ".md", "")
      {:ok, content} = load_content(directory, slug)
      content
    end)
    |> Enum.sort_by(& &1.date, :desc)
  end

  def format_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> Calendar.strftime(date, "%B %d, %Y")
      _ -> date_string
    end
  end

  def format_date(_), do: ""
end
