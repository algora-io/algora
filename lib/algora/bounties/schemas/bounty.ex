defmodule Algora.Bounties.Schemas.Bounty do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "bounties" do
    field :title, :string
    field :description, :string
    field :amount, :integer
    field :status, Ecto.Enum, values: [:open, :claimed, :completed, :closed]
    field :github_issue_url, :string
    field :github_issue_number, :integer
    field :github_repo_name, :string
    field :github_repo_owner, :string
    field :github_sync_status, Ecto.Enum, values: [:synced, :out_of_sync, :error], default: :synced
    field :last_synced_at, :utc_datetime

    belongs_to :organization, Algora.Organizations.Organization
    belongs_to :creator, Algora.Accounts.User, foreign_key: :creator_id
    belongs_to :assignee, Algora.Accounts.User, foreign_key: :assignee_id

    has_many :claims, Algora.Bounties.Schemas.Claim

    timestamps()
  end

  def changeset(bounty, attrs) do
    bounty
    |> cast(attrs, [
      :title,
      :description,
      :amount,
      :status,
      :github_issue_url,
      :github_issue_number,
      :github_repo_name,
      :github_repo_owner,
      :github_sync_status,
      :last_synced_at,
      :organization_id,
      :creator_id,
      :assignee_id
    ])
    |> validate_required([:title, :description, :amount, :status, :organization_id, :creator_id])
    |> validate_inclusion(:status, [:open, :claimed, :completed, :closed])
    |> validate_inclusion(:github_sync_status, [:synced, :out_of_sync, :error])
    |> validate_number(:amount, greater_than: 0)
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:creator_id)
    |> foreign_key_constraint(:assignee_id)
  end

  def sync_changeset(bounty, attrs) do
    bounty
    |> cast(attrs, [:github_sync_status, :last_synced_at, :status])
    |> validate_inclusion(:github_sync_status, [:synced, :out_of_sync, :error])
    |> validate_inclusion(:status, [:open, :claimed, :completed, :closed])
  end
end