defmodule Algora.Github.Command do
  import NimbleParsec
  import Algora.Parser.Combinator

  defmodule Helper do
    @usage %{
      bounty: "/bounty <amount>",
      tip: "/tip <amount> @username or /tip @username <amount>",
      claim: "/claim <issue-ref> (e.g. #123, repo#123, owner/repo#123, or full GitHub URL)"
    }

    def commands() do
      repeat(
        choice([
          # Any text that is not a command
          ascii_string([not: ?/], min: 1) |> ignore(),

          # Known command
          choice([
            bounty_command(),
            tip_command(),
            claim_command()
          ]),

          # Unknown command
          ignore(string("/"))
          |> concat(ascii_string([?a..?z, ?A..?Z, ?_, ?-], min: 1))
          |> ignore()
        ])
      )
    end

    def bounty_command() do
      ignore(string("/bounty"))
      |> concat(optional(ignore(whitespace()) |> concat(amount())))
      |> tag(:bounty)
      |> label(@usage.bounty)
    end

    def tip_command() do
      ignore(string("/tip"))
      |> concat(ignore(whitespace()))
      |> choice([
        amount() |> concat(ignore(whitespace())) |> concat(username()),
        username() |> concat(ignore(whitespace())) |> concat(amount()),
        amount(),
        username()
      ])
      |> tag(:tip)
      |> label(@usage.tip)
    end

    def claim_command() do
      ignore(string("/claim"))
      |> concat(ignore(whitespace()))
      |> concat(ticket_ref())
      |> tag(:claim)
      |> label(@usage.claim)
    end
  end

  defparsec(:parse_raw, Helper.commands())

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
end
