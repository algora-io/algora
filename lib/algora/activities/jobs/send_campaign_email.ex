defmodule Algora.Activities.Jobs.SendCampaignEmail do
  @moduledoc false
  use Oban.Worker,
    queue: :campaign_emails,
    unique: [period: :infinity, keys: [:id, :recipient_email]],
    max_attempts: 1

  alias Algora.Workspace
  alias AlgoraWeb.Admin.CampaignLive

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"recipient" => encoded_recipient} = args}) do
    args
    |> Map.put("recipient", Algora.Util.base64_to_term!(encoded_recipient))
    |> deliver_email()
  end

  defp deliver_email(%{
         "subject" => subject,
         "recipient" => %{"repo_owner" => repo_owner, "repo_name" => repo_name} = recipient,
         "template" => template,
         "from_name" => from_name,
         "from_email" => from_email,
         "preheader" => preheader
       }) do
    token = Algora.Admin.token!()

    with {:ok, repo} <- Workspace.ensure_repository(token, repo_owner, repo_name),
         {:ok, _owner} <- Workspace.ensure_user(token, repo_owner),
         {:ok, _contributors} <- Workspace.ensure_contributors(token, repo),
         {:ok, _languages} <- Workspace.ensure_repo_tech_stack(token, repo) do
      CampaignLive.deliver_email(
        recipient: recipient,
        subject: subject,
        template: template,
        from: {from_name, from_email},
        preheader: preheader
      )
    end
  end

  defp deliver_email(%{
         "subject" => subject,
         "recipient" => recipient,
         "template" => template,
         "from_name" => from_name,
         "from_email" => from_email,
         "preheader" => preheader
       }) do
    CampaignLive.deliver_email(
      recipient: recipient,
      subject: subject,
      template: template,
      from: {from_name, from_email},
      preheader: preheader
    )
  end
end
