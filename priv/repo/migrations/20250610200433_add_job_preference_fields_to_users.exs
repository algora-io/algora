defmodule Algora.Repo.Migrations.AddJobPreferenceFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :min_compensation, :money_with_currency
      add :willing_to_relocate, :boolean, default: false
      add :us_work_authorization, :boolean, default: false
    end
  end
end
