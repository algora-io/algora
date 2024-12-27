defmodule Algora.Github.Command do
  import NimbleParsec

  whitespace = ascii_string([?\s, ?\t], min: 1)
  digits = ascii_string([?0..?9], min: 1)
  word_chars = ascii_string([not: ?\s, not: ?\t], min: 1)
  non_separator_chars = ascii_string([not: ?#, not: ?/, not: ?\s, not: ?\t], min: 1)
  integer = digits |> reduce(:to_integer)

  text_segment =
    ascii_string([not: ?/], min: 1)
    |> ignore()
    |> label("any text")

  unknown_command =
    ignore(string("/"))
    |> concat(ascii_string([?a..?z, ?A..?Z, ?_, ?-], min: 1))
    |> ignore()
    |> label("unknown command")

  amount =
    ignore(optional(string("$")))
    |> concat(ascii_string([?0..?9, ?., ?,], min: 1))
    |> post_traverse(:to_money)
    |> unwrap_and_tag(:amount)
    |> label("amount (e.g. 1000 or 1,000.00)")

  username =
    ignore(string("@"))
    |> concat(word_chars)
    |> unwrap_and_tag(:username)
    |> label("username starting with @")

  ticket_ref =
    choice([
      # Format: #123
      optional(ignore(string("#")))
      |> concat(integer |> unwrap_and_tag(:number)),

      # Format: repo#123
      empty()
      |> concat(non_separator_chars |> unwrap_and_tag(:repo))
      |> ignore(string("#"))
      |> concat(integer |> unwrap_and_tag(:number)),

      # Format: owner/repo#123
      empty()
      |> concat(non_separator_chars |> unwrap_and_tag(:owner))
      |> ignore(string("/"))
      |> concat(non_separator_chars |> unwrap_and_tag(:repo))
      |> ignore(string("#"))
      |> concat(integer |> unwrap_and_tag(:number)),

      # Format: https://github.com/owner/repo/(issues|pull|discussions)/123
      ignore(choice([string("https://"), string("http://"), empty()]))
      |> ignore(string("github.com/"))
      |> concat(non_separator_chars |> unwrap_and_tag(:owner))
      |> ignore(string("/"))
      |> concat(non_separator_chars |> unwrap_and_tag(:repo))
      |> ignore(string("/"))
      |> concat(
        choice([string("issues"), string("pull"), string("discussions")])
        |> unwrap_and_tag(:type)
      )
      |> ignore(string("/"))
      |> concat(integer |> unwrap_and_tag(:number))
    ])
    |> tag(:ticket_ref)
    |> label("issue reference (e.g. #123, repo#123, owner/repo#123, or full GitHub URL)")

  @usage %{
    bounty: "/bounty <amount>",
    tip: "/tip <amount> @username or /tip @username <amount>",
    claim: "/claim <issue-ref> (e.g. #123, repo#123, owner/repo#123, or full GitHub URL)"
  }

  bounty_command =
    ignore(string("/bounty"))
    |> concat(optional(ignore(whitespace) |> concat(amount)))
    |> tag(:bounty)
    |> label(@usage.bounty)

  tip_command =
    ignore(string("/tip"))
    |> concat(ignore(whitespace))
    |> choice([
      amount |> concat(ignore(whitespace)) |> concat(username),
      username |> concat(ignore(whitespace)) |> concat(amount),
      amount,
      username
    ])
    |> tag(:tip)
    |> label(@usage.tip)

  claim_command =
    ignore(string("/claim"))
    |> concat(ignore(whitespace))
    |> concat(ticket_ref)
    |> tag(:claim)
    |> label(@usage.claim)

  single_command =
    choice([
      bounty_command,
      tip_command,
      claim_command
    ])

  command_sequence =
    repeat(
      choice([
        text_segment,
        single_command,
        unknown_command
      ])
    )

  defparsec(:parse_raw, command_sequence)
  defparsec(:money, amount)

  def parse(nil), do: {:ok, []}

  def parse(input) when is_binary(input) do
    try do
      case parse_raw(input) do
        {:ok, [], _, _, _, _} ->
          {:ok, []}

        {:ok, parsed, _, _, _, _} ->
          {:ok, parsed |> Enum.reject(&is_nil/1)}

        {:error, reason, _, _, _, _} ->
          {:error, reason}
      end
    rescue
      ArgumentError ->
        {:error, "Failed to parse commands"}
    end
  end

  # Helper functions
  defp to_money(rest, args, context, _line, _offset) do
    delimiters = [",", "."]

    amount_string = args |> Enum.join()

    amount_string =
      Enum.reduce(delimiters, amount_string, fn delimiter, acc -> String.trim(acc, delimiter) end)

    last_delimiter_pos =
      amount_string
      |> String.reverse()
      |> String.split("")
      |> Enum.find_index(&(&1 in delimiters))

    locale =
      cond do
        # No delimiter found - treat as whole number
        is_nil(last_delimiter_pos) ->
          :en

        # If last segment is 3 digits, it's a thousands separator
        last_delimiter_pos == 4 ->
          case String.at(amount_string, -last_delimiter_pos) do
            "." -> :de
            "," -> :en
          end

        # Otherwise, it's a decimal separator
        true ->
          case String.at(amount_string, -last_delimiter_pos) do
            "," -> :de
            "." -> :en
          end
      end

    case Money.new(:USD, amount_string, locale: locale) do
      {:error, _reason} -> {:error, "Invalid amount: \"#{amount_string}\""}
      amount -> {rest, [amount], context}
    end
  end

  defp to_integer(segments) when is_list(segments) do
    segments |> Enum.join() |> String.to_integer()
  end
end
