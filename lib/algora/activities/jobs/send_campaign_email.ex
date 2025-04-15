defmodule Algora.Activities.Jobs.SendCampaignEmail do
  @moduledoc false
  use Oban.Worker,
    queue: :campaign_emails,
    unique: [period: :infinity, keys: [:id, :recipient_email]],
    max_attempts: 1

  alias AlgoraWeb.Admin.CampaignLive

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{
          "id" => _id,
          "recipient_email" => _recipient_email,
          "subject" => subject,
          "recipient" => encoded_recipient,
          "template_params" => encoded_template_params
        }
      }) do
    recipient = Algora.Util.base64_to_term!(encoded_recipient)
    template_params = Algora.Util.base64_to_term!(encoded_template_params)

    CampaignLive.deliver_email(recipient, subject, template_params)
  end
end
