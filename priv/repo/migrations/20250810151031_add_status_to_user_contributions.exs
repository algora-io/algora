defmodule Algora.Repo.Migrations.AddStatusToUserContributions do
  use Ecto.Migration

  def change do
    alter table(:user_contributions) do
      add :status, :string, null: false, default: "initial"
    end

    create constraint(:user_contributions, :valid_status, check: "status IN ('initial', 'highlighted', 'hidden')")
  end
end
