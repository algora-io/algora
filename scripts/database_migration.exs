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
  require Logger
  alias Algora.Users.User
  alias Algora.Workspace.Ticket
  alias Algora.Bounties.Bounty
  alias Algora.Payments.Transaction

  @table_mappings %{
    "User" => "users",
    "Org" => "users",
    "GithubUser" => "users",
    "Task" => "tickets",
    "GithubIssue" => nil,
    "GithubPullRequest" => nil,
    "Bounty" => "bounties",
    "Reward" => nil,
    "BountyTransfer" => "transactions",
    "Claim" => nil
  }

  @schema_mappings %{
    "User" => User,
    "Org" => User,
    "GithubUser" => User,
    "Task" => Ticket,
    "GithubIssue" => nil,
    "GithubPullRequest" => nil,
    "Bounty" => Bounty,
    "Reward" => nil,
    "BountyTransfer" => Transaction,
    "Claim" => nil
  }

  @backfilled_tables ["repositories", "transactions", "bounties", "tickets", "users"]

  @relevant_tables Map.keys(@table_mappings)

  defp transform("Task", row, db) do
    github_issue =
      db |> Map.get("GithubIssue", []) |> Enum.find(&(&1["id"] == row["issue_id"]))

    github_pull_request =
      db |> Map.get("GithubPullRequest", []) |> Enum.find(&(&1["id"] == row["pull_request_id"]))

    row =
      cond do
        github_issue ->
          row
          |> Map.put("type", "issue")
          |> Map.put("title", github_issue["title"])
          |> Map.put("description", github_issue["body"])
          |> Map.put("inserted_at", github_issue["created_at"])
          |> Map.put("updated_at", github_issue["updated_at"])
          |> Map.put("url", github_issue["html_url"])
          |> Map.put("provider", "github")
          |> Map.put("provider_id", github_issue["id"])
          |> Map.put("provider_meta", deserialize_value(github_issue))

        github_pull_request ->
          row
          |> Map.put("type", "pull_request")
          |> Map.put("title", github_pull_request["title"])
          |> Map.put("description", github_pull_request["body"])
          |> Map.put("inserted_at", github_pull_request["created_at"])
          |> Map.put("updated_at", github_pull_request["updated_at"])
          |> Map.put("url", github_pull_request["html_url"])
          |> Map.put("provider", "github")
          |> Map.put("provider_id", github_pull_request["id"])
          |> Map.put("provider_meta", deserialize_value(github_pull_request))

        true ->
          row
          # TODO: maybe discard altogther?
          |> Map.put("inserted_at", "1970-01-01 00:00:00")
          |> Map.put("updated_at", "1970-01-01 00:00:00")
      end

    row
  end

  defp transform("User", row, db) do
    github_user =
      db |> Map.get("GithubUser", []) |> Enum.find(&(&1["user_id"] == row["id"]))

    row =
      if github_user do
        row
        |> Map.put("provider", "github")
        |> Map.put("provider_id", github_user["id"])
        |> Map.put("provider_login", github_user["login"])
        |> Map.put("provider_meta", deserialize_value(github_user))
      else
        row
      end

    row
    |> Map.put("type", "individual")
    |> rename_column("tech", "tech_stack")
    |> rename_column("stars_earned", "stargazers_count")
    |> rename_column("image", "avatar_url")
    |> update_url_field("avatar_url")
  end

  defp transform("Org", row, _db) do
    row
    |> Map.put("type", "organization")
    |> Map.put("provider", row["github_handle"] && "github")
    |> rename_column("github_handle", "provider_login")
    |> rename_column("tech", "tech_stack")
    |> update_url_field("avatar_url")
  end

  defp transform("GithubUser", %{user_id: nil} = row, _db) do
    row
    |> Map.put("type", "individual")
    |> Map.put("provider", "github")
    |> Map.put("provider_id", row["id"])
    |> Map.put("provider_meta", deserialize_value(row))
  end

  defp transform("GithubUser", _row, _db), do: nil

  defp transform("Bounty", row, db) do
    reward =
      db |> Map.get("Reward", []) |> Enum.find(&(&1["bounty_id"] == row["id"]))

    row =
      row
      |> Map.put("ticket_id", row["task_id"])
      |> Map.put("owner_id", row["org_id"])
      |> Map.put("creator_id", row["poster_id"])
      |> Map.put("inserted_at", row["created_at"])
      |> Map.put("updated_at", row["updated_at"])

    row =
      if reward do
        row
        |> Map.put("amount", Decimal.div(Decimal.new(reward["amount"]), 100))
        |> Map.put("currency", reward["currency"])
      else
        # TODO: make the fields nullable instead
        row
        |> Map.put("amount", 0)
        |> Map.put("currency", "USD")
      end

    row
  end

  defp transform("BountyTransfer", row, db) do
    claim =
      db |> Map.get("Claim", []) |> Enum.find(&(&1["id"] == row["claim_id"]))

    github_user =
      db |> Map.get("GithubUser", []) |> Enum.find(&(&1["id"] == claim["github_user_id"]))

    user =
      db |> Map.get("User", []) |> Enum.find(&(&1["id"] == github_user["user_id"]))

    row =
      if claim && user do
        row
        |> Map.put("type", "transfer")
        |> Map.put("provider", "stripe")
        |> Map.put("provider_id", row["transfer_id"])
        |> Map.put("amount", Decimal.div(Decimal.new(row["amount"]), 100))
        |> Map.put("currency", row["currency"])
        |> Map.put("bounty_id", claim["bounty_id"])
        |> Map.put("recipient_id", user["id"])
        |> Map.put("inserted_at", row["created_at"])
        |> Map.put("updated_at", row["updated_at"])
        |> Map.put("status", if(row["succeeded_at"] == nil, do: :pending, else: :succeeded))
        |> Map.put("succeeded_at", row["succeeded_at"])
      else
        nil
      end

    row
  end

  defp transform(_, _row, _db), do: nil

  def process_dump(input_file, output_file) do
    db = collect_data(input_file)

    File.stream!(input_file)
    |> Stream.chunk_while(
      [],
      &chunk_fun/2,
      &after_fun/1
    )
    |> Stream.filter(&(length(&1) > 0))
    |> Stream.map(&process_chunk(&1, db))
    |> Stream.into(File.stream!(output_file))
    |> Stream.run()
  end

  defp collect_data(input_file) do
    File.stream!(input_file)
    |> Stream.chunk_while(
      nil,
      &collect_chunk_fun/2,
      &collect_after_fun/1
    )
    |> Enum.reduce(%{}, fn
      {table, data}, acc when table in @relevant_tables ->
        parsed_data = parse_copy_data(data)
        Map.put(acc, table, parsed_data)

      _, acc ->
        acc
    end)
  end

  defp parse_copy_data([header | data]) do
    columns =
      header
      |> String.split("(")
      |> List.last()
      |> String.trim_trailing(") FROM stdin;\n")
      |> String.split(", ")

    Enum.map(data, fn line ->
      values = String.trim(line) |> String.split("\t")
      Enum.zip(columns, values) |> Map.new()
    end)
  end

  defp collect_chunk_fun(line, nil) do
    case Regex.run(~r/COPY public\.\"(\w+)\"/, line) do
      [_, table_name] -> {:cont, {table_name, [line]}}
      _ -> {:cont, nil}
    end
  end

  defp collect_chunk_fun(line, {table, acc}) do
    if String.trim(line) == "\\." do
      {:cont, {table, Enum.reverse(acc)}, nil}
    else
      {:cont, {table, [line | acc]}}
    end
  end

  defp collect_after_fun(nil), do: {:cont, nil}
  defp collect_after_fun({table, acc}), do: {:cont, {table, Enum.reverse(acc)}, nil}

  defp process_chunk(chunk, db) do
    case extract_copy_section(chunk) do
      %{table: table} = section when table in @relevant_tables ->
        transform_section(section, db)

      _ ->
        nil
    end
    |> load_copy_section()
  end

  defp transform_section(%{table: table, columns: _columns, data: data}, db) do
    transformed_data =
      data
      |> Enum.map(fn row ->
        try do
          transform(table, row, db)
        rescue
          e ->
            IO.puts("Error transforming row in table #{table}: #{inspect(row)}")
            IO.puts("Error: #{inspect(e)}")
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&post_transform(table, &1))

    transformed_table_name = transform_table_name(table)

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
      |> Enum.reject(fn {_, v} -> v == "\\N" end)
      |> Map.new(fn {k, v} -> {k, v} end)
      |> conditionally_rename_created_at()
      |> Map.take(Enum.map(Map.keys(default_fields), &Atom.to_string/1))
      |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
      |> Map.new()

    # Ensure handle is unique
    fields = ensure_unique_handle(fields)

    Map.merge(default_fields, fields)
  end

  defp conditionally_rename_created_at(fields) do
    case {Map.get(fields, "inserted_at"), Map.get(fields, "created_at")} do
      {nil, created_at} when not is_nil(created_at) ->
        fields
        |> Map.put("inserted_at", created_at)
        |> Map.delete("created_at")

      _ ->
        fields
    end
  end

  defp ensure_unique_handle(fields) do
    case fields[:handle] do
      nil ->
        fields

      handle ->
        new_handle = get_unique_handle(handle)
        Map.put(fields, :handle, new_handle)
    end
  end

  defp get_unique_handle(handle) do
    handles = Process.get(:handles, %{})
    downcased_handle = String.downcase(handle)
    count = Map.get(handles, downcased_handle, 0)

    new_handle = if count > 0, do: "#{handle}#{count + 1}", else: handle
    Process.put(:handles, Map.put(handles, downcased_handle, count + 1))

    new_handle
  end

  defp rename_column(row, from, to) do
    value = Map.get(row, from)

    row
    |> Map.put(to, value)
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

  defp serialize_value(%Decimal{} = value), do: Decimal.to_string(value)

  defp serialize_value(value) when is_map(value) or is_list(value) do
    try do
      json = Jason.encode!(value, escape: :json)
      # Handle empty arrays specifically
      if json == "[]" do
        "{}"
      else
        # Escape backslashes and double quotes for PostgreSQL COPY
        String.replace(json, ["\\", "\""], fn
          "\\" -> "\\\\"
          "\"" -> "\\\""
        end)
      end
    rescue
      _ ->
        # Fallback to a safe string representation
        inspect(value, limit: :infinity, printable_limit: :infinity)
        |> String.replace(["\\", "\n", "\r", "\t"], fn
          "\\" -> "\\\\"
          "\n" -> "\\n"
          "\r" -> "\\r"
          "\t" -> "\\t"
        end)
        |> String.replace("\"", "\\\"")
    end
  end

  defp serialize_value(value) when is_nil(value), do: "\\N"

  defp serialize_value(value) when is_binary(value) do
    # Remove any surrounding quotes for numeric values
    value =
      if String.starts_with?(value, "\"") and String.ends_with?(value, "\"") do
        String.slice(value, 1..-2)
      else
        value
      end

    String.replace(value, ["\\", "\n", "\r", "\t"], fn
      "\\" -> "\\\\"
      "\n" -> "\\n"
      "\r" -> "\\r"
      "\t" -> "\\t"
    end)
  end

  defp serialize_value(value), do: to_string(value)

  # defp extract_default_fields(schema) do
  #   schema.__schema__(:fields)
  #   |> Enum.filter(fn field ->
  #     case schema.__schema__(:field, field) do
  #       {:default, _} -> true
  #       _ -> false
  #     end
  #   end)
  #   |> Enum.map(fn field ->
  #     {field, schema.__schema__(:field, field) |> elem(1)}
  #   end)
  #   |> Enum.into(%{})
  # end

  defp update_url_field(fields, field) do
    case Map.get(fields, field) do
      "/" <> rest ->
        Map.put(fields, field, "https://console.algora.io/" <> rest)

      _ ->
        fields
    end
  end

  defp chunk_fun(line, acc) do
    if String.starts_with?(line, "COPY ") or String.trim(line) == "\\." do
      {:cont, Enum.reverse(acc), [line]}
    else
      {:cont, [line | acc]}
    end
  end

  defp after_fun(acc), do: {:cont, Enum.reverse(acc), []}

  defp extract_copy_section([header | data]) do
    case Regex.run(~r/COPY (?:public\.)?\"?(\w+)\"?\s*\((.*?)\)\s*FROM stdin;/, header) do
      [_, table, column_string] ->
        columns = column_string |> String.split(", ") |> Enum.map(&String.trim/1)

        parsed_data =
          data
          |> Enum.take_while(&(&1 != "\\.\n"))
          |> Enum.map(&parse_data_row(&1, columns))

        %{table: table, columns: columns, data: parsed_data}

      nil ->
        nil
    end
  end

  defp parse_data_row(row, columns) do
    row
    |> String.trim()
    |> String.split("\t")
    |> Enum.zip(columns)
    |> Map.new(fn {value, column} -> {column, value} end)

    # |> Map.new(fn {value, column} -> {column, deserialize_value(value)} end)
  end

  defp deserialize_value("\\N"), do: nil
  defp deserialize_value("t"), do: true
  defp deserialize_value("f"), do: false
  defp deserialize_value("{}"), do: []

  defp deserialize_value(value) when is_map(value) do
    value
    |> Enum.map(fn {k, v} -> {k, deserialize_value(v)} end)
    |> Map.new()
  end

  defp deserialize_value(value) when is_list(value) do
    Enum.map(value, &deserialize_value/1)
  end

  defp deserialize_value(value) when is_binary(value) do
    cond do
      String.starts_with?(value, "{") and String.ends_with?(value, "}") ->
        value
        |> String.slice(1..-2)
        |> String.split(",", trim: true)
        |> Enum.map(&deserialize_value/1)

      true ->
        case Integer.parse(value) do
          {int, ""} ->
            int

          _ ->
            case Float.parse(value) do
              {float, ""} -> float
              _ -> value
            end
        end
    end
  end

  defp deserialize_value(value), do: value

  defp clear_tables!() do
    commands =
      [
        "BEGIN TRANSACTION;",
        "SET CONSTRAINTS ALL DEFERRED;",
        Enum.map(@backfilled_tables, &"TRUNCATE TABLE #{&1} CASCADE;"),
        "SET CONSTRAINTS ALL IMMEDIATE;",
        "COMMIT;"
      ]
      |> List.flatten()
      |> Enum.join("\n")

    case psql(["-c", commands]) do
      {:ok, _} -> :ok
      {:error, code} -> raise "Failed to clear tables with exit code: #{code}"
    end
  end

  defp psql(commands) do
    {res, code} =
      System.cmd("psql", [System.fetch_env!("DATABASE_URL") | commands], stderr_to_stdout: true)

    cond do
      code != 0 ->
        Logger.error(res)
        {:error, code}

      String.contains?(res, "ERROR:") ->
        Logger.error(res)
        {:error, :something_went_wrong}

      true ->
        {:ok, res}
    end
  end

  def run!() do
    input_file = ".local/prod_db.sql"
    output_file = ".local/prod_db_new.sql"

    if File.exists?(input_file) or File.exists?(output_file) do
      # IO.puts("Processing dump...")
      # :ok = process_dump(input_file, output_file)

      IO.puts("Clearing tables...")
      :ok = clear_tables!()

      IO.puts("Importing new data...")
      {:ok, _} = psql(["-f", output_file])

      IO.puts("Backfilling repositories...")
      :ok = Algora.Admin.backfill_repos!()

      IO.puts("Migration completed successfully")
    end
  end
end

DatabaseMigration.run!()
