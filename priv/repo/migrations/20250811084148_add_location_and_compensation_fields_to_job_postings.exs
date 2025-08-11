defmodule Algora.Repo.Migrations.AddLocationAndCompensationFieldsToJobPostings do
  use Ecto.Migration

  def change do
    alter table(:job_postings) do
      add :location_types, {:array, :string}, default: []
      add :locations, {:array, :string}, default: []
      add :max_compensation, :money_with_currency
    end
  end
end
