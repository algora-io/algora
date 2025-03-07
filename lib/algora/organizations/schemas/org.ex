defmodule Algora.Organizations.Org do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.User

  def changeset(org, params) do
    org
    |> cast(params, [
      :handle,
      :display_name,
      :domain,
      :bio,
      :avatar_url,
      :location,
      :stargazers_count,
      :tech_stack,
      :categories,
      :featured,
      :priority,
      :fee_pct,
      :seeded,
      :activated,
      :max_open_attempts,
      :manual_assignment,
      :bounty_mode,
      :hourly_rate_min,
      :hourly_rate_max,
      :og_title,
      :og_image_url,
      :hours_per_week,
      :website_url,
      :twitter_url,
      :github_url,
      :youtube_url,
      :twitch_url,
      :discord_url,
      :slack_url,
      :linkedin_url
    ])
    |> generate_id()
    |> validate_required([:type, :handle, :display_name])
    |> User.validate_handle()
  end
end
