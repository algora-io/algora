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

  alias Algora.Accounts.User

  @table_mappings %{
    "User" => "users",
    "Org" => "users"
  }

  @schema_mappings %{
    "User" => User,
    "Org" => User
  }

  defp transform("User", row) do
    row
    |> Map.put("type", "individual")
    |> rename_column("tech", "tech_stack")
  end

  defp transform("Org", row) do
    row
    |> Map.put("type", "organization")
    |> Map.put("provider", (row["github_handle"] && "github") || nil)
    |> rename_column("github_handle", "provider_login")
    |> rename_column("tech", "tech_stack")
  end

  defp transform(_, row), do: row

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

      if table_name in Map.keys(@table_mappings) do
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

      Enum.zip(columns, values)
      |> Enum.map(fn {column, value} -> {column, deserialize_value(value)} end)
      |> Enum.into(%{})
    end)
  end

  defp deserialize_value(value) do
    cond do
      String.starts_with?(value, "{") && String.ends_with?(value, "}") ->
        value
        |> String.slice(1..-2)
        |> String.split(",")
        |> Enum.map(&String.trim/1)

      String.starts_with?(value, "[") && String.ends_with?(value, "]") ->
        value
        |> Jason.decode!()

      true ->
        value
    end
  end

  defp transform_copy_section(nil), do: nil

  defp transform_copy_section(%{table: table_name, data: data}) do
    transformed_table_name =
      table_name
      |> String.replace(~r/^public\./, "")
      |> transform_table_name()

    transformed_data =
      data
      |> Enum.map(&transform(table_name, &1))
      |> Enum.map(&post_transform(table_name, &1))

    if Enum.empty?(transformed_data) do
      nil
    else
      transformed_columns = Map.keys(hd(transformed_data))
      %{table: transformed_table_name, columns: transformed_columns, data: transformed_data}
    end
  end

  defp transform_table_name(table_name), do: @table_mappings[table_name]

  defp post_transform(table_name, row) do
    schema = @schema_mappings[table_name]

    default_fields =
      schema.__struct__()
      |> Map.from_struct()
      |> Map.take(schema.__schema__(:fields))

    fields =
      row
      |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
      |> Enum.reject(fn {_, v} -> v == "\\N" end)
      |> Map.new()
      |> Map.put(:inserted_at, row["created_at"])
      |> Map.take(Map.keys(default_fields))

    Map.merge(default_fields, fields)
  end

  defp rename_column(row, from, to) do
    row
    |> Map.put(to, Map.get(row, from))
    |> Map.delete(from)
  end

  defp load_copy_section(nil), do: []

  defp load_copy_section(%{table: table_name, columns: columns, data: data}) do
    copy_statement = "COPY #{table_name} (#{Enum.join(columns, ", ")}) FROM stdin;\n"

    data_lines =
      Enum.map(data, fn row ->
        columns
        |> Enum.map(fn col -> serialize_value(Map.get(row, col, "")) end)
        |> Enum.join("\t")
        |> Kernel.<>("\n")
      end)

    [copy_statement | data_lines] ++ ["\\.\n\n"]
  end

  defp serialize_value(value) when is_list(value) do
    cond do
      Enum.all?(value, &is_binary/1) ->
        "{#{Enum.join(value, ",")}}"

      true ->
        Jason.encode!(value)
    end
  end

  defp serialize_value(value) when is_map(value), do: Jason.encode!(value)
  defp serialize_value(value), do: to_string(value)

  def extract_default_fields(schema) do
    schema.__schema__(:fields)
    |> Enum.filter(fn field ->
      case schema.__schema__(:field, field) do
        {:default, _} -> true
        _ -> false
      end
    end)
    |> Enum.map(fn field ->
      {field, schema.__schema__(:field, field) |> elem(1)}
    end)
    |> Enum.into(%{})
  end
end

input_file = ".local/algora_db.sql"
output_file = ".local/algora_db_new.sql"
DatabaseMigration.process_dump(input_file, output_file)
