defmodule Algora.Bounties.Claim do
  @moduledoc false
  use Algora.Schema

  alias Algora.Bounties.Claim
  alias Algora.Workspace.Ticket

  typed_schema "claims" do
    field :status, Ecto.Enum, values: [:pending, :approved, :cancelled], null: false
    field :type, Ecto.Enum, values: [:pull_request, :review, :video, :design, :article]
    field :url, :string, null: false
    field :group_id, :string, null: false
    field :group_share, :decimal, null: false, default: 1.0

    belongs_to :source, Ticket
    belongs_to :target, Ticket, null: false
    belongs_to :user, Algora.Accounts.User, null: false
    has_many :transactions, Algora.Payments.Transaction

    timestamps()
  end

  def changeset(claim, attrs) do
    claim
    |> cast(attrs, [:source_id, :target_id, :user_id, :status, :type, :url, :group_id])
    |> validate_required([:target_id, :user_id, :status, :type, :url])
    |> generate_id()
    |> put_group_id()
    |> foreign_key_constraint(:source_id)
    |> foreign_key_constraint(:target_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:target_id, :user_id])
  end

  def put_group_id(changeset) do
    case get_field(changeset, :group_id) do
      nil -> put_change(changeset, :group_id, get_field(changeset, :id))
      _existing -> changeset
    end
  end

  def type_label(:pull_request), do: "a pull request"
  def type_label(:review), do: "a review"
  def type_label(:video), do: "a video"
  def type_label(:design), do: "a design"
  def type_label(:article), do: "an article"
  def type_label(nil), do: "a URL"

  def reward_url(claim), do: "#{AlgoraWeb.Endpoint.url()}/claims/#{claim.id}"

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
