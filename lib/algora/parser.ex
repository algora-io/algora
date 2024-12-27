defmodule Algora.Parser do
  import NimbleParsec

  defmodule Combinator do
    def whitespace(), do: ascii_string([?\s, ?\t], min: 1)
    def digits(), do: ascii_string([?0..?9], min: 1)
    def word_chars(), do: ascii_string([not: ?\s, not: ?\t], min: 1)
    def non_separator_chars(), do: ascii_string([not: ?#, not: ?/, not: ?\s, not: ?\t], min: 1)
    def integer(), do: digits() |> reduce({__MODULE__, :to_integer, []})

    def amount() do
      ignore(optional(string("$")))
      |> concat(ascii_string([?0..?9, ?., ?,], min: 1))
      |> post_traverse({__MODULE__, :to_money, []})
      |> unwrap_and_tag(:amount)
      |> label("amount (e.g. 1000 or 1,000.00)")
    end

    def username() do
      ignore(string("@"))
      |> concat(word_chars())
      |> unwrap_and_tag(:username)
      |> label("username starting with @")
    end

    def ticket_ref() do
      choice([
        simple_issue_ref(),
        repo_issue_ref(),
        full_repo_issue_ref(),
        github_url_ref()
      ])
      |> tag(:ticket_ref)
      |> label("issue reference (e.g. #123, repo#123, owner/repo#123, or GitHub URL)")
    end

    def full_ticket_ref() do
      choice([full_repo_issue_ref(), github_url_ref()])
      |> tag(:ticket_ref)
      |> label("issue reference (e.g. owner/repo#123 or GitHub URL)")
    end

    def simple_issue_ref do
      # Format: #123
      optional(ignore(string("#")))
      |> concat(integer() |> unwrap_and_tag(:number))
    end

    def repo_issue_ref do
      # Format: repo#123
      empty()
      |> concat(non_separator_chars() |> unwrap_and_tag(:repo))
      |> ignore(string("#"))
      |> concat(integer() |> unwrap_and_tag(:number))
    end

    def full_repo_issue_ref do
      # Format: owner/repo#123
      empty()
      |> concat(non_separator_chars() |> unwrap_and_tag(:owner))
      |> ignore(string("/"))
      |> concat(non_separator_chars() |> unwrap_and_tag(:repo))
      |> ignore(string("#"))
      |> concat(integer() |> unwrap_and_tag(:number))
    end

    def github_url_ref do
      # Format: https://github.com/owner/repo/(issues|pull|discussions)/123
      ignore(choice([string("https://"), string("http://"), empty()]))
      |> ignore(string("github.com/"))
      |> concat(non_separator_chars() |> unwrap_and_tag(:owner))
      |> ignore(string("/"))
      |> concat(non_separator_chars() |> unwrap_and_tag(:repo))
      |> ignore(string("/"))
      |> concat(
        choice([string("issues"), string("pull"), string("discussions")])
        |> unwrap_and_tag(:type)
      )
      |> ignore(string("/"))
      |> concat(integer() |> unwrap_and_tag(:number))
    end

    # Helper functions
    def to_money(rest, args, context, _line, _offset) do
      delimiters = [",", "."]

      amount_string = args |> Enum.join()

      amount_string =
        Enum.reduce(delimiters, amount_string, fn delimiter, acc ->
          String.trim(acc, delimiter)
        end)

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

    def to_integer(segments) when is_list(segments) do
      segments |> Enum.join() |> String.to_integer()
    end
  end

  defparsec(:full_ticket_ref, Combinator.full_ticket_ref())
end
