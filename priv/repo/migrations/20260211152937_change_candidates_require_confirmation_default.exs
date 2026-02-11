defmodule Algora.Repo.Migrations.ChangeCandidatesRequireConfirmationDefault do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :candidates_require_confirmation, :boolean, default: false, from: {:boolean, default: true}
    end
  end
end
