defmodule Algora.Repo.Migrations.RenameEquityAndAddMoneyEquityToJobPostings do
  use Ecto.Migration

  def change do
    # Rename existing decimal equity columns to _pct suffix
    # These store percentage values like 0.25 for 0.25%
    rename table(:job_postings), :min_equity, to: :min_equity_pct
    rename table(:job_postings), :max_equity, to: :max_equity_pct

    alter table(:job_postings) do
      # Add new Money type equity columns
      # These store actual money values (e.g., $10,000 worth of equity)
      add :min_equity, :money_with_currency
      add :max_equity, :money_with_currency
    end
  end
end
