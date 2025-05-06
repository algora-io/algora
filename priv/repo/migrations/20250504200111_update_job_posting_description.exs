defmodule Algora.Repo.Migrations.UpdateJobPostingDescription do
  use Ecto.Migration

  def up do
    alter table(:job_postings) do
      modify :description, :text
      modify :company_name, :text
      modify :company_url, :text
    end

    alter table(:users) do
      modify :linkedin_url, :text
      modify :website_url, :text
      modify :discord_url, :text
      modify :github_url, :text
      modify :twitter_url, :text
      modify :youtube_url, :text
      modify :slack_url, :text
      modify :twitch_url, :text
      modify :og_image_url, :text
    end
  end

  def down do
  end
end
