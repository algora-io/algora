defmodule DatabaseMigration do
  @moduledoc """
  Database Migration Script

  Purpose:
  This script processes a PostgreSQL database dump in COPY format,
  transforms the data according to new schema requirements, and outputs
  the result in the same COPY format.

  Functionality:
  1. Reads a PostgreSQL dump file containing COPY statements and their associated data.
  2. Processes each COPY section (extract, transform, load).
  3. Applies transformations based on table names.
  4. Outputs the transformed data in COPY format.
  5. Discards COPY sections for tables not in the allowed list.

  Usage:
  - Set the input_file to your PostgreSQL dump file path.
  - Set the output_file to your desired output file path.
  - Run the script using: elixir scripts/database_migration.exs
  """

  @allowed_tables [
    "User"
  ]

  def process_dump(input_file, output_file) do
    File.stream!(input_file)
    |> Stream.chunk_while(
      [],
      &chunk_fun/2,
      &after_fun/1
    )
    |> Stream.filter(&(length(&1) > 0))
    |> Stream.map(&process_chunk/1)
    |> Stream.into(File.stream!(output_file))
    |> Stream.run()
  end

  defp chunk_fun(line, []) do
    if String.starts_with?(line, "COPY ") do
      {:cont, [line]}
    else
      {:cont, [], []}
    end
  end

  defp chunk_fun(line, acc) do
    trimmed_line = String.trim(line)

    if trimmed_line == "\\." do
      {:cont, Enum.reverse([trimmed_line | acc]), []}
    else
      {:cont, [line | acc]}
    end
  end

  defp after_fun([]), do: {:cont, []}
  defp after_fun(acc), do: {:cont, Enum.reverse(acc), []}

  defp process_chunk(chunk) do
    chunk
    |> extract_copy_section()
    |> transform_copy_section()
    |> load_copy_section()
  end

  defp extract_copy_section([copy_statement | data_lines]) do
    if String.starts_with?(copy_statement, "COPY ") do
      table_name = extract_table_name(copy_statement)

      if table_name in @allowed_tables do
        columns = extract_columns(copy_statement)
        data = parse_data_lines(data_lines, columns)

        %{
          table: table_name,
          columns: columns,
          data: data
        }
      else
        nil
      end
    else
      nil
    end
  end

  defp extract_table_name(copy_statement) do
    ~r/COPY\s+(\w+\.)?\"?(\w+)\"?/
    |> Regex.run(copy_statement)
    |> List.last()
  end

  defp extract_columns(copy_statement) do
    ~r/\((.*?)\)/
    |> Regex.run(copy_statement)
    |> List.last()
    |> String.split(", ")
  end

  defp parse_data_lines(data_lines, columns) do
    data_lines
    |> Enum.take_while(&(String.trim(&1) != "\\."))
    |> Enum.map(fn line ->
      values = String.split(String.trim(line), "\t")
      Enum.zip(columns, values) |> Enum.into(%{})
    end)
  end

  defp transform_copy_section(nil), do: nil

  defp transform_copy_section(%{table: table_name, data: data}) do
    table_name = String.replace(table_name, ~r/^public\./, "")
    pluralized_table_name = pluralize_table_name(table_name)
    transformed_data = Enum.map(data, &transform(table_name, &1))

    if Enum.empty?(transformed_data) do
      nil
    else
      transformed_columns = Map.keys(hd(transformed_data))
      %{table: pluralized_table_name, columns: transformed_columns, data: transformed_data}
    end
  end

  defp pluralize_table_name(table_name) do
    case table_name do
      "User" -> "users"
      _ -> table_name
    end
  end

  defp transform("User", row) do
    allowed_columns = ["id", "inserted_at", "updated_at", "handle", "email"]

    row
    |> Map.put("inserted_at", Map.get(row, "created_at"))
    |> Map.put("type", "individual")
    |> Map.filter(fn {key, _} -> key in allowed_columns end)
  end

  defp transform(_, row), do: row

  defp load_copy_section(nil), do: []

  defp load_copy_section(%{table: table_name, columns: columns, data: data}) do
    copy_statement = "COPY #{table_name} (#{Enum.join(columns, ", ")}) FROM stdin;\n"

    data_lines =
      Enum.map(data, fn row ->
        columns
        |> Enum.map(fn col -> Map.get(row, col, "") end)
        |> Enum.join("\t")
        # Add newline after each row
        |> Kernel.<>("\n")
      end)

    [copy_statement | data_lines] ++ ["\\.\n\n"]
  end
end

input_file = "algora_db.sql"
output_file = "algora_db_new.sql"
DatabaseMigration.process_dump(input_file, output_file)
