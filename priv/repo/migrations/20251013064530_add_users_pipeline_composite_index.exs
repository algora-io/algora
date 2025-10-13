defmodule Algora.Repo.Migrations.AddUsersPipelineCompositeIndex do
  use Ecto.Migration

  def change do
    create index(
             :users,
             [
               :type,
               :country,
               :open_to_new_role,
               :provider_login,
               :opt_out_algora,
               :last_job_match_email_at
             ],
             where:
               "type = 'individual' AND provider_login IS NOT NULL AND opt_out_algora = false AND open_to_new_role = true AND country IN ('US', 'CA')",
             name: :idx_users_pipeline_composite
           )
  end
end
