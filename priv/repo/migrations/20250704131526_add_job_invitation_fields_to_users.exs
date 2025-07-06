defmodule Algora.Repo.Migrations.AddJobInvitationFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :refer_to_company, :boolean, default: false
      add :company_domain, :string
      add :friends_recommendations, :boolean, default: false
      add :friends_github_handles, :string
      add :opt_out_algora, :boolean, default: false
    end
  end
end
