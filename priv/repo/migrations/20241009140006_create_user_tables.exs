defmodule Algora.Repo.Migrations.CreateUserTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add :provider, :string
      add :provider_id, :string
      add :provider_login, :string
      add :provider_meta, :map

      add :email, :citext
      add :name, :string
      add :handle, :citext
      add :avatar_url, :string
      add :external_homepage_url, :string

      add :type, :string, null: false, default: "individual"
      add :bio, :text
      add :location, :string
      add :country, :string
      add :timezone, :string
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

      add :og_title, :string
      add :og_image_url, :string

      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:handle])
    create unique_index(:users, [:provider, :provider_id])
    create index(:users, [:featured])
    create index(:users, [:priority])

    create table(:identities) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :provider, :string, null: false
      add :provider_token, :string, null: false
      add :provider_email, :string, null: false
      add :provider_login, :string, null: false
      add :provider_id, :string, null: false
      add :provider_meta, :map, default: "{}", null: false

      timestamps()
    end

    create index(:identities, [:user_id])
    create index(:identities, [:provider])
    create unique_index(:identities, [:user_id, :provider])
  end
end
