defmodule Algora.Workspace.Ticket do
  @moduledoc false
  use Algora.Schema

  alias Algora.Activities.Activity
  alias Algora.Workspace.Ticket

  @derive {Inspect, except: [:provider_meta]}
  typed_schema "tickets" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map

    field :type, Ecto.Enum, values: [:issue, :pull_request]
    field :title, :string
    field :description, :string
    field :number, :integer
    field :url, :string
    field :state, Ecto.Enum, values: [:open, :closed], default: :open
    field :closed_at, :utc_datetime_usec
    field :merged_at, :utc_datetime_usec

    belongs_to :repository, Algora.Workspace.Repository
    has_many :bounties, Algora.Bounties.Bounty
    has_many :tips, Algora.Bounties.Tip

    has_many :activities, {"ticket_activities", Activity}, foreign_key: :assoc_id

    timestamps()
  end

  def changeset(ticket, params) do
    ticket
    |> cast(params, [:title, :description, :url])
    |> validate_required([:title])
    |> generate_id()
  end

  def github_changeset(meta, repo) do
    params = %{
      provider_id: to_string(meta["id"]),
      type: if(meta["pull_request"], do: :pull_request, else: :issue),
      title: meta["title"],
      description: meta["body"],
      number: meta["number"],
      url: meta["html_url"],
      repository_id: repo.id,
      state: meta["state"],
      closed_at: meta["closed_at"],
      merged_at: get_in(meta, ["pull_request", "merged_at"])
    }

    %Ticket{provider: "github", provider_meta: meta}
    |> cast(params, [
      :provider_id,
      :type,
      :title,
      :description,
      :number,
      :url,
      :repository_id,
      :state,
      :closed_at,
      :merged_at
    ])
    |> generate_id()
    |> validate_required([:provider_id, :type, :title, :number, :url, :repository_id, :state])

    # TODO: Reenable this after migration is complete.
    # |> unique_constraint([:provider, :provider_id])
  end
end
