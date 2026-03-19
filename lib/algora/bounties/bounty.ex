defmodule Algora.Bounties.Bounty do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bounties" do
    field :title, :string
    field :description, :string
    field :amount, :integer
    field :currency, :string, default: "USD"
    field :github_issue_url, :string
    field :github_issue_number, :integer
    field :github_repo_full_name, :string
    field :status, :string, default: "open"
    field :external_id, :string
    field :closed_at, :utc_datetime
    field :github_node_id, :string
    field :github_issue_state, :string
    field :github_issue_closed_at, :utc_datetime
    field :github_pull_request_url, :string

    # Virtual fields for real-time data
    field :real_time_claim_count, :integer, virtual: true
    field :real_time_status, :string, virtual: true

    belongs_to :organization, Algora.Organizations.Organization
    belongs_to :user, Algora.Accounts.User
    has_many :activities, Algora.Bounties.Activity, preload_order: [desc: :inserted_at]
    has_many :claims, Algora.Bounties.Claim

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bounty, attrs) do
    bounty
    |> cast(attrs, [
      :title,
      :description,
      :amount,
      :currency,
      :github_issue_url,
      :github_issue_number,
      :github_repo_full_name,
      :status,
      :external_id,
      :closed_at,
      :github_node_id,
      :github_issue_state,
      :github_issue_closed_at,
      :github_pull_request_url,
      :organization_id,
      :user_id
    ])
    |> validate_required([:title, :amount])
    |> validate_number(:amount, greater_than: 0)
    |> validate_inclusion(:currency, ["USD"])
    |> validate_inclusion(:status, ["open", "in_progress", "completed", "cancelled"])
    |> validate_format(:github_issue_url, ~r/^https:\/\/github\.com\//)
    |> unique_constraint(:external_id)
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:user_id)
  end

  def with_preloads(query \\ __MODULE__) do
    import Ecto.Query
    
    query
    |> preload([
      :organization,
      :user,
      activities: ^from(a in Algora.Bounties.Activity, order_by: [desc: a.inserted_at]),
      claims: [:user]
    ])
  end

  def compute_real_time_status(%__MODULE__{} = bounty) do
    cond do
      bounty.github_issue_state == "closed" -> "completed"
      bounty.status == "cancelled" -> "cancelled"
      has_active_claims?(bounty) -> "in_progress"
      true -> "open"
    end
  end

  def compute_real_time_claim_count(%__MODULE__{claims: claims}) when is_list(claims) do
    claims
    |> Enum.filter(&(&1.status in ["pending", "approved"]))
    |> length()
  end
  def compute_real_time_claim_count(_), do: 0

  defp has_active_claims?(%__MODULE__{claims: claims}) when is_list(claims) do
    Enum.any?(claims, &(&1.status in ["pending", "approved"]))
  end
  defp has_active_claims?(_), do: false

  def assign_virtual_fields(%__MODULE__{} = bounty) do
    %{bounty |
      real_time_claim_count: compute_real_time_claim_count(bounty),
      real_time_status: compute_real_time_status(bounty)
    }
  end
end