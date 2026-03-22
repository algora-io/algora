defmodule Algora.Bounties.Schemas.Bounty do
  use Ecto.Schema
  import Ecto.Changeset

  alias Algora.Accounts.Schemas.User
  alias Algora.Bounties.Schemas.Claim

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "bounties" do
    field :title, :string
    field :description, :string
    field :reward_amount, :decimal
    field :currency, :string, default: "USD"
    field :status, Ecto.Enum, values: [:open, :claimed, :completed, :cancelled], default: :open
    field :github_issue_url, :string
    field :github_issue_number, :integer
    field :github_repo_owner, :string
    field :github_repo_name, :string
    field :tags, {:array, :string}, default: []
    field :expires_at, :naive_datetime
    field :last_synced_at, :naive_datetime

    belongs_to :creator, User
    has_many :claims, Claim, on_delete: :delete_all

    timestamps(type: :naive_datetime_usec)
  end

  @doc false
  def changeset(bounty, attrs) do
    bounty
    |> cast(attrs, [
      :title,
      :description,
      :reward_amount,
      :currency,
      :status,
      :github_issue_url,
      :github_issue_number,
      :github_repo_owner,
      :github_repo_name,
      :tags,
      :expires_at,
      :last_synced_at,
      :creator_id
    ])
    |> validate_required([:title, :reward_amount, :creator_id])
    |> validate_number(:reward_amount, greater_than: 0)
    |> validate_inclusion(:currency, ["USD", "EUR", "GBP"])
    |> validate_url_format(:github_issue_url)
    |> unique_constraint(:github_issue_url)
  end

  def sync_changeset(bounty, attrs) do
    bounty
    |> cast(attrs, [:status, :last_synced_at])
    |> validate_required([:last_synced_at])
  end

  defp validate_url_format(changeset, field) do
    validate_change(changeset, field, fn _, url ->
      case url do
        nil -> []
        "" -> []
        url ->
          if String.match?(url, ~r/^https:\/\/github\.com\/[^\/]+\/[^\/]+\/issues\/\d+$/) do
            []
          else
            [{field, "must be a valid GitHub issue URL"}]
          end
      end
    end)
  end
end