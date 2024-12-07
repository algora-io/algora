defmodule Algora.Repo.Migrations.CreateReviews do
  use Ecto.Migration

  def change do
    create table(:reviews) do
      add :rating, :integer, null: false
      add :content, :string, null: false
      add :visibility, :string, null: false, default: "public"

      add :contract_id, references(:contracts, on_delete: :restrict), null: false
      add :bounty_id, references(:bounties, on_delete: :restrict), null: true
      add :organization_id, references(:users, on_delete: :restrict), null: false
      add :reviewer_id, references(:users, on_delete: :restrict), null: false
      add :reviewee_id, references(:users, on_delete: :restrict), null: false

      timestamps()
    end

    # Add indexes for foreign keys and common queries
    create index(:reviews, [:contract_id])
    create index(:reviews, [:bounty_id])
    create index(:reviews, [:organization_id])
    create index(:reviews, [:reviewer_id])
    create index(:reviews, [:reviewee_id])
  end
end
