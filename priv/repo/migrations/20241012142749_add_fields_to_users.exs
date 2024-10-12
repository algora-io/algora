defmodule Algora.Repo.Migrations.AddFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :provider, :string
      add :provider_id, :string
      add :provider_login, :string
      add :provider_meta, :map

      add :type, :string, null: false, default: "individual"
      add :bio, :text
      add :location, :string
      add :stargazers_count, :integer, null: false, default: 0
      add :domain, :string
      add :tech_stack, {:array, :string}, null: false, default: "{}"
      add :featured, :boolean, null: false, default: false
      add :priority, :integer, null: false, default: 0
      add :fee_pct, :integer, null: false, default: 19
      add :seeded, :boolean, null: false, default: false
      add :activated, :boolean, null: false, default: false
      add :max_open_attempts, :integer, null: false, default: 3
      add :manual_assignment, :boolean, null: false, default: false
      add :bounty_mode, :string, null: false, default: "community"

      add :website_url, :string
      add :twitter_url, :string
      add :github_url, :string
      add :youtube_url, :string
      add :twitch_url, :string
      add :discord_url, :string
      add :slack_url, :string
      add :linkedin_url, :string
    end

    create index(:users, [:provider, :provider_id])
    create index(:users, [:featured])
    create index(:users, [:priority])
  end
end
