defmodule Algora.Repo.Migrations.UpdateUserFeePct do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :fee_pct_prev, :integer, default: 9
    end

    execute """
    UPDATE users
    SET fee_pct_prev = fee_pct,
        fee_pct = 9
    """
  end
end
