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
    initial_counts = %{completed: 0, wontdo: 0, remaining: 0, undecided: 0}

    # Flatten and count all column statuses
    Enum.reduce(yaml, initial_counts, fn table, acc ->
      columns = table |> Map.values() |> List.first()

      Enum.reduce(columns, acc, fn column, inner_acc ->
        {_col, status} = Enum.at(Map.to_list(column), 0)

        case status do
          1 -> Map.update!(inner_acc, :completed, &(&1 + 1))
          -2 -> Map.update!(inner_acc, :undecided, &(&1 + 1))
          -1 -> Map.update!(inner_acc, :wontdo, &(&1 + 1))
          0 -> Map.update!(inner_acc, :remaining, &(&1 + 1))
        end
      end)
    end)
  end

  defp display_stats(%{completed: done, wontdo: wont, remaining: todo, undecided: undecided}) do
    total = done + wont + todo + undecided
    done_pct = percentage(done, total)
    wont_pct = percentage(wont, total)
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
    ✅ Completed:  #{done} (#{done_pct}%)
    ⏳ Remaining:  #{todo} (#{todo_pct}%)
    ❌ Won't Do:   #{wont} (#{wont_pct}%)
    ❓ Undecided: #{undecided} (#{undecided_pct}%)
    Progress:
    ---------
    [#{progress_bar(done_pct, wont_pct, todo_pct, undecided_pct)}]
    """)
  end

  defp percentage(part, total) when total > 0 do
    Float.round(part / total * 100, 1)
  end

  defp progress_bar(done_pct, wont_pct, todo_pct, undecided_pct) do
    done_chars = round(done_pct / 2)
    wont_chars = round(wont_pct / 2)
    todo_chars = round(todo_pct / 2)
    undecided_chars = round(undecided_pct / 2)

    String.duplicate("=", done_chars) <>
      String.duplicate("x", wont_chars) <>
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
