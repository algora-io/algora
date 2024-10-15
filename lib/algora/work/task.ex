defmodule Algora.Work.Task do
  use Ecto.Schema
  import Ecto.Changeset

  alias Algora.Work.Task

  @type t() :: %__MODULE__{}

  @derive {Inspect, except: [:provider_meta]}
  schema "tasks" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map

    field :title, :string
    field :description, :string
    field :number, :integer
    field :url, :string

    belongs_to :repository, Algora.Work.Repository
    has_many :bounties, Algora.Bounties.Bounty

    timestamps()
  end

  def github_changeset(repo, meta) do
    params = %{
      provider_id: to_string(meta["id"]),
      title: meta["title"],
      description: meta["body"],
      number: meta["number"],
      url: meta["html_url"],
      repository_id: repo.id
    }

    %Task{provider: "github", provider_meta: meta}
    |> cast(params, [:provider_id, :title, :description, :number, :url, :repository_id])
    |> validate_required([:provider_id, :title, :number, :url, :repository_id])
    |> unique_constraint([:provider, :provider_id])
  end
end
