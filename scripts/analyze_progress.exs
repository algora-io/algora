defmodule ProgressAnalyzer do
  @moduledoc false
  def analyze_file(path) do
    stats =
      path
      |> File.read!()
      |> YamlElixir.read_from_string!()
      |> count_statuses()

    display_stats(stats)
  end

  defp count_statuses(yaml) do
    # Initialize counters
    initial_counts = %{completed: 0, skipped: 0, remaining: 0, undecided: 0}

    # Flatten and count all column statuses
    Enum.reduce(yaml, initial_counts, fn table, acc ->
      columns = table |> Map.values() |> List.first()

      Enum.reduce(columns, acc, fn column, inner_acc ->
        {_col, status} = Enum.at(Map.to_list(column), 0)

        case status do
          1 -> Map.update!(inner_acc, :completed, &(&1 + 1))
          -2 -> Map.update!(inner_acc, :undecided, &(&1 + 1))
          -1 -> Map.update!(inner_acc, :skipped, &(&1 + 1))
          0 -> Map.update!(inner_acc, :remaining, &(&1 + 1))
        end
      end)
    end)
  end

  defp display_stats(%{completed: done, skipped: skipped, remaining: todo, undecided: undecided}) do
    total = done + skipped + todo + undecided
    done_pct = percentage(done, total)
    skipped_pct = percentage(skipped, total)
    todo_pct = percentage(todo, total)
    undecided_pct = percentage(undecided, total)

    IO.puts("""
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
    """)
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
end

case System.argv() do
  [filename] ->
    ProgressAnalyzer.analyze_file(filename)

  _ ->
    IO.puts("Usage: elixir analyze_progress.exs <filename>")
    System.halt(1)
end
