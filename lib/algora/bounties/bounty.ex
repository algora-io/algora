defmodule Algora.Bounties.Bounty do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bounties" do
    field :amount, :integer
    field :currency, :string, default: "USD"
    field :description, :string
    field :github_issue_id, :integer
    field :github_issue_url, :string
    field :issue_number, :integer
    field :repository, :string
    field :status, :string, default: "open"
    field :title, :string
    field :github_state, :string
    field :github_assignees, {:array, :string}, default: []
    field :github_closed_at, :utc_datetime
    field :github_updated_at, :utc_datetime
    field :claims_count, :integer, default: 0

    belongs_to :user, Algora.Accounts.User
    has_many :claims, Algora.Bounties.Claim

    timestamps()
  end

  @doc false
  def changeset(bounty, attrs) do
    bounty
    |> cast(attrs, [
      :amount,
      :currency,
      :description,
      :github_issue_id,
      :github_issue_url,
      :issue_number,
      :repository,
      :status,
      :title,
      :github_state,
      :github_assignees,
      :github_closed_at,
      :github_updated_at,
      :claims_count
    ])
    |> validate_required([:amount, :title, :repository])
    |> validate_inclusion(:status, ["open", "claimed", "closed", "paid"])
    |> validate_inclusion(:currency, ["USD"])
    |> validate_number(:amount, greater_than: 0)
  end

  def github_sync_changeset(bounty, attrs) do
    bounty
    |> cast(attrs, [
      :github_state,
      :github_assignees,
      :github_closed_at,
      :github_updated_at,
      :status,
      :claims_count
    ])
    |> maybe_update_status()
  end

  defp maybe_update_status(changeset) do
    case get_field(changeset, :github_state) do
      "closed" ->
        assignees = get_field(changeset, :github_assignees) || []
        
        new_status = cond do
          length(assignees) > 0 -> "claimed"
          true -> "closed"
        end
        
        put_change(changeset, :status, new_status)
      
      "open" ->
        put_change(changeset, :status, "open")
      
      _ ->
        changeset
    end
  end

  def sync_with_github_issue(bounty, issue_data) do
    attrs = %{
      github_state: issue_data["state"],
      github_assignees: extract_assignee_logins(issue_data["assignees"] || []),
      github_closed_at: parse_datetime(issue_data["closed_at"]),
      github_updated_at: parse_datetime(issue_data["updated_at"]),
      claims_count: length(issue_data["assignees"] || [])
    }

    github_sync_changeset(bounty, attrs)
  end

  defp extract_assignee_logins(assignees) do
    Enum.map(assignees, & &1["login"])
  end

  defp parse_datetime(nil), do: nil
  defp parse_datetime(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _} -> datetime
      _ -> nil
    end
  end

  def needs_github_sync?(bounty) do
    case bounty.github_updated_at do
      nil -> true
      last_sync ->
        DateTime.diff(DateTime.utc_now(), last_sync, :hour) >= 1
    end
  end

  def is_stale?(bounty) do
    bounty.github_state == "closed" and bounty.status in ["open", "claimed"]
  end
end