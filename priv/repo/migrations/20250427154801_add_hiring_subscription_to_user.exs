defmodule Algora.Repo.Migrations.AddHiringSubscriptionToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :hiring_subscription, :string, default: "inactive"
    end
  end
end
