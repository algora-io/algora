defmodule Algora.Repo.Migrations.AddRecruitingContractIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :recruiting_contract_id, :string
    end
  end
end
