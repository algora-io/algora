defmodule Algora.Github.Command do
  @moduledoc false
  import Algora.Parser.Combinator
  import NimbleParsec

  defmodule Helper do
    @moduledoc false
    @usage %{
      bounty: "/bounty <amount>",
      tip: "/tip <amount> @username or /tip @username <amount>",
      claim: "/claim <issue-ref> (e.g. #123, repo#123, owner/repo#123, or full GitHub URL)"
    }

    def commands do
      repeat(
        choice([
          # Any text that is not a command
          [not: ?/] |> ascii_string(min: 1) |> ignore(),

          # Known command
          choice([
            bounty_command(),
            tip_command(),
            claim_command()
          ]),

          # Unknown command
          "/"
          |> string()
          |> ignore()
          |> concat(ascii_string([?a..?z, ?A..?Z, ?_, ?-], min: 1))
          |> ignore()
        ])
      )
    end

    def bounty_command do
      "/bounty"
      |> string()
      |> ignore()
      |> concat(whitespace() |> ignore() |> concat(amount()))
      |> tag(:bounty)
      |> label(@usage.bounty)
    end

    def tip_command do
      "/tip"
      |> string()
      |> ignore()
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

    def claim_command do
      "/claim"
      |> string()
      |> ignore()
      |> concat(ignore(whitespace()))
      |> concat(ticket_ref())
      |> tag(:claim)
      |> label(@usage.claim)
    end
  end

  defparsec(:parse_raw, Helper.commands())

  def parse(nil), do: {:ok, %{}}

  def parse(input) when is_binary(input) do
    case parse_raw(input) do
      {:ok, [], _, _, _, _} ->
        {:ok, %{}}

      {:ok, parsed, _, _, _, _} ->
        {:ok,
         parsed
         |> Enum.reject(&is_nil/1)
         |> Map.new()}

      {:error, reason, _, _, _, _} ->
        {:error, reason}
    end
  rescue
    ArgumentError ->
      {:error, "Failed to parse commands"}
  end
end
