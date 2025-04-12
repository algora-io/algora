defmodule Algora.Content do
  @moduledoc """
  Handles markdown content with frontmatter for blog posts, changelogs, docs, etc.
  """

  alias Algora.Markdown

  defstruct [:slug, :title, :date, :tags, :authors, :content, :path]

  defp base_path, do: Path.join([:code.priv_dir(:algora), "content"])

  def load_content(directory, slug) do
    with {:ok, content} <- [base_path(), directory, "#{slug}.md"] |> Path.join() |> File.read(),
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
    [base_path(), directory]
    |> Path.join()
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".md"))
    |> Enum.map(fn filename ->
      slug = String.replace(filename, ".md", "")
      {:ok, content} = load_content(directory, slug)
      content
    end)
    |> Enum.sort_by(& &1.date, :desc)
  end

  def list_content_rec(directory) do
    list_content_rec_helper([base_path(), directory], directory)
  end

  defp list_content_rec_helper(path, root_dir) do
    case File.ls(Path.join(path)) do
      {:ok, entries} ->
        entries
        |> Enum.reduce(%{files: [], dirs: %{}}, fn entry, acc ->
          full_path = Path.join(path ++ [entry])

          cond do
            File.dir?(full_path) ->
              nested_content = list_content_rec_helper(path ++ [entry], root_dir)
              put_in(acc, [:dirs, entry], nested_content)

            String.ends_with?(entry, ".md") ->
              # Get the path relative to base_path
              relative_path =
                full_path
                |> Path.relative_to(base_path())
                |> Path.rootname(".md")

              path_segments =
                relative_path
                |> Path.split()
                |> Enum.drop(1)

              directory = Path.dirname(relative_path)
              slug = Path.basename(relative_path)

              case load_content(directory, slug) do
                {:ok, content} ->
                  content_with_path = Map.put(content, :path, path_segments)
                  Map.update!(acc, :files, &[content_with_path | &1])

                _ ->
                  acc
              end

            true ->
              acc
          end
        end)
        |> Map.update!(:files, &Enum.sort_by(&1, fn file -> file.date end, :desc))

      {:error, _} ->
        %{files: [], dirs: %{}}
    end
  end

  def format_date(date_string) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> Calendar.strftime(date, "%B %d, %Y")
      _ -> date_string
    end
  end

  def format_date(_), do: ""
end
