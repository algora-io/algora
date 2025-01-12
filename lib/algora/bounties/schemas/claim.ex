defmodule Algora.Bounties.Claim do
  @moduledoc false
  use Algora.Schema

  alias Algora.Bounties.Claim

  @derive {Inspect, except: [:provider_meta]}
  typed_schema "claims" do
    field :provider, :string, null: false
    field :provider_id, :string, null: false
    field :provider_meta, :map, null: false

    field :merged_at, :utc_datetime_usec
    field :approved_at, :utc_datetime_usec
    field :rejected_at, :utc_datetime_usec
    field :charged_at, :utc_datetime_usec
    field :paid_at, :utc_datetime_usec

    field :title, :string, null: false
    field :description, :string
    field :url, :string, null: false
    field :group_id, :string, null: false

    belongs_to :ticket, Algora.Workspace.Ticket, null: false
    belongs_to :user, Algora.Accounts.User, null: false
    # has_one :transaction, Algora.Payments.Transaction

    timestamps()
  end

  def changeset(claim, attrs) do
    claim
    |> cast(attrs, [
      :ticket_id,
      :user_id,
      :provider,
      :provider_id,
      :provider_meta,
      :merged_at,
      :approved_at,
      :rejected_at,
      :charged_at,
      :paid_at,
      :title,
      :description,
      :url,
      :group_id
    ])
    |> validate_required([
      :ticket_id,
      :user_id,
      :provider,
      :provider_id,
      :provider_meta,
      :title,
      :url,
      :group_id
    ])
    |> foreign_key_constraint(:ticket_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:ticket_id, :user_id])
  end

  def rewarded(query \\ Claim) do
    from c in query,
      where: c.state == :approved and not is_nil(c.charged_at)
  end

  def filter_by_org_id(query, nil), do: query

  def filter_by_org_id(query, org_id) do
    from c in query,
      join: b in assoc(c, :bounty),
      join: u in assoc(b, :owner),
      where: u.id == ^org_id
  end
end
