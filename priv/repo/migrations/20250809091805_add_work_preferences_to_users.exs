defmodule Algora.Repo.Migrations.AddWorkPreferencesToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      # Work arrangement preferences
      add :open_to_remote, :boolean, default: false
      add :open_to_hybrid, :boolean, default: false
      add :open_to_onsite, :boolean, default: false

      # Relocation preferences
      add :open_to_relocate_sf, :boolean, default: false
      add :open_to_relocate_ny, :boolean, default: false
      add :open_to_relocate_country, :boolean, default: false
      add :open_to_relocate_world, :boolean, default: false

      # Commitment preferences
      add :open_to_fulltime, :boolean, default: false
      add :open_to_contract, :boolean, default: false

      # Track preferences
      add :open_to_ic, :boolean, default: false
      add :open_to_manager, :boolean, default: false

      # Work authorization
      add :work_auth_us, :boolean, default: false
      add :work_auth_eu, :boolean, default: false
    end
  end
end
