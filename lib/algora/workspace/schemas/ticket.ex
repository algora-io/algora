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

    belongs_to :repository, Algora.Workspace.Repository
    has_many :bounties, Algora.Bounties.Bounty

    has_many :activities, {"ticket_activities", Activity}, foreign_key: :assoc_id

    timestamps()
  end

  def github_changeset(meta, repo) do
    params = %{
      provider_id: to_string(meta["id"]),
      title: meta["title"],
      description: meta["body"],
      number: meta["number"],
      url: meta["html_url"],
      repository_id: repo.id
    }

    %Ticket{provider: "github", provider_meta: meta}
    |> cast(params, [:provider_id, :title, :description, :number, :url, :repository_id])
    |> generate_id()
    |> validate_required([:provider_id, :title, :number, :url, :repository_id])

    # TODO: Reenable this after migration is complete.
    # |> unique_constraint([:provider, :provider_id])
  end
end
