defmodule Algora.Admin.Migration.Progress do
  @moduledoc false
  require Logger

  @doc """
  Example usage:

      Migration.Progress.run!("v2-progress.yaml")
  """
  def run!(path, verbose \\ false) do
    [Path.dirname(__ENV__.file), path]
    |> Path.join()
    |> File.read!()
    |> YamlElixir.read_from_string!()
    |> count_statuses()
    |> display_stats(verbose)
  end

  @doc """
  Example usage:

      Migration.Progress.init!(".local/db/v2-structure.sql")
  """
  def init!(path) do
    path
    |> File.read!()
    |> parse_tables()
    |> filter_tables()
    |> format_yaml()
    |> IO.puts()
  end

  defp count_statuses(yaml) do
    # Initialize counters
    initial_counts = %{completed: 0, skipped: 0, remaining: 0, undecided: 0, remaining_columns: []}

    # Flatten and count all column statuses
    Enum.reduce(yaml, initial_counts, fn table, acc ->
      columns = table |> Map.values() |> List.first()

      Enum.reduce(columns, acc, fn column, inner_acc ->
        {col, status} = Enum.at(Map.to_list(column), 0)

        case status do
          1 ->
            Map.update!(inner_acc, :completed, &(&1 + 1))

          -2 ->
            Map.update!(inner_acc, :undecided, &(&1 + 1))

          -1 ->
            Map.update!(inner_acc, :skipped, &(&1 + 1))

          0 ->
            inner_acc
            |> Map.update!(:remaining, &(&1 + 1))
            |> Map.update!(:remaining_columns, &(&1 ++ ["#{table |> Map.keys() |> List.first()}.#{col}"]))
        end
      end)
    end)
  end

  defp display_stats(
         %{
           completed: done,
           skipped: skipped,
           remaining: todo,
           undecided: undecided,
           remaining_columns: remaining_columns
         },
         verbose
       ) do
    total = done + skipped + todo + undecided
    done_pct = percentage(done, total)
    skipped_pct = percentage(skipped, total)
    todo_pct = percentage(todo, total)
    undecided_pct = percentage(undecided, total)

    base_output = """
    Migration Progress Report
    ========================

    Summary:
    --------
    Total columns: #{total}

    Status Breakdown:
    ----------------
    ✅ Completed: #{String.pad_leading("#{done_pct}", 2)}% #{String.pad_leading("(#{done})", 5)}
    ⏳ Remaining: #{String.pad_leading("#{todo_pct}", 2)}% #{String.pad_leading("(#{todo})", 5)}
    ❌ Skipped:   #{String.pad_leading("#{skipped_pct}", 2)}% #{String.pad_leading("(#{skipped})", 5)}
    ❓ Undecided: #{String.pad_leading("#{undecided_pct}", 2)}% #{String.pad_leading("(#{undecided})", 5)}

    Progress:
    ---------
    [#{progress_bar(done_pct, skipped_pct, todo_pct, undecided_pct)}]
    """

    if_result =
      if verbose do
        base_output <>
          """

          Remaining Columns:
          ------------------
          #{Enum.join(remaining_columns, "\n")}
          """
      else
        base_output
      end

    IO.puts(if_result)
  end

  defp percentage(part, total) when total > 0 do
    trunc(part / total * 100)
  end

  defp progress_bar(done_pct, skipped_pct, todo_pct, undecided_pct) do
    done_chars = round(done_pct / 2)
    skipped_chars = round(skipped_pct / 2)
    todo_chars = round(todo_pct / 2)
    undecided_chars = round(undecided_pct / 2)

    String.duplicate("=", done_chars) <>
      String.duplicate("x", skipped_chars) <>
      String.duplicate("?", undecided_chars) <>
      String.duplicate(".", todo_chars)
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
