defmodule Algora.Github.Command do
  @moduledoc false
  import Algora.Parser.Combinator
  import NimbleParsec

  defmodule Helper do
    @moduledoc false
    @usage %{
      bounty: "/bounty <amount>",
      tip: "/tip <amount> @username or /tip @username <amount>",
      claim: "/claim <issue-ref> (e.g. #123, repo#123, owner/repo#123, or full GitHub URL)",
      split: "/split @username",
      attempt: "/attempt <issue-ref> (e.g. #123, repo#123, owner/repo#123, or full GitHub URL)"
    }

    def command do
      choice([
        bounty_command(),
        tip_command(),
        claim_command(),
        split_command(),
        attempt_command()
      ])
    end

    def bounty_command do
      "/bounty"
      |> string()
      |> ignore()
      |> concat(ignore(whitespace()))
      |> concat(amount())
      |> tag(:bounty)
      |> label(@usage.bounty)
    end

    def tip_command do
      "/tip"
      |> string()
      |> ignore()
      |> concat(ignore(whitespace()))
      |> choice([
        amount() |> concat(ignore(whitespace())) |> concat(recipient()),
        recipient() |> concat(ignore(whitespace())) |> concat(amount()),
        amount(),
        recipient()
      ])
      |> tag(:tip)
      |> label(@usage.tip)
    end

    def split_command do
      "/split"
      |> string()
      |> ignore()
      |> concat(ignore(whitespace()))
      |> concat(recipient())
      |> tag(:split)
      |> label(@usage.split)
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

    def attempt_command do
      "/attempt"
      |> string()
      |> ignore()
      |> concat(ignore(whitespace()))
      |> concat(ticket_ref())
      |> tag(:attempt)
      |> label(@usage.attempt)
    end

    def commands do
      repeat(
        choice([
          ignore(utf8_string([not: ?/], min: 1)),
          command(),
          ignore(string("/"))
        ])
      )
    end
  end

  defparsec(:parse_raw, Helper.commands())

  def parse(nil), do: {:ok, []}

  def parse(input) when is_binary(input) do
    case parse_raw(input) do
      {:ok, parsed, _, _, _, _} -> {:ok, Enum.reject(parsed, &is_nil/1)}
      {:error, reason, _, _, _, _} -> {:error, reason}
    end
  end
end
