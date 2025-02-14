defmodule SqlParser do
  @moduledoc false
  def parse_file(path) do
    path
    |> File.read!()
    |> parse_tables()
    |> filter_tables()
    |> format_yaml()
    |> IO.puts()
  end

  defp parse_tables(content) do
    # Match CREATE TABLE statements
    regex = ~r/CREATE TABLE public\.([^(]+)\s*\((.*?)\);/s

    regex
    |> Regex.scan(content, capture: :all_but_first)
    |> Enum.map(fn [table_name, columns] ->
      {
        String.trim(table_name),
        parse_columns(columns)
      }
    end)
  end

  defp parse_columns(columns_str) do
    # Match column definitions - captures quotes if present
    regex = ~r/^\s*("?\w+"?)[^,]*/m

    regex
    |> Regex.scan(columns_str, capture: :all_but_first)
    |> List.flatten()
    |> Enum.map(&String.trim/1)
  end

  defp filter_tables(tables) do
    Enum.reject(tables, fn {table_name, _columns} ->
      String.ends_with?(table_name, "_activities")
    end)
  end

  defp format_yaml(tables) do
    Enum.map_join(tables, "\n", fn {table_name, columns} ->
      columns_yaml =
        Enum.map_join(columns, "\n", fn column ->
          "    - #{column}: 0"
        end)

      "- #{table_name}:\n#{columns_yaml}"
    end)
  end
end

case System.argv() do
  [filename] ->
    SqlParser.parse_file(filename)

  _ ->
    IO.puts("Usage: elixir parse_sql.exs <filename>")
    System.halt(1)
end
