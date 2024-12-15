defmodule Algora.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :provider, :string
      add :provider_id, :string
      add :provider_login, :string
      add :provider_meta, :map

      add :email, :citext
      add :name, :string
      add :display_name, :string
      add :handle, :citext
      add :avatar_url, :string
      add :external_homepage_url, :string

      add :type, :string, null: false, default: "individual"
      add :bio, :text
      add :location, :string
      add :country, :citext
      add :timezone, :string
      add :stargazers_count, :integer, null: false, default: 0
      add :domain, :string
      add :tech_stack, {:array, :citext}, null: false, default: "{}"
      add :featured, :boolean, null: false, default: false
      add :priority, :integer, null: false, default: 0
      add :fee_pct, :integer, null: false, default: 19
      add :seeded, :boolean, null: false, default: false
      add :activated, :boolean, null: false, default: false
      add :max_open_attempts, :integer, null: false, default: 3
      add :manual_assignment, :boolean, null: false, default: false
      add :bounty_mode, :string, null: false, default: "community"

      add :hourly_rate_min, :money_with_currency
      add :hourly_rate_max, :money_with_currency
      add :hours_per_week, :integer

      add :website_url, :string
      add :twitter_url, :string
      add :github_url, :string
      add :youtube_url, :string
      add :twitch_url, :string
      add :discord_url, :string
      add :slack_url, :string
      add :linkedin_url, :string

      add :og_title, :string
      add :og_image_url, :string

      add :last_context, :string
      add :need_avatar, :boolean, default: false

      timestamps()
    end

    execute("ALTER TABLE users DROP COLUMN name;")

    execute(
      "ALTER TABLE users ADD COLUMN name VARCHAR GENERATED ALWAYS AS (COALESCE(NULLIF(TRIM(display_name), ''), handle)) STORED;"
    )

    create unique_index(:users, [:email])
    create unique_index(:users, [:handle])
    create unique_index(:users, [:provider, :provider_id])
    create index(:users, [:featured])
    create index(:users, [:priority])
  end
end
