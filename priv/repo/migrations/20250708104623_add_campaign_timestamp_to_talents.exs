defmodule Algora.Repo.Migrations.AddCampaignTimestampToTalents do
  use Ecto.Migration

  def change do
    alter table(:talents) do
      add :campaign_timestamp, :string
    end
  end
end
