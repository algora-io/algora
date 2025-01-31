defmodule Algora.Bounties.Jobs.PromptPayoutConnect do
  @moduledoc false
  use Oban.Worker, queue: :prompt_payout_connect

  alias Algora.Github

  require Logger

  # TODO: confirm these urls
  defp signup_url, do: "#{AlgoraWeb.Endpoint.url()}"
  defp connect_url, do: "#{AlgoraWeb.Endpoint.url()}/user/transactions"
  defp body, do: "💵 To receive payouts, [sign up on Algora](#{signup_url()}) and [connect with Stripe](#{connect_url()})."

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"ticket_ref" => ticket_ref, "installation_id" => nil}}) do
    if Github.pat_enabled() do
      Github.create_issue_comment(
        Github.pat(),
        ticket_ref["owner"],
        ticket_ref["repo"],
        ticket_ref["number"],
        body()
      )
    else
      Logger.info("""
      Github.create_issue_comment(Github.pat(), "#{ticket_ref["owner"]}", "#{ticket_ref["repo"]}", #{ticket_ref["number"]},
             \"\"\"
             #{body()}
             \"\"\")
      """)
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"ticket_ref" => ticket_ref, "installation_id" => installation_id}}) do
    ticket_ref = %{
      owner: ticket_ref["owner"],
      repo: ticket_ref["repo"],
      number: ticket_ref["number"]
    }

    with {:ok, token} <- Github.get_installation_token(installation_id) do
      Github.create_issue_comment(
        token,
        ticket_ref["owner"],
        ticket_ref["repo"],
        ticket_ref["number"],
        body()
      )
    end
  end
end
