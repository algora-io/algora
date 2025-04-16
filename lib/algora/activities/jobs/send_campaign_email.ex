defmodule Algora.Activities.Jobs.SendCampaignEmail do
  @moduledoc false
  use Oban.Worker,
    queue: :campaign_emails,
    unique: [period: :infinity, keys: [:id, :recipient_email]],
    max_attempts: 1

  alias Algora.Workspace
  alias AlgoraWeb.Admin.CampaignLive

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "id" => _id,
          "recipient_email" => _recipient_email,
          "subject" => subject,
          "recipient" => encoded_recipient,
          "template_params" => encoded_template_params,
          "from_name" => from_name,
          "from_email" => from_email,
          "preheader" => preheader
        }
      }) do
    recipient = Algora.Util.base64_to_term!(encoded_recipient)
    template_params = Algora.Util.base64_to_term!(encoded_template_params)
    token = Algora.Admin.token!()

    with {:ok, repo} <- Workspace.ensure_repository(token, recipient["repo_owner"], recipient["repo_name"]),
         {:ok, _owner} <- Workspace.ensure_user(token, recipient["repo_owner"]),
         {:ok, _contributors} <- Workspace.ensure_contributors(token, repo),
         {:ok, _languages} <- Workspace.ensure_repo_tech_stack(token, repo) do
      CampaignLive.deliver_email(
        recipient: recipient,
        subject: subject,
        template_params: template_params,
        from: {from_name, from_email},
        preheader: preheader
      )
    end
  end
end
