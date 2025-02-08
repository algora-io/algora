defmodule Algora.Repo.Migrations.MakeProviderMetaNullable do
  use Ecto.Migration

  def change do
    alter table(:command_responses) do
      modify :provider_meta, :map, null: true
    end

    alter table(:installations) do
      modify :provider_meta, :map, null: true
      modify :provider_user_id, :string, null: true
    end

    alter table(:customers) do
      modify :provider_meta, :map, null: true
    end

    alter table(:payment_methods) do
      modify :provider_meta, :map, null: true
    end

    alter table(:accounts) do
      modify :provider_meta, :map, null: true
      modify :country, :string, null: true
    end

    alter table(:identities) do
      modify :provider_meta, :map, null: true
      modify :provider_login, :string, null: true
    end

    alter table(:claims) do
      modify :source_id, :string, null: true
    end

    alter table(:tips) do
      modify :creator_id, :string, null: true
    end
  end
end
